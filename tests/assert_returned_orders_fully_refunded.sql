-- Бизнес-правило: по возвращённому заказу деньги вернулись полностью.
select order_id, paid_amount, refunded_amount, net_paid_amount
from {{ ref('fct_orders') }}
where order_status = 'returned'
  and net_paid_amount <> 0
