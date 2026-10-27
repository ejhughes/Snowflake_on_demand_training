
-------- SELECT on Sample Data ---------------------

--Check the range of values in the Market Segment Column
select distinct c_mktsegment
from snowflake_sample_data.tpch_sf1.customer; 

--Find out which Market Segments have the most customers
select c_mktsegment, count(*)
from snowflake_sample_data.tpch_sf1.customer
group by c_mktsegment
order by count(*);

---------- Joins & Aggregations on Sample Data --------------
-- Nations Table
select n_nationkey, n_name, n_regionkey
from snowflake_sample_data.tpch_sf1.nation;


-- Regions Table
select r_regionkey, r_name
from snowflake_sample_data.tpch_sf1.region;


-- Join the Tables and Sort
select r_name as region, n_name as nation
from snowflake_sample_data.tpch_sf1.nation
join snowflake_sample_data.tpch_sf1.region
on n_regionkey = r_regionkey
order by r_name, n_name asc;

--Group and Count Rows Per Region
select r_name as region, count(n_name) as num_countries
from snowflake_sample_data.tpch_sf1.nation
join snowflake_sample_data.tpch_sf1.region
on n_regionkey = r_regionkey
group by r_name;

---------- Set up a new database / warehouse --------------

use role SYSADMIN;

create database INTL_DB;

use schema INTL_DB.PUBLIC;

-----

use role SYSADMIN;

create warehouse INTL_WH 
with 
warehouse_size = 'XSMALL' 
warehouse_type = 'STANDARD' 
auto_suspend = 600 --600 seconds/10 mins
auto_resume = TRUE;

use warehouse INTL_WH;

---- Create a table --------

create or replace table intl_db.public.INT_STDS_ORG_3166 
(iso_country_name varchar(100), 
 country_name_official varchar(200), 
 sovreignty varchar(40), 
 alpha_code_2digit varchar(2), 
 alpha_code_3digit varchar(3), 
 numeric_country_code integer,
 iso_subdivision varchar(15), 
 internet_domain_code varchar(10)
);

---- Create a file format for CSV -----------
create or replace file format util_db.public.PIPE_DBLQUOTE_HEADER_CR 
  type = 'CSV' --use CSV for any flat file
  compression = 'AUTO' 
  field_delimiter = '|' --pipe or vertical bar
  record_delimiter = '\r' --carriage return
  skip_header = 1  --1 header row
  field_optionally_enclosed_by = '\042'  --double quotes
  trim_space = FALSE;

 show stages in account;

 list @util_db.public.aws_s3_bucket;

 copy into int_stds_org_3166
 from @util_db.public.aws_s3_bucket
 files = ('ISO_Countries_UTF8_pipe.csv')
 file_format = (format_name = util_db.public.PIPE_DBLQUOTE_HEADER_CR );

 select *
 from int_stds_org_3166;

--- check table exists in information schema -----

select count(*) as OBJECTS_FOUND
from INTL_DB.INFORMATION_SCHEMA.TABLES ------ from DATABASE_NAME.information_schema.tables
where table_schema='PUBLIC' ----------------- where table_schema = SCHEMA_NAME
and table_name= 'INT_STDS_ORG_3166'; -------- and table_name = TABLE_NAME
--------------------------------------------- Result should be 'Objects_found: 1'

--- check row count from information schema --------

select row_count
from INTL_DB.INFORMATION_SCHEMA.TABLES
where table_schema='PUBLIC'
and table_name= 'INT_STDS_ORG_3166'; 

---- join local data with shared data -----
select  
     iso_country_name
    ,country_name_official
    ,alpha_code_2digit
    ,r_name as region
from INTL_DB.PUBLIC.INT_STDS_ORG_3166 i
left join SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION n
on upper(i.iso_country_name)= n.n_name
left join SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION r
on n_regionkey = r_regionkey;

--- convert query into a View ----
create view intl_db.public.NATIONS_SAMPLE_PLUS_ISO 
( iso_country_name
  ,country_name_official
  ,alpha_code_2digit
  ,region) AS
        select  
            iso_country_name
            ,country_name_official
            ,alpha_code_2digit
            ,r_name as region
        from INTL_DB.PUBLIC.INT_STDS_ORG_3166 i
        left join SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION n
        on upper(i.iso_country_name)= n.n_name
        left join SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION r
        on n_regionkey = r_regionkey
;

select *
from intl_db.public.NATIONS_SAMPLE_PLUS_ISO;

----- Creating more tables --------------
create table intl_db.public.CURRENCIES 
(
  currency_ID integer, 
  currency_char_code varchar(3), 
  currency_symbol varchar(4), 
  currency_digital_code varchar(3), 
  currency_digital_name varchar(30)
)
  comment = 'Information about currencies including character codes, symbols, digital codes, etc.';

create table intl_db.public.COUNTRY_CODE_TO_CURRENCY_CODE 
  (
    country_char_code varchar(3), 
    country_numeric_code integer, 
    country_name varchar(100), 
    currency_name varchar(100), 
    currency_char_code varchar(3), 
    currency_numeric_code integer
  ) 
  comment = 'Mapping table currencies to countries';

create file format util_db.public.CSV_COMMA_LF_HEADER
  type = 'CSV' 
  field_delimiter = ',' 
  record_delimiter = '\n' -- the n represents a Line Feed character
  skip_header = 1 
;

copy into currencies
from @util_db.public.aws_s3_bucket
files = ('currencies.csv')
file_format = (format_name = util_db.public.CSV_COMMA_LF_HEADER);

copy into country_code_to_currency_code
from @util_db.public.aws_s3_bucket
files = ('country_code_to_currency_code.csv')
file_format = (format_name = util_db.public.CSV_COMMA_LF_HEADER);

---- Create a View -----------
create view intl_db.public.SIMPLE_CURRENCY
(
CTY_CODE
, CUR_CODE
) as
select country_char_code as CTY_CODE
    , currency_char_code as CUR_CODE
from country_code_to_currency_code;

select * from simple_currency;

USE ROLE ORGADMIN;
SELECT SYSTEM$ENABLE_GLOBAL_DATA_SHARING_FOR_ACCOUNT('YW18830');

SELECT SYSTEM$IS_GLOBAL_DATA_SHARING_ENABLED_FOR_ACCOUNT('YW18830'); --- this should return as TRUE

alter view intl_db.public.NATIONS_SAMPLE_PLUS_ISO
set secure; 

alter view intl_db.public.SIMPLE_CURRENCY
set secure; 
