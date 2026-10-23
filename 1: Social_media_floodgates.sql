--create a database named SOCIAL_MEDIA_FLOODGATES
create database SOCIAL_MEDIA_FLOODGATES;

--Create a table called TWEET_INGEST in the PUBLIC schema
--The table only needs 1 column. Name it RAW_STATUS
create table TWEET_INGEST
(
    RAW_STATUS variant
);

--check table
select * from tweet_ingest;

--In the meantime: Change schema ownership (and database?) to SysAdmin
--& Add json file to my_internal_stage

--Create a file format that is type json so that you can load in the file
create file format social_media_floodgates.public.json_file_format
type = 'JSON' 
compression = 'AUTO' 
enable_octal = FALSE
allow_duplicate = FALSE
strip_outer_array = TRUE
strip_null_values = FALSE 
ignore_utf8_errors = FALSE; 

--Check file format
select $1
from @util_db.public.my_internal_stage/nutrition_tweets.json
(file_format => social_media_floodgates.public.json_file_format);

--Copy into from json file to table
copy into tweet_ingest
from @util_db.public.my_internal_stage
files = ('nutrition_tweets.json')
file_format = (format_name = social_media_floodgates.public.json_file_format );

--run test queries

--simple select statements -- are you seeing 9 rows?
select * from tweet_ingest;

select raw_status
from tweet_ingest;

select raw_status:entities
from tweet_ingest;

select raw_status:entities:hashtags
from tweet_ingest;

--Explore looking at specific hashtags by adding bracketed numbers
--This query returns just the first hashtag in each tweet
select raw_status:entities:hashtags[0].text
from tweet_ingest;

--This version adds a WHERE clause to get rid of any tweet that 
--doesn't include any hashtags
select raw_status:entities:hashtags[0].text
from tweet_ingest
where raw_status:entities:hashtags[0].text is not null;

--Perform a simple CAST on the created_at key, to query it as a date field
--Add an ORDER BY clause to sort by the tweet's creation date
select raw_status:created_at::date
from tweet_ingest
order by raw_status:created_at::date;

--------------- Flatten and Isolate entities --------------------------------

--Flatten statements can return nested entities only (and ignore the higher level objects)
select value
from tweet_ingest
, lateral flatten(input => raw_status:entities:urls);

select value
from tweet_ingest
, table(flatten(raw_status:entities:urls));

--Flatten and return just the hashtag text, CAST the text as VARCHAR
select value:text::varchar hashtag_used
from tweet_ingest
, lateral flatten(input => raw_status:entities:hashtags);

--Add the Tweet ID and User ID to the returned table so we could join the hashtag back to it's source tweet
select raw_status:id as tweet_id
    ,raw_status:user:name::text as user_name
    ,value:text::varchar hashtag_used
from tweet_ingest
, lateral flatten(input => raw_status:entities:hashtags);

----------- Create a View of the URL Data looking "Normalized" ------------------------------

create or replace view social_media_floodgates.public.urls_normalized as
(
select raw_status:id as tweet_id
    ,raw_status:user:name::text as user_name
    ,value:display_url::text url_used
from tweet_ingest
, lateral flatten(input => raw_status:entities:urls)
);

-- do the same for hashtags data
create or replace view social_media_floodgates.public.hashtags_normalized as
(
select raw_status:id as tweet_id
    ,raw_status:user:name::text as user_name
    ,value:text::text hashtag_used
from tweet_ingest
, lateral flatten(input => raw_status:entities:hashtags)
);SOCIAL_MEDIA_FLOODGATES.PUBLIC
