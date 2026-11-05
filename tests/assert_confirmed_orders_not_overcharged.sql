-- С подтверждённого заказа не списали больше его суммы.
-- Заказ 113 оплачен дважды, поэтому warn (см. README).
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
