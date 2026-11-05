-- Staging категорий: одна строка — одна категория.
-- Дерево здесь не разворачиваем: это рекурсия, ей место в intermediate.
with source as (
    select * from {{ source('shop', 'product_categories') }}
)

select
    category_id,
    parent_category_id,
    category_name,
    parent_category_id is null      as is_root_category   -- true у верхнего уровня
from source
