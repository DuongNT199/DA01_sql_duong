-- Dataset: ThelookEcommerce - BIG QUERIES: https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce?q=search&referrer=search&project=sincere-torch-350709

-- Project start here:

-- II. Adhoc tasks:

/* 1. Số lượng đơn hàng và số lượng khách hàng mỗi tháng
Thống kê tổng số lượng người mua và số lượng đơn hàng đã hoàn thành mỗi tháng ( Từ 1/2019-4/2022)
Output: month_year ( yyyy-mm) , total_user, total_orde
*/
-- Thống kê
SELECT FORMAT_DATETIME('%Y-%m',created_at) AS month_year
, COUNT(order_id) AS total_order
, COUNT(user_id) AS total_user
FROM bigquery-public-data.thelook_ecommerce.orders
WHERE status = 'Complete' 
  AND created_at BETWEEN '2019-01-01' AND '2022-05-01'
GROUP BY 1
ORDER BY 1;


-- Kiểm tra xu hướng với moving average
SELECT *
, ROUND(AVG(t.total_order) OVER (ORDER BY t.month_year),2) AS running_avg_dh
,  ROUND(AVG(t.total_user) OVER (ORDER BY t.month_year),2) AS running_avg_kh
, ROUND((t.total_order - LAG(t.total_order)  OVER (ORDER BY t.month_year))*100/LAG(t.total_order)  OVER (ORDER BY t.month_year),2) AS increase_ratio
FROM
  (
    SELECT FORMAT_DATETIME('%Y-%m',created_at) AS month_year
, COUNT(order_id) AS total_order
, COUNT(user_id) AS total_user
FROM bigquery-public-data.thelook_ecommerce.orders
WHERE status = 'Complete' 
  AND created_at BETWEEN '2019-01-01' AND '2022-05-01'
GROUP BY 1
ORDER BY 1
  ) t;
/* 
Insights: Số lượng khách hàng và đơn hàng đã hoàn thành nhìn chung có xu hướng tăng; 
Ngoài ra có thể thấy xuất hiện pattern số lượng đơn/ khách tăng nhiều vào đầu năm t1-t4 và gần cuối năm t9-t10
có thể do yếu tố màu vụ hoặc các chương trình khuyến mãi
*/

--------------------------------------------------------------------------------

/*
2. Giá trị đơn hàng trung bình (AOV) và số lượng khách hàng mỗi tháng
Thống kê giá trị đơn hàng trung bình và tổng số người dùng khác nhau mỗi tháng 
( Từ 1/2019-4/2022)
Output: month_year ( yyyy-mm), distinct_users, average_order_value
*/
-- Thống kê theo tháng
SELECT FORMAT_DATETIME('%Y-%m',created_at) AS month_year
, COUNT(DISTINCT user_id) AS distinct_users
, ROUND(SUM(sale_price)/COUNT(DISTINCT order_id),2) AS average_order_value
FROM bigquery-public-data.thelook_ecommerce.order_items
WHERE status = 'Complete' 
  AND created_at BETWEEN '2019-01-01' AND '2022-05-01'
GROUP BY 1
ORDER BY 1;

-- Thống kê theo tháng + tỷ lệ tăng %
SELECT *
, ROUND((a.distinct_users - LAG(a.distinct_users) OVER (ORDER BY a.create_year))/LAG(a.distinct_users) OVER (ORDER BY a.create_year)*100,2) AS increase_percentage_us
FROM
(
  SELECT FORMAT_DATETIME('%Y',created_at) AS create_year
  , COUNT(DISTINCT user_id) AS distinct_users
  , ROUND(SUM(sale_price)/COUNT(DISTINCT order_id),2) AS average_order_value
  FROM bigquery-public-data.thelook_ecommerce.order_items
  WHERE status = 'Complete' 
  AND created_at BETWEEN '2019-01-01' AND '2022-05-01'
  GROUP BY 1
  ORDER BY 1
) a
 ORDER BY 1;

/* 
Insights: Số lượng khách hàng mua hàng có xu hướng tăng, từ 2019 đến 2021 số lượng KH đã tăng đến 500%; 
Tuy nhiên từ 2021 đến 2022 số lượng KH giảm 50%
Giá trị đơn hàng trung bình dao động ổn định trong khoảng 80 - 95 đô
*/

--------------------------------------------------------------------------------
/*
3. Nhóm khách hàng theo độ tuổi
Tìm các khách hàng có trẻ tuổi nhất và lớn tuổi nhất theo từng giới tính ( Từ 1/2019-4/2022)
Output: first_name, last_name, gender, age, tag (hiển thị youngest nếu trẻ tuổi nhất, oldest nếu lớn tuổi nhất)
*/
-- Tạo bảng temp người nhỏ nhất và lớn nhất
CREATE TEMPORARY TABLE age_tag (first_name STRING, last_name STRING, gender STRING, age INT64, tag STRING) 
AS 
  SELECT first_name
  , last_name
  , gender
  , age
  , 'oldest' AS tag
  FROM bigquery-public-data.thelook_ecommerce.users
  WHERE age IN 
      (
        SELECT MAX(age) 
        FROM bigquery-public-data.thelook_ecommerce.users 
        GROUP BY gender
      )

  UNION ALL

  SELECT first_name
  , last_name
  , gender
  , age
  , 'youngest' AS tag
  FROM bigquery-public-data.thelook_ecommerce.users
  WHERE age IN 
      (
        SELECT MIN(age) 
        FROM bigquery-public-data.thelook_ecommerce.users 
        GROUP BY gender
      )
  ;
