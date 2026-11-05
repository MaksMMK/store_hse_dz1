-- Сумма заказа равна сумме его позиций. full join ловит заказ без позиций и позиции без заказа.
with items as (
    select order_id, sum(line_amount) as items_amount
    from {{ ref('fct_order_items') }}
    group by order_id
)

select
    coalesce(o.order_id, i.order_id) as order_id,
    o.order_amount,
    i.items_amount
from {{ ref('fct_orders') }} as o
full join items as i
    on i.order_id = o.order_id
where o.order_amount is distinct from i.items_amount
