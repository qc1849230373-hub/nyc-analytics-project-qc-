-- Clean and standardize nyc dog licensing data
-- One row per application

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dog_licensing') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           extract_year,
           animalname,
           animalgender
           breedname,
           zipcode,
           licenseissueddate,
           licenseexpireddate,
       ),

       -- Identifiers

       -- Date/Time
       CAST(extract_year AS TIMESTAMP) AS time_of_submission,
       CAST(licenseissueddate AS TIMESTAMP) AS license_issued_date,
       CAST(licenseexpireddate AS TIMESTAMP) AS license_expired_date,

       -- Request details
       CAST(animalname AS STRING) AS animal_name,
       CAST(breedname AS STRING) AS breed_name,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zipcode AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zipcode AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zipcode AS STRING)) = 5 THEN CAST(zipcode AS STRING)
           WHEN LENGTH(CAST(zipcode AS STRING)) = 9 THEN CAST(zipcode AS STRING)
           WHEN LENGTH(CAST(zipcode AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zipcode AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zipcode AS STRING)
           ELSE NULL
       END AS zip_code,

       -- Clearer column name as well for this one

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE animalname IS NOT NULL
   AND licenseissueddate IS NOT NULL
   AND CAST(licenseissueddate AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND licenseexpireddate IS NOT NULL

   -- Deduplicate
)

SELECT * FROM cleaned
-- All shoulld be part of this table: stg_nyc_dog_licensing