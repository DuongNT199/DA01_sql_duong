-- Dataset: ThelookEcommerce - BIG QUERIES: https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce?q=search&referrer=search&project=sincere-torch-350709

-- Project start here:

-- I. Adhoc tasks:

/* 1. Số lượng đơn hàng và số lượng khách hàng mỗi tháng
Thống kê tổng số lượng người mua và số lượng đơn hàng đã hoàn thành mỗi tháng ( Từ 1/2019-4/2022)
Output: month_year ( yyyy-mm) , total_user, total_orde
*/

SELECT FORMAT_DATETIME('%Y-%m',created_at) AS ngay_tao_don
, COUNT(order_id) AS tong_don_hang
, COUNT(DISTINCT user_id) AS tong_khach_hang
FROM bigquery-public-data.thelook_ecommerce.orders
WHERE status = 'Complete' 
  AND created_at BETWEEN '2019-01-01' AND '2022-05-01'
GROUP BY 1
ORDER BY 1;

-- Kiểm tra moving average để thấy xu hướng của dữ liệu qua từng tháng
SELECT *
, ROUND(AVG(t.tong_don_hang) OVER (ORDER BY t.ngay_tao_don),2) AS moving_avg_dh
,  ROUND(AVG(t.tong_khach_hang) OVER (ORDER BY t.ngay_tao_don),2) AS moving_avg_kh
FROM
  (
    SELECT FORMAT_DATETIME('%Y-%m',created_at) AS ngay_tao_don
  , COUNT(order_id) AS tong_don_hang
  , COUNT(DISTINCT user_id) AS tong_khach_hang
  FROM bigquery-public-data.thelook_ecommerce.orders
  WHERE status = 'Complete' 
    AND created_at BETWEEN '2019-01-01' AND '2022-05-01'
  GROUP BY 1
  ORDER BY 1
  ) t

/* 
Insights: Số lượng khách hàng và đơn hàng nhìn chung có xu hướng tăng; 
Ngoài ra có thể thấy xuất hiện pattern số lượng đơn/ khách tăng nhiều vào đầu năm t1-t4 và gần cuối năm t9-t10
có thể do yếu tố mùa vụ hoặc các chương trình khuyến mãi
*/
