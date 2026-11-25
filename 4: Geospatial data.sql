-- setup
use role sysadmin;

create database mels_smoothie_challenge_db;
drop schema public;
create schema trails;

create stage trails_geojson;
create stage trails_parquet;

create file format ff_json
    type = JSON;

create file format ff_parquet
    type = PARQUET;

-- query data in trails.stages
-- Note: we can use Select * to query unloaded data here!! instead of $1, $2, etc. 
-- The reason being that specifying json/parquet file formats indicates that the data will be in a single column, so there are no unknowns
select *               
from @trails_geojson
(file_format => ff_json);

select *
from @trails_parquet
(file_format => ff_parquet);

-- Parse parquet file into separate columns & create a view
create or replace view mels_smoothie_challenge_db.trails.cherry_creek_trail as(
    select 
        $1:sequence_1 as sequence_1,
        $1:trail_name::varchar as trail_name,
        $1:latitude::number(11,8) as lng,    -- need to swap values for valid lat(0-90) & long(0-180)
        $1:longitude::number(11,8) as lat,
        --$1:elevation::number(6,2) as elevation,
        --$1:sequence_2 as sequence_2
    from @trails_parquet
    (file_format => ff_parquet)
    order by sequence_1
);

-- formatting long lat as WKT compatible points
select top 100
    lng||' '||lat as coord_pair
    , 'POINT('||coord_pair||')' as trail_point
from cherry_creek_trail;

-- add WKT coords to the view using create or replace
create or replace view mels_smoothie_challenge_db.trails.cherry_creek_trail as(
    select 
        $1:sequence_1 as point_id,
        $1:trail_name::varchar as trail_name,
        $1:latitude::number(11,8) as lng,    -- need to swap values for valid lat(0-90) & long(0-180)
        $1:longitude::number(11,8) as lat,
        lng||' '||lat as coord_pair
    from @trails_parquet
    (file_format => ff_parquet)
    order by point_id
);

alter view 

select * from cherry_creek_trail;

-- create a linestring to copy into wkt playground (https://clydedacruz.github.io/openstreetmap-wkt-playground/)
-- listagg will aggregate all of the coord_pair points with commas in between
select 
'LINESTRING('||
listagg(coord_pair, ',') 
within group (order by point_id)
||')' as my_linestring
from cherry_creek_trail
where point_id <= 2450
group by trail_name;

-- Parse json file into separate columns & create a view
create view denver_area_trails as(
    select
    $1:features[0]:properties:Name::string as feature_name
    ,$1:features[0]:geometry:coordinates::string as feature_coordinates
    ,$1:features[0]:geometry::string as geometry
    ,$1:features[0]:properties::string as feature_properties
    ,$1:crs:properties:name::string as specs
    ,$1 as whole_object
    from @trails_geojson (file_format => ff_json)
); 
-- use geojson.io to visualize the data

 -- Exploring geospatial functions

 --Remember this code? 
select 
'LINESTRING('||
listagg(coord_pair, ',') 
within group (order by point_id)
||')' as my_linestring
,st_length(to_geography(my_linestring)) as length_of_trail --this line is new!
from cherry_creek_trail
group by trail_name;

-- Add trail length to the denver_area_trails view

-- test query
select feature_name
    , st_length(to_geography(whole_object)) as wo_length
    , st_length(to_geography(geometry)) as geom_length
from denver_area_trails;

-- how to retrieve underlying SQL for the denver_area_trails view
select get_ddl('view', 'DENVER_AREA_TRAILS');

-- update view
create or replace view DENVER_AREA_TRAILS(
	FEATURE_NAME,
	FEATURE_COORDINATES,
	GEOMETRY,
    TRAIL_LENGTH,
	FEATURE_PROPERTIES,
	SPECS,
	WHOLE_OBJECT,
	GEOM_LENGTH
) as(
    select
    $1:features[0]:properties:Name::string as feature_name
    ,$1:features[0]:geometry:coordinates::string as feature_coordinates
    ,$1:features[0]:geometry::string as geometry
    ,st_length(to_geography(geometry)) as trail_length
    ,$1:features[0]:properties::string as feature_properties
    ,$1:crs:properties:name::string as specs
    ,$1 as whole_object
    ,st_length(to_geography(geometry)) as geom_length
    from @trails_geojson (file_format => ff_json)
);

select *
from denver_area_trails;

-- bringing together the cherry_creek_trail data with the other denver_area_trails

--Create a view that will have similar columns to DENVER_AREA_TRAILS 
--Even though this data started out as Parquet, and we're joining it with geoJSON data
--So let's make it look like geoJSON instead.
create or replace view DENVER_AREA_TRAILS_2 as
select 
trail_name as feature_name
,'{"coordinates":['||listagg('['||lng||','||lat||']',',') within group (order by point_id)||'],"type":"LineString"}' as geometry
,st_length(to_geography(geometry))  as trail_length
from cherry_creek_trail
group by trail_name;

--Create a view that will have similar columns to DENVER_AREA_TRAILS 
select feature_name
    , to_geography(geometry) as my_linestring
    , trail_length
from DENVER_AREA_TRAILS
union all
select feature_name
    , to_geography(geometry) as my_linestring
    , trail_length
from DENVER_AREA_TRAILS_2;

--Add more GeoSpatial Calculations to get more GeoSpecial Information! 
--& create a View

create view trails_and_boundaries as (
    select feature_name
    , to_geography(geometry) as my_linestring
    , st_xmin(my_linestring) as min_eastwest
    , st_xmax(my_linestring) as max_eastwest
    , st_ymin(my_linestring) as min_northsouth
    , st_ymax(my_linestring) as max_northsouth
    , trail_length
    from DENVER_AREA_TRAILS
    union all
    select feature_name
    , to_geography(geometry) as my_linestring
    , st_xmin(my_linestring) as min_eastwest
    , st_xmax(my_linestring) as max_eastwest
    , st_ymin(my_linestring) as min_northsouth
    , st_ymax(my_linestring) as max_northsouth
    , trail_length
    from DENVER_AREA_TRAILS_2
);

select * from trails_and_boundaries;

-- Creating a bounding box polygon
select 'POLYGON(('|| 
    min(min_eastwest)||' '||max(max_northsouth)||','|| 
    max(max_eastwest)||' '||max(max_northsouth)||','|| 
    max(max_eastwest)||' '||min(min_northsouth)||','|| 
    min(min_eastwest)||' '||min(min_northsouth)||'))' AS my_polygon
from trails_and_boundaries;









