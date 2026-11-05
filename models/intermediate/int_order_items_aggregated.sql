-- Позиции, свёрнутые до заказа: одна строка — один заказ.
-- Сворачиваем до JOIN с заказами, иначе заказ размножится на число позиций.
select
    order_id,
    count(distinct product_id)      as items_count         -- число разных товаров в заказе
from {{ ref('stg_shop__order_items') }}
group by order_id
