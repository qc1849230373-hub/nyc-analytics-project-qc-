-- Seating type dimension for open restaurant seating applications
WITH seating_types AS (
   SELECT DISTINCT
       seating_interest_sidewalk AS seating_interest,
    CASE
        WHEN LOWER(TRIM(approved_for_sidewalk_seating)) IN ('yes', 'y', 'true') THEN TRUE
        WHEN LOWER(TRIM(approved_for_sidewalk_seating)) IN ('no', 'n', 'false') THEN FALSE
        ELSE NULL
     AS approved_for_sidewalk,

    CASE
        WHEN LOWER(TRIM(approved_for_roadway_seating)) IN ('yes', 'y', 'true') THEN TRUE
        WHEN LOWER(TRIM(approved_for_roadway_seating)) IN ('no', 'n', 'false') THEN FALSE
        ELSE NULL
--TODO: Replace this comment with a CASE WHEN .. statement that handles the different possibilities for approved_for_sidewalk_seating and approved_for_roadway_seating in the data
--NOTE: The final result we want to select here is two boolean columns (TRUE or FALSE values in them), one column approved_for_sidewalk (TRUE or FALSE value), and one column approved_for_roadway 
      AS approved_for_roadway
   FROM stg_nyc_open_restaurant_apps--TODO: reference the appropriate staging table!
   WHERE seating_interest_sidewalk IS NOT NULL
),
seating_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key([
           'seating_interest',
           'approved_for_sidewalk',
           'approved_for_roadway'
       ]) }} AS seating_type_key,
                approved_for_sidewalk,
                approved_for_roadway
       -- TODO: fill in the rest of this SELECT statement
       --  based on the dimensional model!

   FROM seating_types
)

SELECT * FROM seating_dimension