# temp table: nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_age_tag

-- Kiểm tra số lượng người nhỏ nhất và lớn nhất
SELECT DISTINCT age
, gender
, tag
, COUNT(*) OVER (PARTITION BY tag, gender) AS no_of_user_gender
, COUNT(*) OVER (PARTITION BY tag) AS no_of_user_age
FROM nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_age_tag
ORDER BY age;

/* 
Insights: Độ tuối trẻ nhất 12 tuổi có 1668 KH, lơn snhaats 70 tuổi có 1700 KH
Số lượng KH nữ ở cả 2 độ tuổi cao hơn số KH nam
*/

--------------------------------------------------------------------------------
/*
4.Top 5 sản phẩm mỗi tháng.
Thống kê top 5 sản phẩm có lợi nhuận cao nhất từng tháng (xếp hạng cho từng sản phẩm). 
Output: month_year ( yyyy-mm), product_id, product_name, sales, cost, profit, rank_per_month
*/
-- Tạo bảng temp chứa thông tin cần sử dụng
DROP TABLE IF EXISTS product_cat;
CREATE TEMPORARY TABLE product_cat 
AS
  SELECT OI.created_at
  , OI.product_id
  , PD.name
  , PD.category
  , OI.sale_price
  , PD.cost
  , OI.sale_price - PD.cost AS profit
  FROM bigquery-public-data.thelook_ecommerce.order_items OI
  JOIN bigquery-public-data.thelook_ecommerce.products PD
    ON OI.product_id = PD.id
  WHERE OI.status = 'Complete'
  ;

# temp: nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_product_cat
-- Thống kê top 5 sản phẩm lãi cao nhất mỗi tháng
SELECT *
FROM
(
  SELECT *
  , DENSE_RANK() OVER (PARTITION BY b.month_year ORDER BY b.profit DESC) AS rank_per_month
  FROM
  (
    SELECT FORMAT_DATETIME('%Y-%m',created_at) AS month_year
    , product_id
    , name AS product_name
    , ROUND(SUM(sale_price),2) AS sales
    , ROUND(SUM(cost),2) AS cost
    , ROUND(SUM(sale_price) - SUM(cost),2) AS profit
    FROM nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_product_cat
    WHERE created_at BETWEEN '2019-01-01' AND '2022-05-01'
    GROUP BY 1,2,3
  ) b
) c
WHERE c.rank_per_month <6
ORDER BY 1,7;

--------------------------------------------------------------------------------
/*
5.Doanh thu tính đến thời điểm hiện tại trên mỗi danh mục
Thống kê tổng doanh thu theo ngày của từng danh mục sản phẩm (category) trong 3 tháng qua ( giả sử ngày hiện tại là 15/4/2022)
Output: dates (yyyy-mm-dd), product_categories, revenue
*/

SELECT FORMAT_DATETIME('%Y-%m-%d',created_at) AS dates
, category AS product_categories
, ROUND(SUM(sale_price),2) AS revenue
FROM nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_product_cat
WHERE created_at BETWEEN '2019-01-14' AND '2022-04-16'
GROUP BY 1,2
ORDER BY 1;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- III. Tạo metric trước khi dựng dashboard
-- 1. Query dataset theo form yêu cầu
CREATE VIEW nguyenthuyduong.view.vw_ecommerce_analyst
AS

WITH rev_data AS 
(
  SELECT FORMAT_DATETIME('%Y-%m',OD.created_at) AS Month
  , FORMAT_DATETIME('%Y',OD.created_at) AS Year
  , PD.category AS Product_category
  , ROUND(SUM(OI.sale_price),2) AS TPV
  , COUNT(DISTINCT OI.order_id) AS TPO
  , ROUND(SUM(PD.cost),2) AS Total_cost
  , ROUND(SUM(OI.sale_price) - SUM(PD.cost),2) AS Total_profit
  FROM bigquery-public-data.thelook_ecommerce.orders OD
  JOIN bigquery-public-data.thelook_ecommerce.order_items OI
    ON OD.order_id = OI.order_id
  LEFT JOIN bigquery-public-data.thelook_ecommerce.products PD
    ON OI.product_id = PD.id
  WHERE OD.status = 'Complete'
  GROUP BY 2,1,3
  ORDER BY 2,1,3
)

