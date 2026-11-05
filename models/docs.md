{% docs __overview__ %}

# Аналитический слой интернет-магазина

Витрины интернет-магазина по схеме «звезда» в Greenplum.

```
PostgreSQL (OLTP) → loader → raw → analytics_staging → analytics_intermediate → analytics_marts
```

- **staging** — одна модель на таблицу источника: имена и типы, без JOIN и агрегаций.
- **intermediate** — JOIN, агрегации, разворот дерева категорий.
- **marts** — готовые витрины: факты `fct_orders` и `fct_order_items`,
  измерения `dim_customers`, `dim_products`, `dim_dates`.

Определение выручки: сумма `order_amount` по подтверждённым покупкам (`is_confirmed = true`).

Известная проблема: заказ 113 на 200 рублей оплачен дважды. Её показывает тест
`assert_confirmed_orders_not_overcharged` со статусом WARN.

{% enddocs %}

{% docs confirmed_order %}

Подтверждённая покупка: заказ со статусом `paid` и хотя бы одной успешной оплатой.
Возврат (успешная операция с отрицательной суммой) оплатой не считается.

Поэтому заказ 119 со статусом `paid`, но без успешной оплаты, не подтверждён,
а возвращённый заказ 107 не подтверждён, хотя когда-то был оплачен.

{% enddocs %}
