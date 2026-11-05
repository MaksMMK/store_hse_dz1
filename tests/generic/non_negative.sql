-- Значение колонки не меньше нуля.
{% test non_negative(model, column_name) %}

select {{ column_name }} as negative_value
from {{ model }}
where {{ column_name }} < 0

{% endtest %}