SELECT RV.Month
, RV.Year
, RV.Product_category
, RV.TPV
, TPO
, ROUND((LEAD(RV.TPV,1) OVER (PARTITION BY RV.Product_category ORDER BY RV.Month ASC) - RV.TPV)*100/RV.TPV,2) || '%' AS Revenue_growth
, ROUND((LEAD(RV.TPO,1) OVER (PARTITION BY RV.Product_category ORDER BY RV.Month ASC) - RV.TPO)*100/RV.TPO,2) || '%' AS Order_growth
, RV.Total_cost
, RV.Total_profit
, ROUND(RV.Total_profit/RV.Total_cost,2) AS Profit_to_cost_ratio
FROM rev_data RV
ORDER BY 2,1;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

/* 2.Tạo retention cohort analysis*/
SELECT *
FROM
(
SELECT *
, ROW_NUMBER() OVER(PARTITION BY order_id, user_id ORDER BY created_at ) AS STT
FROM bigquery-public-data.thelook_ecommerce.orders
WHERE status ='Complete'
) d
WHERE d.STT >1;
-- no duplicate in orders table
DROP TABLE IF EXISTS thelook_cohort_data;
CREATE TEMP TABLE thelook_cohort_data
AS
SELECT user_id
, e.amount
, FORMAT_DATE('%Y-%m', e.first_purchase) AS cohort_date
, created_at
, (EXTRACT(year FROM created_at)-EXTRACT(year FROM first_purchase))*12 + (EXTRACT(month FROM created_at)-EXTRACT(month FROM first_purchase))+1 AS index_cohort
FROM
(
  SELECT user_id
  , sale_price AS amount
  , MIN(created_at) OVER (PARTITION BY user_id) AS first_purchase
  , created_at
  FROM bigquery-public-data.thelook_ecommerce.order_items
  WHERE status = 'Complete' AND created_at BETWEEN '2019-01-01' AND '2022-05-01'
) e;

-- temp table: nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_thelook_cohort_data
DROP TABLE IF EXISTS thelook_cohort_pivot;
CREATE TEMP TABLE thelook_cohort_pivot
AS

SELECT cohort_date
, index_cohort
, COUNT(DISTINCT user_id) AS number_customer
, ROUND(SUM(amount),2) AS revenue
FROM nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_thelook_cohort_data
WHERE index_cohort <5
GROUP BY 1,2
ORDER BY 1,2;

-- temp table: nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_thelook_cohort_pivot
-- Create cohort

-- Customer cohort
DROP TABLE IF EXISTS customer_cohort;
CREATE TEMP TABLE customer_cohort AS
    SELECT cohort_date
  , SUM(CASE WHEN index_cohort = 1 THEN number_customer ELSE 0 END) AS m1
  , SUM(CASE WHEN index_cohort = 2 THEN number_customer ELSE 0 END) AS m2
  , SUM(CASE WHEN index_cohort = 3 THEN number_customer ELSE 0 END) AS m3
  , SUM(CASE WHEN index_cohort = 4 THEN number_customer ELSE 0 END) AS m4
  FROM nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_thelook_cohort_pivot
  GROUP BY cohort_date
  ORDER BY cohort_date
;

-- temp table:nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_customer_cohort

-- Retention_cohort
SELECT cohort_date
, ROUND(m1/m1*100.00,2) || '%' AS m1
, ROUND(m2/m1*100.00,2) || '%' AS m2
, ROUND(m3/m1*100.00,2) || '%' AS m3
, ROUND(m4/m1*100.00,2) || '%' AS m4
FROM nguyenthuyduong._87304916977722d1ca2f73340fd60c2c0b7ff659._1d05dc64_d40e_4b60_b2d2_9405cc41ac5d_customer_cohort

/* 
Insight:
- Heat table retention cohort: https://docs.google.com/spreadsheets/d/1f_FjNg1GIqdLGsTCBvhkirYWMR8PZ1OT7w3KkO1GZME/edit?usp=sharing
- Nhìn chung công ty đang chưa mạnh việc giữ chân khách hàng với số lượng khách hàng mới quay lại mua hàng giảm đều qua tháng
- Ở tháng thứ 2 đã giảm hơn 90% lượng khách và đến tháng thứ 3 hầu như không giữ được khách nào quay lại
Đề xuất:
- Công ty cần xem xét và khảo sát lý do vì sao khách hàng rời bỏ / lý do vì sao không giữ chân được khách hàng
- Nếu lí do đến từ sản phẩm của công ty (chất lượng dịch vụ, thuận tiện thanh toán/mua hàng, chương trình hoàn trả, vv)
=> công ty nên lên kế hoạch cải thiện chất lượng
- Nếu lí do từ ngoài sản phẩm công ty (đối thủ có các chương trình hấp dẫn hơn, công ty chưa có chương trình giữ chân khách hàng như loyalty program, vv)
=> Công ty cân nhắc và cải thiện kế hoạch kinh doanh và marketing của mình
*/


