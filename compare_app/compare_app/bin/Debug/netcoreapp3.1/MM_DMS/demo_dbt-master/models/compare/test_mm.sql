{{ config(materialized='external', location="{{env_var('result_path')}}/test_mm.csv") }}
WITH cte_test AS(
  SELECT 
        Column1
  FROM {{source('duck_source_mm','MM_Sales_Summary_VN15')}}
  WHERE Column1 like '%SOV%'
  UNION
  SELECT 
  'SOV-1000-95285928' AS Column1
)
select 
        CASE
            WHEN Column1 LIKE '%-%' THEN SUBSTR(Column1,1,INSTR(Column1,'-') + INSTR(SUBSTR(Column1,INSTR(Column1,'-')+1,10),'-')-1)
            ELSE REPLACE(Column1, '[^0-9]', '')
        END AS ORDER_REFERENCE
  FROM cte_test