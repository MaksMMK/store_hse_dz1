-- Одна строка — один товар в заказе, без тестовых заказов.
-- Модель инкрементальная: обычный запуск обновляет только последние дни (см. README).
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
    and order_date >= (select max(order_date) - {{ lookback_days }} from {{ this }})
{% endif %}
