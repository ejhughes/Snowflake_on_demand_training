create or replace table root_depth (
    root_depth_id number(1),
    root_depth_code text(1),
    root_depth_name text(7),
    unit_of_measure text(2),
    range_min number(2),
    range_max number(2)
    );

insert into root_depth
values
(
    2,
    'M',
    'medium',
    'cm',
    45,
    60
);

select * 
from root_depth;

delete from root_depth
where root_depth_id=3;
