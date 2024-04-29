-- EX 1
SELECT 
SUM(CASE
  WHEN device_type = 'laptop' THEN 1
  ELSE 0
END) AS laptop_views
, SUM(CASE
  WHEN device_type = 'tablet' OR device_type = 'phone' THEN 1
  ELSE 0
END) AS mobile_views
FROM viewership;

-- EX 2
SELECT x
, y
, z
, CASE
        WHEN x+y>z AND y+z>x AND x+z>y THEN 'Yes' -- tổng 2 cạnh > cạnh còn lại
        ELSE 'No'
    END AS triangle
FROM Triangle

-- EX 3
SELECT 
ROUND(
  SUM(
    CASE
      WHEN call_category ='n/a' OR call_category IS NULL THEN 1.00
      ELSE 0.00
    END) 
  / COUNT(*)*100.00,1) 
    AS uncategorised_call_pct
FROM callers;

-- EX 4
SELECT name
FROM Customer
WHERE referee_id <> 2 OR referee_id IS NULL

-- EX 5
SELECT
CASE
    WHEN pclass = 1 THEN 'first_class'
    WHEN pclass = 2 THEN 'second_class'
    ELSE 'third_class'
END AS passenger_class
, SUM(
    CASE
        WHEN survived = 1 THEN 1
        ELSE 0
    END) AS number_of_survivors
 , SUM(
    CASE
        WHEN survived = 0 THEN 1
        ELSE 0
    END) AS number_of_non_survivors  
FROM titanic
GROUP BY pclass;
