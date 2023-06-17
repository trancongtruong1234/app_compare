{{ config(materialized='external', location="{{env_var('result_path')}}/VN16/RESULT_COMPARE_ORDER_DATE_VN16.csv") }}
WITH dms_table AS (
  SELECT
    "order date" AS ORDER_DATE,
    ROUND(SUM("quantity(ec)"),2) AS QUANTITY_EC,
    ROUND(SUM(NSR),0) AS NSR,
    SUM("quantity(ea)") AS QUANTITY_EA
  FROM  {{source('duck_source_dms','SaleSummary_C1V1_VN16_0523')}}
  GROUP BY ORDER_DATE
),
mm_table AS (
    select 
        "Date" AS ORDER_DATE,
        ROUND(SUM("SFA Deliv. Qty (VN) - EC"),2) AS QUANTITY_EC,
        SUM("SFA Deliv. NSR (VN)") AS NSR,
        SUM("SFA Deliv. Qty (VN) - EA") AS QUANTITY_EA 
    FROM {{source('duck_source_mm','MM_Sales_Summary_VN16')}}
    GROUP BY ORDER_DATE
),
combine_2_table AS (
    SELECT
        dms_table.ORDER_DATE AS DMS_ORDER_DATE,
        mm_table.ORDER_DATE AS MM_ORDER_DATE,
        dms_table.QUANTITY_EC AS DMS_QUANTITY_EC,
        dms_table.NSR AS DMS_NSR,
        mm_table.QUANTITY_EC AS MM_QUANTITY_EC,
        mm_table.NSR AS MM_NSR,
        dms_table.QUANTITY_EA AS DMS_QUANTITY_EA,
        mm_table.QUANTITY_EA AS MM_QUANTITY_EA,
        CASE
            WHEN dms_table.ORDER_DATE =  mm_table.ORDER_DATE THEN 'TRUE'
            WHEN dms_table.ORDER_DATE IS NULL AND  mm_table.ORDER_DATE IS NULL THEN 'BOTH ARE NULL'
            WHEN dms_table.ORDER_DATE IS NULL THEN 'VALUE IS NULL IN DMS ONLY'
            WHEN mm_table.ORDER_DATE IS NULL THEN 'VALUE IS NULL IN MM ONLY'
            WHEN dms_table.ORDER_DATE !=  mm_table.ORDER_DATE THEN 'VALUES DO NOT MATCH'
            ELSE 'unknown' -- this should never happen
        END AS CHECK_SO
    FROM dms_table
    FULL OUTER JOIN mm_table 
        ON dms_table.ORDER_DATE = mm_table.ORDER_DATE
),
check_GAP AS (
    SELECT
        DMS_ORDER_DATE,
        DMS_QUANTITY_EC,
        DMS_NSR,
        DMS_QUANTITY_EA,
        MM_ORDER_DATE,
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
		WHEN CHECK_SO != 'TRUE' OR GAP_QUANTITY_EA != 0 THEN 'GAP'
		ELSE 'MATCH'
	END AS STATUS
FROM check_GAP