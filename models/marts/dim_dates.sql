-- Календарь: все дни от первого до последнего заказа.
{{ config(distributed_replicated=true) }}

with date_bounds as (
    select
        min(order_date)::timestamp as first_date,
        max(order_date)::timestamp as last_date
    from {{ ref('stg_shop__orders') }}
),

days as (
    select generate_series(first_date, last_date, interval '1 day')::date as date_day
    from date_bounds
)

select
    date_day,
    extract(year from date_day)::int                    as year_number,
    extract(quarter from date_day)::int                 as quarter_number,
    extract(month from date_day)::int                   as month_number,
    to_char(date_day, 'YYYY-MM')                        as year_month,
    to_char(date_day, 'FMMonth')                        as month_name,
    extract(day from date_day)::int                     as day_of_month,
    extract(isodow from date_day)::int                  as day_of_week,
    to_char(date_day, 'FMDay')                          as day_name,
    extract(isodow from date_day) in (6, 7)             as is_weekend
from days
