-- Факт позиций заказа: одна строка — один товар в заказе. Тестовые заказы исключены.
--
-- Инкрементальная модель. Первый запуск и --full-refresh строят таблицу целиком.
-- Обычный запуск пересчитывает только последние дни: dbt удаляет из витрины строки с теми же
-- order_item_id и вставляет новые версии (delete + insert). Что при этом теряется — см. README.
--
-- Хранение: order_id как у fct_orders (JOIN без пересылки строк), колонки — отчёты читают
-- несколько столбцов из всей таблицы.
{{ config(
    materialized='incremental',
    unique_key='order_item_id',
    distributed_by='order_id',
    orientation='column'
) }}

{% set lookback_days = 3 %}

select
    order_item_id,
    order_id,
    product_id,
    customer_id,
    order_date,
    order_status,
    quantity,
    unit_price,
    gross_amount,
    discount_amount,
    line_amount,
    is_confirmed
from {{ ref('int_order_items_with_orders') }}
where not is_test_order
{% if is_incremental() %}
    -- Запас в несколько дней: свежие заказы ещё могут оплатить, отменить или вернуть.
    and order_date >= (select max(order_date) - {{ lookback_days }} from {{ this }})
{% endif %}
