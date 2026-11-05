-- Staging товаров: одна строка — один товар.
-- В источнике категория записана текстом. Переименовываем колонку,
-- чтобы она совпадала с category_name в справочнике категорий.
with source as (
    select * from {{ source('shop', 'products') }}
)

select
    product_id,
    product_name,
    brand,
    category                        as category_name
from source
