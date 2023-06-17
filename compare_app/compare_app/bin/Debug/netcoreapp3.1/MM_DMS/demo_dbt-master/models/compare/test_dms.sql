{{ config(materialized='external', location="{{env_var('result_path')}}/test_dms.csv") }}
  SELECT DISTINCT
  SUBSTR("order date",1,INSTR("order date",`/`)),
  "order date"
  FROM {{source('duck_source_dms','SaleSummary_C1V1_VN15_0523')}}