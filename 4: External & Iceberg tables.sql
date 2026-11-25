use database mels_smoothie_challenge_db;

use schema trails;

-- version 1: does not work
-- because external tables cannot use internal stages (@trails_parquet)
create or replace external table T_CHERRY_CREEK_TRAIL(
my_filename varchar(100) as (metadata$filename::varchar(100))
)
location= @trails_parquet
auto_refresh = true
file_format = (type = parquet);

-- version 2: does work
-- connected to an external stage (data stored in AWS s3 bucket)
create or replace external table T_CHERRY_CREEK_TRAIL(
my_filename varchar(100) as (metadata$filename::varchar(100))
)
location= @external_aws_dlkw
auto_refresh = true
file_format = (type = parquet);

select * from T_CHERRY_CREEK_TRAIL;

-- Cannot put Materialized View on top of staged data
-- But you CAN put Materialized Views on top of External Tables based on a Stage

-- Creating a secure materlized view
create secure materialized view MELS_SMOOTHIE_CHALLENGE_DB.TRAILS.SMV_CHERRY_CREEK_TRAIL(
	POINT_ID,
	TRAIL_NAME,
	LNG,
	LAT,
	COORD_PAIR,
    DISTANCE_TO_MELANIES
) as(
    select 
        value:sequence_1 as point_id,
        value:trail_name::varchar as trail_name,
        value:latitude::number(11,8) as lng,    -- need to swap values for valid lat(0-90) & long(0-180)
        value:longitude::number(11,8) as lat,
        lng||' '||lat as coord_pair,
        locations.distance_to_mc(st_makepoint(lng,lat)) as distance_to_melanies
    from t_cherry_creek_trail                   -- from external table
);

-- Iceberg tables
-- creating an external volume, s3 bucket created for us
-- accountadmin role required
use role accountadmin;

CREATE OR REPLACE EXTERNAL VOLUME iceberg_external_volume
   STORAGE_LOCATIONS =
      (
         (
            NAME = 'iceberg-s3-us-west-2'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://uni-dlkw-iceberg'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::321463406630:role/dlkw_iceberg_role'
            STORAGE_AWS_EXTERNAL_ID = 'dlkw_iceberg_id'
         )
      );

-- check details, get user and share with Snowflake Learning Team
DESC EXTERNAL VOLUME iceberg_external_volume;

-- creating an iceberg database
create database my_iceberg_db
  catalog = 'SNOWFLAKE'
  external_volume = 'iceberg_external_volume';

-- creating a table
-- CCT = Cherry Creek Trail
set table_name = 'CCT_'||current_account();

create iceberg table identifier($table_name) (
    point_id number(10,0),
    trail_name string,
    coord_pair string,
    distance_to_melanies decimal(20,10),
    user_name string
)
  base_location = $table_name
  as
  select top 100
      point_id,
      trail_name,
      coord_pair,
      distance_to_melanies,
      current_user()
  from MELS_SMOOTHIE_CHALLENGE_DB.TRAILS.SMV_CHERRY_CREEK_TRAIL;

  select * from identifier($table_name);

  update identifier($table_name)
set user_name = 'I am amazing!!'
where point_id = 1;
