-- Most of the content from this module was completed in a streamlit_app.py file

use warehouse compute_wh;

create database smoothies;

GRANT USAGE ON WAREHOUSE compute_wh TO ROLE accountadmin;
GRANT USAGE ON WAREHOUSE compute_wh TO ROLE sysadmin;

create table fruit_options (
    fruit_id int,
    fruit_name varchar(25)
);

create file format smoothies.public.two_headerrow_pct_delim
  type = CSV,
  skip_header = 2,
  field_delimiter = '%',
  trim_space = TRUE
;

SELECT $1, $2
FROM @smoothies.public.my_uploaded_files/fruits_available_for_smoothies.txt
(FILE_FORMAT => smoothies.public.two_headerrow_pct_delim);

-- Test copy into - we see data type errors because the column order does not match the table we created in snowflake.
COPY INTO smoothies.public.fruit_options
FROM @smoothies.public.my_uploaded_files
FILES = ('fruits_available_for_smoothies.txt')
FILE_FORMAT = (FORMAT_NAME = smoothies.public.two_headerrow_pct_delim)
ON_ERROR = ABORT_STATEMENT
VALIDATION_MODE = RETURN_ERRORS
PURGE = TRUE;

-- Edit column order to match snowflake table
SELECT $2 as fruit_id, $1 as fruit_name
FROM @smoothies.public.my_uploaded_files/fruits_available_for_smoothies.txt
(FILE_FORMAT => smoothies.public.two_headerrow_pct_delim);

-- Retry copy into script with re-ordered columns
COPY INTO smoothies.public.fruit_options
FROM (
select $2 as fruit_id, $1 as fruit_name
from  @smoothies.public.my_uploaded_files
)
FILES = ('fruits_available_for_smoothies.txt')
FILE_FORMAT = (FORMAT_NAME = smoothies.public.two_headerrow_pct_delim)
ON_ERROR = ABORT_STATEMENT
PURGE = TRUE;

create table smoothies.public.orders
    (
    ingredients varchar(200)
    );

-- testing sql insert statement used in streamlit app

insert into smoothies.public.orders(ingredients)
values ('Cantaloupe Guava Jackfruit Elderberries Figs');

select * from orders;

truncate table smoothies.public.orders;

-- adding customer name column to the orders table

alter table smoothies.public.orders add column name_on_order varchar(100);

insert into smoothies.public.orders(ingredients, name_on_order) values ('Dragon Fruit Honeydew Guava Apples Kiwi', 'Bill');

select * from orders;

-- adding order_filled column to the order table

alter table smoothies.public.orders add column order_filled boolean default false;

update smoothies.public.orders
set order_filled = true
where name_on_order is null;

-- create a sequence to use as row id

truncate table smoothies.public.orders;

create sequence SMOOTHIES.PUBLIC.order_seq
    start = 1
    increment = 2
    ORDER
    comment = 'Provide a unique id for each smoothie order';

alter table SMOOTHIES.PUBLIC.ORDERS 
add column order_uid integer --adds the column
default smoothies.public.order_seq.nextval  --sets the value of the column to sequence
constraint order_uid unique enforced; --makes sure there is always a unique value in the column;

-- dropping and recreating the orders table

create or replace table smoothies.public.orders (
       order_uid integer default smoothies.public.order_seq.nextval,
       order_filled boolean default false,
       name_on_order varchar(100),
       ingredients varchar(200),
       constraint order_uid unique (order_uid),
       order_ts timestamp_ltz default current_timestamp()
);

-- setting variables

set mystery_bag = 'This bag is empty!';
select $mystery_bag;

set var1 = 2;
set var2 = 5;
set var3 = 7;
select $var1 + $var2 + $var3;

use database util_db;

use role accountadmin;

create function sum_mystery_bag_vars (var1 number, var2 number, var3 number)
 returns number as 'select var1+var2+var3';

select sum_mystery_bag_vars(12,36,204);

set alternating_caps_phrase = 'aLtErNaTiNg CaPs';
select initcap($alternating_caps_phrase);

create function convert_str_to_init_caps (str_to_convert string)
 returns string as 'initcap(str_to_convert)';

create function neutralize_whining (statement text)
 returns string as 'initcap(statement)';

select neutralize_whining($alternating_caps_phrase);

-- add search_on column

use database smoothies;
use schema public;
use role sysadmin;

alter table smoothies.public.fruit_options
add column search_on varchar(50);

select * from fruit_options;

update fruit_options
set search_on = 'Dragonfruit'
where fruit_name = 'Dragon Fruit';

-- missing Cantaloupe and Yerba Mate
