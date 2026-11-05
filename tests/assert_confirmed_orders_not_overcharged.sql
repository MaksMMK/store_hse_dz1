-- Бизнес-правило: с подтверждённого заказа не списали больше его суммы.
-- Тест находит реальную проблему в источнике: заказ 113 на 200 оплачен дважды, списано 400.
-- Данные не подгоняем: severity warn, сборка проходит, а проблема видна в отчёте. См. README.
{{ config(severity='warn') }}

select
    order_id,
    order_amount,
    paid_amount,
    successful_payments_count,
    net_paid_amount - order_amount as overcharged_amount
from {{ ref('fct_orders') }}
where is_confirmed
  and net_paid_amount > order_amount
