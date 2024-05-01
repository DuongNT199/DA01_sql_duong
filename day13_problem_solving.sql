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

-- EX 7

-- EX 8

-- EX 9

-- EX 10

-- EX 11


-- EX 12
