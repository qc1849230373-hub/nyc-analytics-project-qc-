WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dog_licensing') }}
), 
cleaned AS (
   SELECT
       * EXCEPT (
           animalname,
           animalgender,
           animalbirth,
           breedname,
           zipcode,
           licenseissueddate,
           licenseexpireddate,
           extract_year
       ),

       -- Date/Time
       CAST(licenseissueddate AS TIMESTAMP) AS license_issued_date,
       CAST(licenseexpireddate AS TIMESTAMP) AS license_expired_date,
       CAST(extract_year AS TIMESTAMP) AS extract_year,
       CAST(animalbirth AS TIMESTAMP) AS animal_birth,

       -- Request details
       CAST(animalname AS STRING) AS animal_name,
       CAST(animalgender AS STRING) AS animal_gender,
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
       END AS zipcode,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER ( ORDER BY licenseissueddate DESC) = 1
)

SELECT * FROM cleaned