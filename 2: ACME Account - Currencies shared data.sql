// Show the Simple Country Code to Currency Code Mapping
/*
Based on the billing address of a customer, look up which currency applies to the order.
*/
select * from public.country_code_to_currency_code;

alter view intl_db.public.NATIONS_SAMPLE_PLUS_ISO
set secure;

alter view intl_db.public.SIMPLE_CURRENCY
set secure;

select *
from int_stds_org_3166;
