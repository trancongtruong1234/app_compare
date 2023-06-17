{{ config(materialized='external', location="{{env_var('result_path')}}/COMPARE_ROUND6/RESULT_COMPARE_ROUND6.csv") }}
WITH invoice_dtl_6 AS 
(
  SELECT 
    CONCAT_WS('',"Distributor Code", "Invoice No") as pk,
    "Distributor Code" as distributor_code, 
    "Invoice No" as invoice_no, 
    SUM ("Promo Discount") AS promo_discount
  FROM {{source('duck_source','INVOICE_DTL_R6')}}
  GROUP BY 1,2,3
),
vn08_dist_promotion_6 AS 
(
  SELECT 
    CONCAT_WS('', "ERPMã","Số HĐ") AS pk,
    "ERPMã" AS erp_ma,
    "Số HĐ" AS so_hd,
    SUM("Số tiền KM") AS so_tien_km
  FROM {{source('duck_source','VN08_DIST_PROMOTION_R6')}}
  WHERE "Loại hình trả" != 'Tặng hàng' 
    AND "Tên CTKM" NOT LIKE '%Tra thuong%'
  GROUP BY 1,2,3
  
),
combine_2_tables AS (
  SELECT 
    invoice_dtl_6.distributor_code, 
    invoice_dtl_6.invoice_no,
    invoice_dtl_6.promo_discount,
    vn08_dist_promotion_6.erp_ma,
    vn08_dist_promotion_6.so_hd,
    vn08_dist_promotion_6.so_tien_km,
    invoice_dtl_6.promo_discount - vn08_dist_promotion_6.so_tien_km AS GAP
  FROM invoice_dtl_6
  FULL JOIN vn08_dist_promotion_6
  ON invoice_dtl_6.distributor_code = vn08_dist_promotion_6.erp_ma
  AND invoice_dtl_6.invoice_no = vn08_dist_promotion_6.so_hd
  WHERE vn08_dist_promotion_6.so_tien_km != '0' 
)
SELECT *,
  CASE
    WHEN GAP = 0 THEN 'Match'
    WHEN GAP!= 0 THEN 'Not Match'
    WHEN distributor_code IS NULL OR invoice_no IS NULL THEN 'Value in Invoice_DTL is NULL'
    WHEN erp_ma IS NULL OR so_hd IS NULL THEN 'Value in VN08_DIST is NULL'
  END AS Status
FROM combine_2_tables