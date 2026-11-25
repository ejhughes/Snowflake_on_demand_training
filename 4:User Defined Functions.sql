-- Melanie's Location into a 2 Variables (mc for melanies cafe)
set mc_lng='-104.97300245114094';
set mc_lat='39.76471253574085';

--Confluence Park into a Variable (loc for location)
set loc_lng='-105.00840763333615'; 
set loc_lat='39.754141917497826';

--Test your variables to see if they work with the Makepoint function
select st_makepoint($mc_lng,$mc_lat) as melanies_cafe_point;
select st_makepoint($loc_lng,$loc_lat) as confluent_park_point;

--use the variables to calculate the distance from 
--Melanie's Cafe to Confluent Park
select st_distance(
        st_makepoint($mc_lng,$mc_lat)
        ,st_makepoint($loc_lng,$loc_lat)
        ) as mc_to_cp;

-- UDFs exercise setup
use role sysadmin;
use database mels_smoothie_challenge_db;
create schema locations;

-- function to calculate distance to Melanie's Cafe (mc)
create or replace function distance_to_mc(loc_lng number(38,32),loc_lat number(38,32))
    returns float
    as 
    $$
    st_distance(
        st_makepoint(-104.97300245114094,39.76471253574085)
        ,st_makepoint(loc_lng,loc_lat)
        )
    $$;

--Tivoli Center into the variables 
set tc_lng='-105.00532059763648'; 
set tc_lat='39.74548137398218';

select distance_to_mc($tc_lng,$tc_lat);

-- find distance from Melanie's Cafe to competing Juice Bars

-- create a view for the database of juice bars from openstreemap shared data (managed by Sonra)
create view competition as (
    select * 
    from OPENSTREETMAP_DENVER.DENVER.V_OSM_DEN_AMENITY_SUSTENANCE
    where 
        ((amenity in ('fast_food','cafe','restaurant','juice_bar'))
        and 
        (name ilike '%jamba%' or name ilike '%juice%'
         or name ilike '%superfruit%'))
     or 
        (cuisine like '%smoothie%' or cuisine like '%juice%')
);

-- find closest competitor
-- this statement does not use our UDF because Sonra data does not store simple lat/long coordinates (it has geojson data)
SELECT
 name
 ,cuisine
 , ST_DISTANCE(
    st_makepoint('-104.97300245114094','39.76471253574085')
    , coordinates
  ) AS distance_to_melanies
 ,*
FROM  competition
ORDER by distance_to_melanies;

-- update function to accept geography argument
CREATE OR REPLACE FUNCTION distance_to_mc(lng_and_lat GEOGRAPHY)
  RETURNS FLOAT
  AS
  $$
   st_distance(
        st_makepoint('-104.97300245114094','39.76471253574085')
        ,lng_and_lat
        )
  $$
  ;

  -- test UDF with Sonra data
SELECT
 name
 ,cuisine
 ,distance_to_mc(coordinates) AS distance_to_melanies
 ,*
FROM  competition
ORDER by distance_to_melanies;

-- Note: two versions of the UDF have been stored
-- which means both types of input (numerical lat/long or Geography) will be accepted

-- Bookstore example

-- Tattered Cover Bookstore McGregor Square
set tcb_lng='-104.9956203'; 
set tcb_lat='39.754874';

--this will run the first version of the UDF
select distance_to_mc($tcb_lng,$tcb_lat);

--this will run the second version of the UDF, bc it converts the coords 
--to a geography object before passing them into the function
select distance_to_mc(st_makepoint($tcb_lng,$tcb_lat));

--this will run the second version bc the Sonra Coordinates column
-- contains geography objects already
select name
, distance_to_mc(coordinates) as distance_to_melanies 
, ST_ASWKT(coordinates)
from OPENSTREETMAP_DENVER.DENVER.V_OSM_DEN_SHOP
where shop='books' 
and name like '%Tattered Cover%'
and addr_street like '%Wazee%';

-- Distance to Denver Bike Shops

--create view denver_bike_shops

create view denver_bike_shops as
    select name
        , distance_to_mc(coordinates)  as distance_to_melanies
        , coordinates
    from openstreetmap_denver.denver.v_osm_den_shop_outdoors_and_sport_vehicles
    where shop = 'bicycle';
