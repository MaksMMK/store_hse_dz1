-- Итоги подтверждённых покупок: одна строка — один клиент, у которого есть покупки.
-- Клиентов без покупок здесь нет, они появятся в dim_customers через left join.
with confirmed_orders as (
    select
        customer_id,
        order_id,
        ordered_at,
        order_amount,
        -- order_id нужен: заказы 101 и 102 клиента 1 оформлены в одну и ту же секунду.
        -- Без него «первая покупка» выбиралась бы случайно и менялась от запуска к запуску.
        row_number() over (
            partition by customer_id
            order by ordered_at, order_id
        ) as purchase_number
    from {{ ref('int_orders_with_payments') }}
    where is_confirmed   -- тестовые заказы отсеяны: у них статус test, а не paid
)

select
    customer_id,
    max(order_id)   filter (where purchase_number = 1) as first_confirmed_order_id,
    max(ordered_at) filter (where purchase_number = 1) as first_confirmed_at,
    count(*)                                           as confirmed_orders_count,
    sum(order_amount)                                  as confirmed_revenue
from confirmed_orders
group by customer_id
