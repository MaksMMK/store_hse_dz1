-- Одна строка — один клиент с подтверждёнными покупками.
with confirmed_orders as (
    select
        customer_id,
        order_id,
        ordered_at,
        order_amount,
        -- order_id нужен: заказы 101 и 102 оформлены в одну секунду
        row_number() over (
            partition by customer_id
            order by ordered_at, order_id
        ) as purchase_number
    from {{ ref('int_orders_with_payments') }}
    where is_confirmed
)

select
    customer_id,
    max(order_id)   filter (where purchase_number = 1) as first_confirmed_order_id,
    max(ordered_at) filter (where purchase_number = 1) as first_confirmed_at,
    count(*)                                           as confirmed_orders_count,
    sum(order_amount)                                  as confirmed_revenue
from confirmed_orders
group by customer_id
