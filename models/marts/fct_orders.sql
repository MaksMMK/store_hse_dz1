-- Факт заказов: одна строка — один заказ. Тестовые заказы в витрину не попадают.
-- Распределение по order_id: так же распределены raw.orders, raw.order_items, raw.payments
-- и fct_order_items, поэтому JOIN по order_id идёт локально на каждом сегменте.
{{ config(distributed_by='order_id') }}

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.ordered_at,
    o.order_status,
    o.order_amount,
    coalesce(i.items_count, 0) as items_count,   -- 0 вместо null, если у заказа нет позиций
    o.paid_amount,
    o.refunded_amount,
    o.net_paid_amount,
    o.successful_payments_count,
    o.first_paid_at,
    o.is_confirmed
from {{ ref('int_orders_with_payments') }} as o
left join {{ ref('int_order_items_aggregated') }} as i
    on i.order_id = o.order_id
where not o.is_test_order
