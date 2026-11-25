-- Reviewing Data Types

use role sysadmin;

create or replace table util_db.public.my_data_types
(
  my_number number
, my_text varchar(10)
, my_bool boolean
, my_float float
, my_date date
, my_timestamp timestamp_tz
, my_variant variant
, my_array array
, my_object object
, my_geography geography
, my_geometry geometry
, my_vector vector(int,16)
);

select * from util_db.public.my_data_types;

-- Setup

create database zenas_athleisure_db;

drop schema public;

create schema products;

-- list command & querying staged data 

list @product_metadata;

select $1
from @product_metadata/product_coordination_suggestions.txt;

select $1
from @product_metadata/sweatsuit_sizes.txt;

select $1
from @product_metadata/swt_product_line.txt;

-- file formats for exploring staged data

-- ^ as row separators
create file format zmd_file_format_1
RECORD_DELIMITER = '^';

select $1
from @product_metadata/product_coordination_suggestions.txt
(file_format => zmd_file_format_1);

-- ^ as column separators
create file format zmd_file_format_2
FIELD_DELIMITER = '^';  

select $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
from @product_metadata/product_coordination_suggestions.txt
(file_format => zmd_file_format_2);

-- file format for product_coordinating_suggestions
create or replace file format zmd_file_format_3
FIELD_DELIMITER = '='
RECORD_DELIMITER = '^'
TRIM_SPACE = TRUE; 

select $1, $2
from @product_metadata/product_coordination_suggestions.txt
(file_format => zmd_file_format_3);

-- file format for sweatsuit_sizes
drop file format zmd_file_format_1;

create or replace file format zmd_file_format_1
RECORD_DELIMITER = ';'
TRIM_SPACE = TRUE;

select $1 as sizes_available  
from @product_metadata/sweatsuit_sizes.txt
(file_format => zmd_file_format_1);

-- file format for swt_product_line
drop file format zmd_file_format_2;

create or replace file format zmd_file_format_2
RECORD_DELIMITER = ';'
FIELD_DELIMITER = '|'
TRIM_SPACE = TRUE;

select $1, $2, $3
from @product_metadata/swt_product_line.txt
(file_format => zmd_file_format_2);

-- Tidying up sweatsuit_sizes in the select
-- And creating a View

create view zenas_athleisure_db.products.sweatsuit_sizes as (
    select REPLACE($1,char(13)||char(10)) as sizes_available  
    --char(13) is a Carriage Return, char(11) is a Line Feed. || concatenates the values to remove CRLF characters, aka \r\n
    from @product_metadata/sweatsuit_sizes.txt
    (file_format => zmd_file_format_1)
    where sizes_available != ''                               -- remove empty row 19 at the end of the table
);  

select * from sweatsuit_sizes;

-- Tidying up swt_product_line in the select
-- And creating a View

create view zenas_athleisure_db.products.sweatband_product_line as (
    select REPLACE($1,char(13)||char(10)) as product_code
        , $2 as headband_description
        , $3 as wristband_description
    from @product_metadata/swt_product_line.txt
    (file_format => zmd_file_format_2)
);

select * from sweatband_product_line;

-- Tidying up product_coordination_suggestions in the select
-- And creating a View

create view zenas_athleisure_db.products.sweatband_coordination as (
    select $1 as product_code, $2 as has_matching_sweatsuit
    from @product_metadata/product_coordination_suggestions.txt
    (file_format => zmd_file_format_3)
    );

select * from sweatband_coordination;

-- Exploring Sweatsuits Stage

list @sweatsuits;

-- THIS DOES NOT WORK WITH UNSTRUCTURED DATA
-- select $1
-- from sweatsuits/burgundy_sweatsuit.png;

select metadata$filename, COUNT(metadata$file_row_number)
from @sweatsuits
group by metadata$filename;

-- Directory tables for unstructured data (instead of file formats)

select * 
from directory(@sweatsuits);

-- using functioms on directory tables
select REPLACE(relative_path, '_', ' ') as no_underscores_filename
, REPLACE(no_underscores_filename, '.png') as just_words_filename
, INITCAP(just_words_filename) as product_name
from directory(@sweatsuits);

-- using nested functions
select INITCAP(REPLACE(REPLACE(relative_path, '_', ' '), '.png')) as product_name
from directory(@sweatsuits);

--create an internal table for some sweatsuit info
create or replace table zenas_athleisure_db.products.sweatsuits (
	color_or_style varchar(25),
	file_name varchar(50),
	price number(5,2)
);

--fill the new table with some data
insert into  zenas_athleisure_db.products.sweatsuits 
          (color_or_style, file_name, price)
values
 ('Burgundy', 'burgundy_sweatsuit.png',65)
,('Charcoal Grey', 'charcoal_grey_sweatsuit.png',65)
,('Forest Green', 'forest_green_sweatsuit.png',64)
,('Navy Blue', 'navy_blue_sweatsuit.png',65)
,('Orange', 'orange_sweatsuit.png',65)
,('Pink', 'pink_sweatsuit.png',63)
,('Purple', 'purple_sweatsuit.png',64)
,('Red', 'red_sweatsuit.png',68)
,('Royal Blue',	'royal_blue_sweatsuit.png',65)
,('Yellow', 'yellow_sweatsuit.png',67);

select * from zenas_athleisure_db.products.sweatsuits;

-- Joins with unstructured data

create view product_list as (
    select INITCAP(REPLACE(REPLACE(relative_path, '_', ' '), '.png')) as product_name
        , s.file_name
        , s.color_or_style
        , s.price
        , d.file_url
    from directory(@sweatsuits) d
    join zenas_athleisure_db.products.sweatsuits s
    on d.relative_path = s.file_name
);

create view catalog as(
    select * 
    from product_list p
    cross join sweatsuit_sizes
);

-- Add a table to map the sweatsuits to the sweat band sets
create table zenas_athleisure_db.products.upsell_mapping
(
sweatsuit_color_or_style varchar(25)
,upsell_product_code varchar(10)
);

--populate the upsell table
insert into zenas_athleisure_db.products.upsell_mapping
(
sweatsuit_color_or_style
,upsell_product_code 
)
VALUES
('Charcoal Grey','SWT_GRY')
,('Forest Green','SWT_FGN')
,('Orange','SWT_ORG')
,('Pink', 'SWT_PNK')
,('Red','SWT_RED')
,('Yellow', 'SWT_YLW');

-- Zena needs a single view she can query for her website prototype
create view catalog_for_website as 
select color_or_style
,price
,file_name
, get_presigned_url(@sweatsuits, file_name, 3600) as file_url
,size_list
,coalesce('Consider: ' ||  headband_description || ' & ' || wristband_description, 'Consider: White, Black or Grey Sweat Accessories')  as upsell_product_desc
from
(   select color_or_style, price, file_name
    ,listagg(sizes_available, ' | ') within group (order by sizes_available) as size_list
    from catalog
    group by color_or_style, price, file_name
) c
left join upsell_mapping u
on u.sweatsuit_color_or_style = c.color_or_style
left join sweatband_coordination sc
on sc.product_code = u.upsell_product_code
left join sweatband_product_line spl
on spl.product_code = sc.product_code;

select * from catalog_for_website;
