-- EX 1
SELECT CTR.CONTINENT
, FLOOR(AVG (CT.POPULATION))
FROM COUNTRY AS CTR
INNER JOIN CITY AS CT
    ON CTR.CODE=CT.COUNTRYCODE
GROUP BY CTR.CONTINENT

-- EX 2
SELECT 
ROUND(
  SUM(CASE
      WHEN texts.signup_action = 'Confirmed' THEN 1
      ELSE 0
    END)*1.00 / COUNT(DISTINCT emails.user_id) -- count distinct lấy số lượng user thực tế 
  , 2)
  AS confirm_rate
FROM emails
  LEFT JOIN texts 
    ON emails.email_id = texts.email_id;
-- EX 3
SELECT demo.age_bucket
, ROUND(
    SUM(
      CASE
        WHEN act.activity_type = 'send' THEN time_spent
      ELSE 0
      END)*100.00/SUM(act.time_spent)
      , 2) AS send_perc
, ROUND(
    SUM(
      CASE
        WHEN act.activity_type = 'open' THEN time_spent
      ELSE 0
      END)*100.00/SUM(act.time_spent)
      ,2 ) AS open_perc
FROM activities AS act
LEFT JOIN age_breakdown AS demo
  ON act.user_id = demo.user_id
WHERE act.activity_type IN ('open','send')
GROUP BY  demo.age_bucket

/* S2 WINDOW FUNCTION FILTER by datalemur
SELECT 
  age.age_bucket, 
  ROUND(100.0 * 
    SUM(activities.time_spent) FILTER (WHERE activities.activity_type = 'send')/
      SUM(activities.time_spent),2) AS send_perc, 
  ROUND(100.0 * 
    SUM(activities.time_spent) FILTER (WHERE activities.activity_type = 'open')/
      SUM(activities.time_spent),2) AS open_perc
FROM activities
INNER JOIN age_breakdown AS age 
  ON activities.user_id = age.user_id 
WHERE activities.activity_type IN ('send', 'open') 
GROUP BY age.age_bucket;
*/

-- EX 4
WITH pivot AS
(
SELECT csc.customer_id AS customer_id
, SUM(
  CASE 
    WHEN pd.product_id IN (1,2) THEN 1
    ELSE 0
  END ) AS Analytics
, SUM(
  CASE 
    WHEN pd.product_id IN (3,4) THEN 1
    ELSE 0
  END ) AS Containers
, SUM(
  CASE 
    WHEN pd.product_id IN (5,6) THEN 1
    ELSE 0
  END ) AS Compute
FROM customer_contracts AS csc
LEFT JOIN products AS pd
  ON csc.product_id = pd.product_id
GROUP BY csc.customer_id
)

SELECT pivot.customer_id
FROM pivot
WHERE pivot.Analytics >0 AND pivot.Containers >0 AND pivot.Compute >0;

/* date lemur solution:
WITH supercloud AS (
SELECT 
  customers.customer_id, 
  COUNT(DISTINCT products.product_category) as unique_count
FROM customer_contracts AS customers
LEFT JOIN products 
  ON customers.product_id = products.product_id
GROUP BY customers.customer_id
)

SELECT customer_id
FROM supercloud
WHERE unique_count = (
  SELECT COUNT(DISTINCT product_category) 
  FROM products)
ORDER BY customer_id;
*/
-- EX 5
SELECT mng.employee_id
, mng.name
, COUNT(emp.employee_id) AS reports_count
, ROUND(AVG (emp.age)*1.00,0) AS average_age
FROM Employees AS mng
LEFT JOIN Employees AS emp
    ON emp.reports_to = mng.employee_id
GROUP BY mng.employee_id
HAVING COUNT(emp.employee_id)>0
ORDER BY mng.employee_id
-- EX 6
WITH Orders_2020 AS
(SELECT product_id
, SUM(unit) AS total_unit
FROM Orders
WHERE EXTRACT(month FROM order_date)=2 AND EXTRACT(year FROM order_date)=2020
GROUP BY product_id)

SELECT Products.product_name
, Orders_2020.total_unit AS unit
FROM Products
INNER JOIN Orders_2020
    ON Products.product_id = Orders_2020.product_id
WHERE Orders_2020.total_unit>=100
-- EX 7
SELECT pages.page_id
FROM pages
LEFT JOIN page_likes
  ON pages.page_id = page_likes.page_id
WHERE page_likes.page_id IS NULL;
