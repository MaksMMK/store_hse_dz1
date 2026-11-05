-- Позиции с атрибутами заказа: одна строка — один товар в заказе (включая тестовые заказы).
-- Клиент, дата и признак подтверждения живут у заказа, поэтому берём их оттуда.
-- JOIN не размножает строки: у каждой позиции ровно один заказ,
-- а int_orders_with_payments содержит одну строку на заказ.
select
    i.order_item_id,
    i.order_id,
    i.product_id,
    o.customer_id,
    o.order_date,
    o.order_status,
    i.quantity,
    i.unit_price,
    i.gross_amount,
    i.discount_amount,
    i.line_amount,
    o.is_confirmed,
    o.is_test_order
from {{ ref('stg_shop__order_items') }} as i
join {{ ref('int_orders_with_payments') }} as o
    on o.order_id = i.order_id
