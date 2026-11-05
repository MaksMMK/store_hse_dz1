-- Клиент не может купить раньше, чем зарегистрировался.
select customer_id, registered_at, first_confirmed_at
from {{ ref('dim_customers') }}
where first_confirmed_at < registered_at
