-- first_confirmed_order_id указывает на самую раннюю подтверждённую покупку клиента.
-- При одинаковом времени первым считается заказ с меньшим номером.
with ranked_orders as (
    select
        customer_id,
        order_id,
        row_number() over (
            partition by customer_id
            order by ordered_at, order_id
        ) as purchase_number
    from {{ ref('fct_orders') }}
    where is_confirmed
)

select
    d.customer_id,
    d.first_confirmed_order_id,
    r.order_id as expected_order_id
from {{ ref('dim_customers') }} as d
join ranked_orders as r
    on r.customer_id = d.customer_id
   and r.purchase_number = 1
where d.first_confirmed_order_id is distinct from r.order_id
