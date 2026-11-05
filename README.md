# store_hse

Домашнее задание 1: витрины интернет-магазина в Greenplum.

Loader копирует таблицы магазина в схему `raw`, а dbt собирает из них витрины
по схеме «звезда» в схеме `analytics_marts`.

## Запуск

```bash
docker compose down -v && docker compose up -d   # чистые базы и загрузка raw
docker compose logs loader                       # дождаться строки «Готово»
docker compose run --rm dbt build                # должно быть ERROR=0 и один WARN (заказ 113)
```

Документация проекта:

```bash
docker compose run --rm dbt docs generate
docker compose run --rm --service-ports dbt docs serve --host 0.0.0.0 --port 8080 --no-browser
```

## Модель данных

```mermaid
erDiagram
    dim_customers ||--o{ fct_orders : "customer_id"
    dim_customers ||--o{ fct_order_items : "customer_id"
    dim_dates ||--o{ fct_orders : "order_date = date_day"
    dim_dates ||--o{ fct_order_items : "order_date = date_day"
    dim_products ||--o{ fct_order_items : "product_id"
    fct_orders ||--|{ fct_order_items : "order_id"

    fct_orders {
        int order_id PK
        int customer_id FK
        date order_date FK
        text order_status
        numeric order_amount
        int items_count
        numeric paid_amount
        numeric refunded_amount
        numeric net_paid_amount
        boolean is_confirmed
    }
    fct_order_items {
        text order_item_id PK
        int order_id FK
        int product_id FK
        int customer_id FK
        date order_date FK
        text order_status
        int quantity
        numeric unit_price
        numeric discount_amount
        numeric line_amount
        boolean is_confirmed
    }
    dim_customers {
        int customer_id PK
        text city
        text acquisition_channel
        int first_confirmed_order_id
        timestamp first_confirmed_at
        int confirmed_orders_count
        numeric confirmed_revenue
        boolean is_buyer
    }
    dim_products {
        int product_id PK
        text product_name
        text brand
        text category_name
        text parent_category_name
        text root_category_name
    }
    dim_dates {
        date date_day PK
        int year_number
        int quarter_number
        int month_number
        int day_of_week
        boolean is_weekend
    }
```

| Витрина | Зернистость | На какой вопрос отвечает |
| --- | --- | --- |
| `fct_orders` | один заказ | Выручка, средний чек, оплаты и возвраты |
| `fct_order_items` | один товар в заказе | Выручка по категориям, возвраты по брендам |
| `dim_customers` | один клиент, включая не купивших | Покупатели по каналам привлечения и городам |
| `dim_products` | один товар | Бренды и категории товаров |
| `dim_dates` | один день | Отчёты по месяцам, кварталам, выходным |

### Граф зависимостей

![Граф lineage из dbt docs](docs/lineage.png)

## Хранение в Greenplum

| Витрина | Распределение | Хранение | Почему |
| --- | --- | --- | --- |
| `fct_orders` | `order_id` | heap | Значения уникальные, строки ложатся ровно. Так же распределены сырые заказы, позиции и платежи |
| `fct_order_items` | `order_id` | колоночное | JOIN с `fct_orders` идёт локально. Отчёты обычно читают только несколько колонок |
| `dim_customers` | `replicated` | heap | Таблица маленькая, JOIN идёт без пересылки. Если клиентов станет очень много, лучше `distributed by (customer_id)` |
| `dim_products` | `replicated` | heap | Маленький справочник, JOIN идёт без пересылки |
| `dim_dates` | `replicated` | heap | Мало строк, нужен почти в каждом отчёте |

Оба факта распределены по `order_id`, поэтому строки одного заказа лежат на одном сегменте и JOIN
идёт без пересылки. Если распределить `fct_order_items` по `product_id`, для JOIN строки придётся
пересылать по сети (Redistribute Motion). Плюс товаров всего 13 и продаются они неравномерно,
так что будет перекос.

`order_status` тоже плохой ключ: у него 4 значения, и большинство заказов имеют статус `paid`.

Проверка:

```sql
select c.relname, pg_get_table_distributedby(c.oid) as distribution, am.amname as storage
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_am am on am.oid = c.relam
where n.nspname = 'analytics_marts' and c.relkind = 'r';
```

## Инкрементальная модель fct_order_items

Из двух вариантов дополнительного задания я выбрал инкрементальную модель (`unique_key='order_item_id'`).
`dbt_utils` не подошёл: проверочная команда не запускает `dbt deps`, а `dbt_packages/` не лежит в репозитории.

Первый запуск строит таблицу целиком. Дальше dbt заменяет только заказы за последние 3 дня от самой
свежей даты в витрине: свежий заказ ещё могут оплатить или отменить.

Что модель пропустит:

- заказ старше 3 дней вернули или оплатили: в витрине останутся старые `order_status` и `is_confirmed`,
  а `fct_orders` покажет новые значения;
- изменили старую позицию: останутся старые количество, цена или скидка;
- строку удалили в источнике: в витрине она останется;
- старый заказ задним числом стал тестовым: из витрины он не исчезнет;
- заказ загрузили с опозданием, и его дата вне окна: в витрину он не попадёт.

Расхождение `is_confirmed` с `fct_orders` ловит тест `assert_order_items_confirmation_is_fresh`.
Исправляется полной пересборкой: `dbt run --full-refresh -s fct_order_items`.

## Тесты

Generic-тесты: `unique`, `not_null`, `relationships`, `accepted_values` и свой `non_negative` из `tests/generic/`.

Singular-тесты:

| Тест | Что проверяет |
| --- | --- |
| `assert_order_amount_matches_items` | Сумма заказа равна сумме его позиций |
| `assert_confirmed_revenue_matches_source` | Подтверждённые покупки в витрине совпадают с расчётом по сырым таблицам |
| `assert_returned_orders_fully_refunded` | По возвращённому заказу `net_paid_amount = 0` |
| `assert_confirmed_orders_not_overcharged` | С подтверждённого заказа не списали больше его суммы (WARN) |
| `assert_first_purchase_after_registration` | Первая покупка не раньше регистрации |
| `assert_first_purchase_is_earliest` | `first_confirmed_order_id` указывает на самую раннюю покупку клиента |
| `assert_order_items_confirmation_is_fresh` | `is_confirmed` в позициях совпадает с заказом |
| `assert_refunds_only_for_returned_orders` | Возврат есть только у заказа со статусом `returned` |

### Что нашёл тест на переплату

`assert_confirmed_orders_not_overcharged` даёт WARN на заказ 113: сумма 200, но прошло два успешных
платежа по 200 с разницей в минуту, то есть списали 400. Возврата лишних 200 в данных нет.

Данные я не менял: ошибка в источнике, и исправлять её надо там. На выручку это не влияет, потому что
она считается по `order_amount`. Поэтому тест стоит с `severity: warn`.
