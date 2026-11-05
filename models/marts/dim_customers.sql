-- Одна строка — один клиент. left join, чтобы не потерять клиентов без покупок.
{{ config(distributed_replicated=true) }}

select
    c.customer_id,
    c.registered_at,
    c.registration_date,
    c.city,
    c.acquisition_channel,
    s.first_confirmed_order_id,
    s.first_confirmed_at,
    coalesce(s.confirmed_orders_count, 0)   as confirmed_orders_count,
    coalesce(s.confirmed_revenue, 0)        as confirmed_revenue,
    s.customer_id is not null               as is_buyer
from {{ ref('stg_shop__customers') }} as c
left join {{ ref('int_customer_order_stats') }} as s
    on s.customer_id = c.customer_id
