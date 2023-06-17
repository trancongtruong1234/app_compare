{{ config(materialized='external', location="{{env_var('result_path')}}/VN15/RESULT_COMPARE_ORDER_REFERENCE_VN15_1.csv") }}
WITH dms_table AS (
  SELECT
    "order date" AS ORDER_DATE,
    RIGHT ("order reference",8) AS ORDER_REFERENCE,
    ROUND(SUM("quantity(ec)"),2) AS QUANTITY_EC,
    ROUND(SUM(NSR),0) AS NSR,
    SUM("quantity(ea)") AS QUANTITY_EA
  FROM  {{source('duck_source_dms','SaleSummary_C1V1_VN15_0523')}}
  GROUP BY ORDER_DATE, ORDER_REFERENCE
),
mm_table AS (
    select 
        "Date" AS ORDER_DATE,
        CASE
            WHEN Column1 LIKE '%-%' THEN SUBSTR(Column1,1,INSTR(Column1,'-') + INSTR(SUBSTR(Column1,INSTR(Column1,'-')+1,4),'-')-1)
            ELSE REPLACE(Column1, '[^0-9]', '')
        END AS ORDER_REFERENCE,
        ROUND(SUM("SFA Deliv. Qty (VN) - EC"),2) AS QUANTITY_EC,
        SUM("SFA Deliv. NSR (VN)") AS NSR,
        SUM("SFA Deliv. Qty (VN) - EA") AS QUANTITY_EA 
    FROM {{source('duck_source_mm','MM_Sales_Summary_VN15')}}
    GROUP BY ORDER_DATE, ORDER_REFERENCE
),
combine_2_table AS (
    SELECT
        dms_table.ORDER_DATE AS DMS_ORDER_DATE,
        mm_table.ORDER_DATE AS MM_ORDER_DATE,
        dms_table.ORDER_REFERENCE AS DMS_ORDER_REFERENCE,
        mm_table.ORDER_REFERENCE AS MM_ORDER_REFERENCE,
        dms_table.QUANTITY_EC AS DMS_QUANTITY_EC,
        dms_table.NSR AS DMS_NSR,
        mm_table.QUANTITY_EC AS MM_QUANTITY_EC,
        mm_table.NSR AS MM_NSR,
        dms_table.QUANTITY_EA AS DMS_QUANTITY_EA,
        mm_table.QUANTITY_EA AS MM_QUANTITY_EA,
        CASE
            WHEN dms_table.ORDER_REFERENCE =  mm_table.ORDER_REFERENCE THEN 'TRUE'
            WHEN dms_table.ORDER_REFERENCE IS NULL AND  mm_table.ORDER_REFERENCE IS NULL THEN 'BOTH ARE NULL'
            WHEN dms_table.ORDER_REFERENCE IS NULL THEN 'VALUE IS NULL IN DMS ONLY'
            WHEN mm_table.ORDER_REFERENCE IS NULL THEN 'VALUE IS NULL IN MM ONLY'
            WHEN dms_table.ORDER_REFERENCE !=  mm_table.ORDER_REFERENCE THEN 'VALUES DO NOT MATCH'
            ELSE 'unknown' -- this should never happen
        END AS CHECK_SO
    FROM dms_table
    FULL OUTER JOIN mm_table 
        ON concat(dms_table.ORDER_DATE, '|', dms_table.ORDER_REFERENCE ) = concat(mm_table.ORDER_DATE, '|', mm_table.ORDER_REFERENCE )
),
check_GAP AS (
    SELECT
        DMS_ORDER_DATE,
        DMS_ORDER_REFERENCE,
        DMS_QUANTITY_EC,
        DMS_NSR,
        DMS_QUANTITY_EA,
        MM_ORDER_DATE,
        MM_ORDER_REFERENCE,
        MM_QUANTITY_EC,
        MM_NSR,
        MM_QUANTITY_EA,
        DMS_QUANTITY_EC - MM_QUANTITY_EC AS GAP_QUANTITY_EC,
        DMS_NSR - MM_NSR AS GAP_NSR,
        DMS_QUANTITY_EA - MM_QUANTITY_EA AS GAP_QUANTITY_EA,
        CHECK_SO
    FROM combine_2_table
)
SELECT *,
	CASE 
		WHEN CHECK_SO != 'TRUE' OR GAP_QUANTITY_EC != 0 OR GAP_NSR != 0 OR GAP_QUANTITY_EA != 0 THEN 'GAP'
		ELSE 'MATCH'
	END AS STATUS
FROM check_GAP