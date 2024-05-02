-- EX 1
WITH dup_company AS
(
  SELECT company_id
  , title
  , description
  , COUNT(title) AS dup
  FROM job_listings
  GROUP BY company_id, title, description
  HAVING COUNT(title)>1
  ORDER BY company_id
)

SELECT COUNT(*) AS duplicate_companies
FROM dup_company

-- EX 2
-- Tạo 2 bảng CTEs chứa 2 top products, cho từng category
-- UNION 2 bảng CTEs 
  WITH top_app AS 
(
  SELECT category
  , product
  , SUM(spend) AS total_spend
  FROM product_spend
  WHERE EXTRACT(year FROM transaction_date)=2022
    AND category = 'appliance'
  GROUP BY category, product
  ORDER BY total_spend DESC
  LIMIT 2
)
, top_elec AS 
(
  SELECT category
  , product
  , SUM(spend) AS total_spend
  FROM product_spend
  WHERE EXTRACT(year FROM transaction_date)=2022
    AND category = 'electronics'
  GROUP BY category, product
  ORDER BY total_spend DESC
  LIMIT 2
)

SELECT category
, product
, total_spend
FROM top_app

UNION ALL

SELECT category
, product
, total_spend
FROM top_elec

/* Solution with window function, data lemur:
WITH ranked_spending_cte AS (
  SELECT 
    category, 
    product, 
    SUM(spend) AS total_spend,
    RANK() OVER (
      PARTITION BY category 
      ORDER BY SUM(spend) DESC) AS ranking 
  FROM product_spend
  WHERE EXTRACT(YEAR FROM transaction_date) = 2022
  GROUP BY category, product
)

SELECT 
  category, 
  product, 
  total_spend 
FROM ranked_spending_cte 
WHERE ranking <= 2 
ORDER BY category, ranking;
*/


-- EX 3
WITH count_call AS
(
  SELECT policy_holder_id
  , COUNT(policy_holder_id) AS count_p
  FROM callers
  GROUP BY policy_holder_id
  ORDER BY policy_holder_id
)

SELECT COUNT(count_p) AS policy_holder_count
FROM count_call
WHERE count_p>2


-- EX 4
SELECT pages.page_id
FROM pages
LEFT JOIN page_likes
  ON pages.page_id = page_likes.page_id
WHERE page_likes.page_id IS NULL
ORDER BY pages.page_id;

-- EX 5

WITH july_active AS
(
SELECT EXTRACT(month FROM event_date) AS month
, user_id
FROM user_actions
WHERE EXTRACT(month FROM event_date) = 7 
  AND EXTRACT(YEAR FROM curr_month.event_date) = 2022
GROUP BY month, user_id
HAVING COUNT(event_type)>0
)
, june_active AS
(
SELECT EXTRACT(month FROM event_date) AS month
, user_id
FROM user_actions
WHERE EXTRACT(month FROM event_date) =6 
  AND EXTRACT(YEAR FROM curr_month.event_date) = 2022
GROUP BY month, user_id
HAVING COUNT(event_type)>0
)

SELECT july_active.month
, COUNT(july_active.user_id) AS monthly_active_users
FROM july_active
INNER JOIN june_active
  ON july_active.user_id=june_active.user_id
WHERE june_active.user_id IS NOT NULL
GROUP BY july_active.month


/*data lemur:
SELECT 
  EXTRACT(MONTH FROM curr_month.event_date) AS mth, 
  COUNT(DISTINCT curr_month.user_id) AS monthly_active_users 
FROM user_actions AS curr_month
WHERE EXISTS (
  SELECT last_month.user_id 
  FROM user_actions AS last_month
  WHERE last_month.user_id = curr_month.user_id
    AND EXTRACT(MONTH FROM last_month.event_date) =
    EXTRACT(MONTH FROM curr_month.event_date - interval '1 month')
)
  AND EXTRACT(MONTH FROM curr_month.event_date) = 7
  AND EXTRACT(YEAR FROM curr_month.event_date) = 2022
GROUP BY EXTRACT(MONTH FROM curr_month.event_date);
*/
-- EX 6
SELECT TO_CHAR (trans_date, 'YYYY-MM') AS month
, country
, COUNT(id) AS trans_count
, SUM
    (CASE
        WHEN state='approved' THEN 1
        ELSE 0
    END) AS approved_count
, SUM
    (CASE
        WHEN state='approved' THEN amount
        ELSE 0
    END) AS approved_total_amount
, SUM(amount) AS trans_total_amount
FROM Transactions
GROUP BY month, country

-- Không nên sử dụng JOIN hay CTEs trong bài 6 do test case có TH country ID null hoặc TH không có transaction nào approved => sinh null bảng join, khó xử lí join

-- EX 7
WITH FY AS
( 
    SELECT product_id
    , MIN(year) AS first_year
    FROM Sales
    GROUP BY product_id
)
  
