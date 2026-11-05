-- Свой generic-тест: значение колонки не меньше нуля.
-- Возвращает «плохие» строки. null не считается нарушением: за него отвечает not_null.
{% test non_negative(model, column_name) %}

select {{ column_name }} as negative_value
from {{ model }}
where {{ column_name }} < 0

{% endtest %}
