-- Сверка: считаем подтверждённые покупки прямо по сырым таблицам и сравниваем с витриной.
with mart as (
    select
        count(*)                       as orders_count,
        coalesce(sum(order_amount), 0) as revenue
    from {{ ref('fct_orders') }}
    where is_confirmed
),

source_data as (
    select
        count(*)                       as orders_count,
        coalesce(sum(total_amount), 0) as revenue
    from {{ source('shop', 'orders') }}
    where status = 'paid'
      and order_id in (
          select order_id
          from {{ source('shop', 'payments') }}
          where payment_status = 'success'
            and amount > 0
      )
)

select
    mart.orders_count        as mart_orders_count,
    source_data.orders_count as source_orders_count,
    mart.revenue             as mart_revenue,
    source_data.revenue      as source_revenue
from mart
cross join source_data
where mart.orders_count <> source_data.orders_count
   or mart.revenue <> source_data.revenue
