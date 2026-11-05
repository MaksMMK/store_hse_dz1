-- Одна строка — один товар с цепочкой категорий. Связь с категорией идёт по названию.
{{ config(distributed_replicated=true) }}

select
    p.product_id,
    p.product_name,
    p.brand,
    p.category_name,
    c.parent_category_name,
    c.root_category_name,
    c.category_level,
    c.category_path
from {{ ref('stg_shop__products') }} as p
left join {{ ref('int_product_categories_flattened') }} as c
    on c.category_name = p.category_name
