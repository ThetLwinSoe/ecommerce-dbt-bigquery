{% macro get_date_spine(start_date, end_date) %}
/*
    Utility macro: get_date_spine
    Generates a table of consecutive dates between start and end.
    Useful for gap-filling in daily sales charts.

    Usage:
        {{ get_date_spine('2019-05-20', '2019-06-19') }}
*/
with date_spine as (
    {{ dbt_utils.date_spine(
        datepart   = "day",
        start_date = "cast('" ~ start_date ~ "' as date)",
        end_date   = "cast('" ~ end_date   ~ "' as date)"
    ) }}
)
select cast(date_day as date) as calendar_date
from date_spine
{% endmacro %}
