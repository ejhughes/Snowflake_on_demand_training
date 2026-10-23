create table garden_plants.veggies.vegetable_details
(
plant_name varchar(25)
, root_depth_code varchar(1)    
);

select *
from vegetable_details
where plant_name = 'Spinach'
    and root_depth_code='D';

delete from vegetable_details
where plant_name='Spinach'
    and root_depth_code='D';

select * from vegetable_details;

create or replace table vegetable_details_soil_type
(plant_name varchar(25)
,soil_type number(1,0)
);

create file format garden_plants.veggies.PIPECOLSEP_ONEHEADROW 
    type = 'CSV'--csv is used for any flat file (tsv, pipe-separated, etc)
    field_delimiter = '|' --pipes as column separators
    skip_header = 1 --one header row to skip
    ;

copy into vegetable_details_soil_type
from @util_db.public.my_internal_stage
files = ('VEG_NAME_TO_SOIL_TYPE_PIPE.txt')
file_format = ( format_name=garden_plants.veggies.PIPECOLSEP_ONEHEADROW );

create file format garden_plants.veggies.COMMASEP_DBLQUOT_ONEHEADROW 
    TYPE = 'CSV'--csv for comma separated files
    FIELD_DELIMITER = ',' --commas as column separators
    SKIP_HEADER = 1 --one header row  
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
--this means that some values will be wrapped in double-quotes bc they have commas in them
    ;

--The data in the file, with no FILE FORMAT specified
select $1
from @util_db.public.my_internal_stage/LU_SOIL_TYPE.tsv;

--Same file but with one of the file formats we created earlier  
select $1, $2, $3
from @util_db.public.my_internal_stage/LU_SOIL_TYPE.tsv
(file_format => garden_plants.veggies.COMMASEP_DBLQUOT_ONEHEADROW);

--Same file but with the other file format we created earlier
select $1, $2, $3
from @util_db.public.my_internal_stage/LU_SOIL_TYPE.tsv
(file_format => garden_plants.veggies.PIPECOLSEP_ONEHEADROW );

create or replace file format garden_plants.veggies.L9_CHALLENGE_FF 
    TYPE = 'CSV'--csv for comma separated files
    FIELD_DELIMITER = '\t' --tab as column separators
    SKIP_HEADER = 1 --one header row  
    ;
    
select $1 , $2, $3
from @util_db.public.my_internal_stage/LU_SOIL_TYPE.tsv
(file_format => garden_plants.veggies.L9_CHALLENGE_FF );

create or replace table LU_SOIL_TYPE(
SOIL_TYPE_ID number,
SOIL_TYPE varchar(15),
SOIL_DESCRIPTION varchar(75)
);

copy into LU_SOIL_TYPE
from @util_db.public.my_internal_stage
files = ('LU_SOIL_TYPE.tsv')
file_format = ( format_name=garden_plants.veggies.L9_CHALLENGE_FF );

select *
from LU_SOIL_TYPE;

create or replace table VEGETABLE_DETAILS_PLANT_HEIGHT(
PLANT_NAME varchar(25),
UOM varchar(1),
LOW_END_OF_RANGE number,
HIGH_END_OF_RANGE number
);

select $1 , $2, $3, $4
from @util_db.public.my_internal_stage/veg_plant_height.csv
(file_format => garden_plants.veggies.COMMASEP_DBLQUOT_ONEHEADROW  );

copy into VEGETABLE_DETAILS_PLANT_HEIGHT
from @util_db.public.my_internal_stage
files = ('veg_plant_height.csv')
file_format = (format_name=garden_plants.veggies.COMMASEP_DBLQUOT_ONEHEADROW );

select *
from vegetable_details_plant_height;
