-- Разворачиваем дерево категорий: одна строка — одна категория,
-- к ней приписаны родитель, корень дерева и уровень вложенности.
--
-- Рекурсия идёт сверху вниз:
--   1) первый select берёт корни (Electronics, Home);
--   2) второй select добавляет детей уже найденных категорий и повторяется,
--      пока новых строк не останется.
-- Глубина нигде не записана, поэтому четвёртый уровень ничего не сломает.
with recursive category_tree as (

    select
        category_id,
        category_name,
        null::text                  as parent_category_name,
        category_name               as root_category_name,
        1                           as category_level,
        category_name               as category_path
    from {{ ref('stg_shop__product_categories') }}
    where parent_category_id is null

    union all

    select
        child.category_id,
        child.category_name,
        parent.category_name        as parent_category_name,
        parent.root_category_name,                             -- корень наследуется от родителя
        parent.category_level + 1   as category_level,
        parent.category_path || ' > ' || child.category_name   as category_path
    from {{ ref('stg_shop__product_categories') }} as child
    join category_tree as parent
        on child.parent_category_id = parent.category_id

)

select
    category_id,
    category_name,
    parent_category_name,
    root_category_name,
    category_level,
    category_path
from category_tree
