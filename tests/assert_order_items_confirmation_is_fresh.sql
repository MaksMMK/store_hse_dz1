-- Признак подтверждения в позициях совпадает с признаком заказа.
-- fct_order_items инкрементальная и не пересчитывает старые заказы, а fct_orders собирается
-- целиком. Если статус старого заказа изменился, тест упадёт: нужен dbt run --full-refresh.
select
    i.order_item_id,
    i.order_id,
    i.is_confirmed as item_is_confirmed,
    o.is_confirmed as order_is_confirmed
from {{ ref('fct_order_items') }} as i
join {{ ref('fct_orders') }} as o
    on o.order_id = i.order_id
where i.is_confirmed <> o.is_confirmed
