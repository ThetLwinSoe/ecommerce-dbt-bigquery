{% macro test_is_positive(model, column_name) %}
/*
    Custom test: is_positive
    Asserts that all non-null values in a column are > 0.
    Usage in YAML:
        tests:
          - is_positive
*/
select
    {{ column_name }} as failing_value,
    count(*) as row_count
from {{ model }}
where {{ column_name }} is not null
  and {{ column_name }} <= 0
group by 1
{% endmacro %}
