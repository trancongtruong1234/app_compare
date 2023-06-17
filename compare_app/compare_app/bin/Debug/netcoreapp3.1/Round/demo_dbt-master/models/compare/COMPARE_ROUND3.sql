{{ config(materialized='external', location="{{env_var('result_path')}}/COMPARE_ROUND3/RESULT_COMPARE_ROUND3.csv") }}
WITH vn04_off_pur_inv_opi AS
(
   SELECT 
        "Product Code" AS product_code, 
        SUM(CAST(Pack AS INT)) AS total_pack
   FROM {{source('duck_source','VN04_OFF_PUR_INV_OPI_R3')}}
   WHERE DataType = 'PromotionCOGS'
   GROUP BY "Product Code" 
),
vn08_dist_promotion AS
(
   SELECT 
        "Product Code" AS product_code,
        SUM(cast(Pack as INT)) AS total_pack
   FROM {{source('duck_source','VN08_DIST_PROMOTION_R3')}}
   GROUP BY "Product Code"
),
check_gap as (
	SELECT 
		vn04_off_pur_inv_opi.product_code AS vn04_product_code,
		vn04_off_pur_inv_opi.total_pack AS vn04_total_pack,
		vn08_dist_promotion.product_code AS vn08_product_code,
		vn08_dist_promotion.total_pack AS vn08_total_pack,
		vn08_dist_promotion.total_pack - vn04_off_pur_inv_opi.total_pack  as GAP
	FROM vn04_off_pur_inv_opi 
	FULL OUTER JOIN vn08_dist_promotion
	ON vn04_off_pur_inv_opi.product_code = vn08_dist_promotion.product_code
)
SELECT 
	vn04_product_code,
	vn04_total_pack,
	vn08_product_code,
	vn08_total_pack,
	GAP,
	CASE 
		WHEN GAP = 0 THEN 'Match'
		WHEN GAP !=0 THEN 'Not Match'
		WHEN vn08_product_code IS NULL AND vn04_product_code IS NULL THEN 'Both are NULL'
		WHEN vn04_product_code IS NULL THEN 'Value in VN04 is Null'
		WHEN vn08_product_code IS NULL THEN 'Value in VN08 is Null'
	END AS status
FROM check_gap