-- Одна строка — один заказ. Считаем товары до JOIN, иначе заказ размножится.
select
    order_id,
    count(distinct product_id)      as items_count
from {{ ref('stg_shop__order_items') }}
group by order_id
