use role sysadmin;

-- Create a new database and set the context to use the new database
create database library_card_catalog comment = 'DWW Lesson 10 ';

--Set the worksheet context to use the new database
use database library_card_catalog;

-------------------------------------------------

use database library_card_catalog;
use role sysadmin;

-- Create the book table and use AUTOINCREMENT to generate a UID for each new row

create or replace table book
( book_uid number autoincrement
 , title varchar(50)
 , year_published number(4,0)
);

-- Insert records into the book table
-- You don't have to list anything for the
-- BOOK_UID field because the AUTOINCREMENT property 
-- will take care of it for you

insert into book(title, year_published)
values
 ('Food',2001)
,('Food',2006)
,('Food',2008)
,('Food',2016)
,('Food',2015);


-- Check your table. Does each row have a unique id? 
select * from book;


-------------------------------------------

-- Create Author table
create or replace table author (
   author_uid number 
  ,first_name varchar(50)
  ,middle_name varchar(50)
  ,last_name varchar(50)
);

-- Insert the first two authors into the Author table
insert into author(author_uid, first_name, middle_name, last_name)  
values
(1, 'Fiona', '','Macdonald')
,(2, 'Gian','Paulo','Faleschini');

-- Look at your table with its new rows
select * 
from author;

--------------------------------------

create sequence SEQ_AUTHOR_UID
    start = 3
    increment = 1
    ORDER,
    comment = 'Use this to fill in AUTHOR_UID';

--create sequence SEQ_AUTHOR_UID_WO_ORDER
--    start = 1
--    increment = 1
--    comment = 'Test of sequence without ORDER';

use role sysadmin;

select seq_author_uid.nextval;

--select seq_author_uid_wo_order.nextval;

show sequences;

--drop sequence seq_author_uid;
--select seq_author_uid.nextval, seq_author_uid.nextval;

insert into author(author_uid, first_name, middle_name, last_name)
values 
(seq_author_uid.nextval, 'Laura', 'K', 'Egendorf')
, (seq_author_uid.nextval, 'Jan', '', 'Grover')
, (seq_author_uid.nextval, 'Jennifer', '', 'Clapp')
, (seq_author_uid.nextval, 'Kathleen', '', 'Petelinsek');


----------------------------------------------

-- Create the relationships table (bridge table between book and author)
-- this is sometimes called a "Many-to-Many table"
create table book_to_author
( book_uid number
  ,author_uid number
);

--Insert rows of the known relationships
insert into book_to_author(book_uid, author_uid)
values
 (1,1)  -- This row links the 2001 book to Fiona Macdonald
,(1,2)  -- This row links the 2001 book to Gian Paulo Faleschini
,(2,3)  -- Links 2006 book to Laura K Egendorf
,(3,4)  -- Links 2008 book to Jan Grover
,(4,5)  -- Links 2016 book to Jennifer Clapp
,(5,6); -- Links 2015 book to Kathleen Petelinsek


--Check your work by joining the 3 tables together
--You should get 1 row for every author
select * 
from book_to_author ba 
join author a 
on ba.author_uid = a.author_uid 
join book b 
on b.book_uid=ba.book_uid; 

----------- UNSTRUCTURED DATA -----------------------

-- Create an Ingestion Table for JSON Data
create table library_card_catalog.public.author_ingest_json
(
  raw_author variant
);

--Create File Format for JSON Data 
create file format library_card_catalog.public.json_file_format
type = 'JSON' 
compression = 'AUTO' 
enable_octal = FALSE
allow_duplicate = FALSE
strip_outer_array = TRUE
strip_null_values = FALSE 
ignore_utf8_errors = FALSE; 

select $1
from @util_db.public.my_internal_stage/author_with_header.json
(file_format => library_card_catalog.public.json_file_format);

use role sysadmin;

copy into library_card_catalog.public.author_ingest_json
from @util_db.public.my_internal_stage
files = ('author_with_header.json')
file_format = (format_name = library_card_catalog.public.json_file_format);

--one column table
select * from author_ingest_json;

--separated columns table
SELECT 
 raw_author:AUTHOR_UID
,raw_author:FIRST_NAME::STRING as FIRST_NAME
,raw_author:MIDDLE_NAME::STRING as MIDDLE_NAME
,raw_author:LAST_NAME::STRING as LAST_NAME
FROM AUTHOR_INGEST_JSON;

------------ NESTED JSON DATA ---------------

-- create an Ingestion Table for the NESTED JSON Data
create or replace table library_card_catalog.public.nested_ingest_json 
(
  raw_nested_book VARIANT --raw_nested_book is the name of the column header when you do select * on nested_ingest_json
);

-- Add table to my_internal_stage
--Check/change ownnership of nested_ingest_json to sysadmin

--preview the data
select $1
from @util_db.public.my_internal_stage/json_book_author_nested.txt
(file_format => library_card_catalog.public.json_file_format);

--copy data into the relevant table
copy into nested_ingest_json
from @util_db.public.my_internal_stage
files = ('json_book_author_nested.txt')
file_format = (format_name = library_card_catalog.public.json_file_format);

--------- Query data checks ---------------------
select *
from nested_ingest_json;

select raw_nested_book
from nested_ingest_json;

select raw_nested_book:year_published
from nested_ingest_json;

select raw_nested_book:authors
from nested_ingest_json;

-------- Flattening the nested data ---------------

-- use these example flatten commands to explore flattening the nested book and author data

select value:first_name
from nested_ingest_json
, lateral flatten(input => raw_nested_book:authors);

select value:first_name
from nested_ingest_json
, table(flatten(input => raw_nested_book:authors));

-- add a CAST command to the fields returned
select value:first_name::varchar, value:last_name::varchar
from nested_ingest_json
, lateral flatten(input => raw_nested_book:authors);

-- assign new column  names to the columns using "AS"
select value:first_name::varchar first_nm
    , value:last_name::varchar last_nm
from nested_ingest_json
, lateral flatten(input => raw_nested_book:authors);
