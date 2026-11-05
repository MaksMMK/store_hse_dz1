-- Одна строка — один заказ, без тестовых заказов.
{{ config(distributed_by='order_id') }}

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.ordered_at,
    o.order_status,
    o.order_amount,
    coalesce(i.items_count, 0) as items_count,
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