SELECT FY.product_id
, FY.first_year
, SL.quantity
, SL.price
FROM Sales AS SL
INNER JOIN FY 
    ON FY.product_id = SL.product_id
    AND FY.first_year = SL.year

-- Cần trả về toàn bộ giá và số lượng của mã product trong first_year
-- Tách bảng lấy key product và year, inner join để lấy toàn bộ record

-- EX 8
SELECT customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) >= (SELECT COUNT(product_key) FROM Product)

-- EX 9
WITH have_mng AS
(
    SELECT * 
    FROM Employees
    WHERE manager_id IS NOT NULL
        AND salary<30000
)

SELECT emp.employee_id
FROM have_mng AS emp
LEFT JOIN Employees AS mng
    ON emp.manager_id = mng.employee_id
WHERE mng.employee_id IS NULL
ORDER BY emp.employee_id

-- Simpler
SELECT employee_id
FROM Employees 
WHERE salary <30000
    AND manager_id NOT IN (SELECT employee_id FROM Employees)
ORDER BY employee_id;

-- EX 10
SELECT COUNT(DISTINCT company_id) AS duplicate_companies
FROM job_listings
WHERE company_id IN
  (
    SELECT company_id
    FROM job_listings
    GROUP BY company_id, title, description
    HAVING COUNT(title)>1
  );

-- EX 11
-- Tạo bảng với user và số lần đánh giá; phim và trung bình rating trong T2/2020
WITH user_rate_count AS 
(
    SELECT user_id
    , COUNT(user_id) AS frequency
    FROM MovieRating
    GROUP BY user_id
)
, movie_rate20 AS 
(
    SELECT movie_id
    , AVG(rating) AS avg_rating
    FROM MovieRating 
    WHERE EXTRACT (year FROM created_at) =2020
        AND EXTRACT (month FROM created_at) =2
    GROUP BY movie_id
)
-- Lấy name/title từ bảng tương ứng mà id bằng MAX số lần đánh giá/trung bình rating
-- Order theo tên ASC -> limit 1 -> lấy 1 name/title theo lexicographically 
-- Đóng ngoặc câu lệnh do dùng order by và limit để dùng được union all
(
SELECT name AS results
FROM Users
WHERE user_id IN 
    (
        SELECT user_id
        FROM user_rate_count 
        WHERE user_rate_count.frequency = (SELECT MAX(frequency) FROM user_rate_count)
    )
ORDER BY name ASC
LIMIT 1 
)

UNION ALL

(
SELECT title
FROM Movies
WHERE movie_id IN 
    (
        SELECT movie_id
        FROM movie_rate20
        WHERE movie_rate20.avg_rating = (SELECT MAX(avg_rating) FROM movie_rate20)
    )
ORDER BY title ASC
LIMIT 1 
)

-- EX 12
WITH rest_friend AS
(
    SELECT requester_id AS id
    , COUNT(requester_id) AS fr_count
    FROM RequestAccepted
    GROUP BY requester_id
)
, accept_friend AS
(
    SELECT accepter_id AS id
    , COUNT(accepter_id) AS fr_count
    FROM RequestAccepted
    GROUP BY accepter_id
)
, all_friend AS
(
    SELECT *
    FROM rest_friend
    UNION ALL 
    SELECT *
    FROM accept_friend
)
, total_friend_sum AS
(
    SELECT id
    , SUM(fr_count) AS num
    FROM all_friend
    GROUP BY id
)

SELECT *
FROM total_friend_sum
WHERE num = (SELECT MAX(num) FROM total_friend_sum)

-- PROBLEM APP CLICKTHROUGH RATE IN VIDEO
WITH ctr_table AS
(
  SELECT app_id
  , SUM(
    CASE
      WHEN event_type = 'impression' THEN 1
      ELSE 0
    END)*1.00 AS count_impression
  , SUM(
    CASE
      WHEN event_type = 'click' THEN 1
      ELSE 0
    END)*1.00 AS count_click
  FROM events
  WHERE EXTRACT(year FROM timestamp) = 2022
  GROUP BY app_id
)

SELECT app_id
, ROUND(100*(count_click/count_impression),2) AS ctr
FROM ctr_table

-- SOLUTION BY LESSON (using CTEs)

-- CTEs lượng click, impression
WITH no_clicks AS
(
  SELECT app_id
  , COUNT(*) AS no_click
  FROM events
  WHERE EXTRACT(year FROM timestamp) = 2022
    AND event_type = 'click'
  GROUP BY app_id
)
, no_impressions AS
(
  SELECT app_id
  , COUNT(*) AS no_impression
  FROM events
  WHERE EXTRACT(year FROM timestamp) = 2022
    AND event_type = 'impression'
  GROUP BY app_id
)

SELECT NI.app_id
, ROUND(100.0*(NC.no_click/NI.no_impression),2) AS ctr
FROM no_impressions AS NI
LEFT JOIN no_clicks AS NC
  ON NI.app_id = NC.app_id


