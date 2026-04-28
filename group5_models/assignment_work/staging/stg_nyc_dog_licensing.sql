WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dog_licensing') }}
),
cleaned AS (
   SELECT
       * EXCEPT (
           extract_year,
           animalname,
           animalgender,
           animalbirth,
           breedname,
           zipcode,
           licenseissueddate,
           licenseexpireddate,
       ),

       -- Date/Time
       CAST(extract_year AS TIMESTAMP) AS time_of_submission,
       CAST(licenseissueddate AS TIMESTAMP) AS license_issued_date,
       CAST(licenseexpireddate AS TIMESTAMP) AS license_expired_date,
       CAST(animalbirth AS TIMESTAMP) AS animal_birth,

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

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE animalname IS NOT NULL
   AND licenseissueddate IS NOT NULL
   AND CAST(licenseissueddate AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND licenseexpireddate IS NOT NULL

)

SELECT * FROM cleaned
-- All shoulld be part of this table: stg_nyc_dog_licensing