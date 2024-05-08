--EX1: https://leetcode.com/problems/immediate-food-delivery-ii/description/?envType=study-plan-v2&envId=top-sql-50
WITH delivery_category AS
(
    SELECT customer_id
    , order_date
    , customer_pref_delivery_date 
    , CASE
        WHEN customer_pref_delivery_date - order_date =0 THEN 'immediate'
        ELSE 'scheduled'
     END AS delivery_request
    , RANK() OVER (PARTITION BY customer_id  ORDER BY order_date ASC) AS order_no
    FROM Delivery
)
, delivery_pivot AS
(
    SELECT customer_id
    , CASE
        WHEN delivery_request = 'immediate' THEN 1
        ELSE 0
    END AS immediate_orders
    FROM delivery_category
    WHERE order_no =1
)

SELECT ROUND(SUM(immediate_orders)*100.0/count(*),2) AS immediate_percentage 
FROM delivery_pivot;

-- ex2: leetcode-game-play-analysis

WITH login_data AS
(
    SELECT player_id 
    , event_date 
    , LAG(event_date) OVER (PARTITION BY player_id ORDER BY event_date ASC) AS prev_day
    , event_date - LAG(event_date) OVER (PARTITION BY player_id ORDER BY event_date ASC) AS day_difference
    , ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY event_date ASC) AS login_order
    FROM Activity
)
, consecutive_log AS
(
    SELECT player_id
    FROM login_data
    WHERE login_order <3
        AND day_difference = 1
)

SELECT ROUND(
    (SELECT COUNT(DISTINCT player_id) FROM consecutive_log)*1.0/
    (COUNT(DISTINCT player_id))
    ,2
) AS fraction 
FROM Activity

/* using interval
with fst as ( select player_id, min(event_date) event_date from activity group by player_id )
select round((count (1) * 1.0) / (select count (distinct player_id) from activity), 2) fraction
from fst a1 join activity a2 using(player_id)
where a2.event_date = a1.event_date + interval '1' day
*/
-- ex3: leetcode-exchange-seats.
WITH swap_table AS
(
    SELECT id
    , student AS original
    , LEAD(student) OVER (ORDER BY id) AS swap_up
    , LAG(student) OVER (ORDER BY id) AS swap_down
    FROM Seat
)

SELECT id
, CASE
    WHEN id % 2 = 0 THEN swap_down
    WHEN id = (SELECT id FROM Seat ORDER BY id DESC LIMIT 1) AND id%2=1 THEN original
    ELSE swap_up
END AS student 
FROM swap_table


-- ex4: leetcode-restaurant-growth.
WITH counting_period AS
(
    SELECT DISTINCT visited_on
    FROM Customer
    ORDER BY visited_on ASC 
    OFFSET 6

)

SELECT CP.visited_on
, SUM(CS.amount) AS amount
, ROUND(SUM(CS.amount)/7.0,2) AS average_amount
FROM counting_period AS CP
JOIN Customer AS CS
    ON CS.visited_on BETWEEN CP.visited_on - 6 AND CP.visited_on
GROUP BY CP.visited_on
ORDER BY CP.visited_on ASC

-- ex5: leetcode-investments-in-2016.
-- Write your PostgreSQL query statement below
WITH match_table AS
(
SELECT pid 
, COUNT(tiv_2015) OVER (PARTITION BY tiv_2015 ) AS matching_2015
, lat || ',' || lon AS geo
FROM Insurance
)
, no_dup_geo AS
(
    SELECT COUNT(geo) OVER (PARTITION BY geo) AS matching_geo
    , pid 
    FROM match_table
)
, final_to_sum AS
(  
    SELECT MT.pid
    FROM match_table AS MT
    INNER JOIN no_dup_geo AS ND
        ON MT.pid=ND.pid
        AND ND.matching_geo = 1
    WHERE MT.matching_2015>1
)

SELECT ROUND(SUM(CAST (tiv_2016 AS DECIMAL)),2) AS tiv_2016 
FROM Insurance 
WHERE pid IN (SELECT pid FROM final_to_sum)

/* runtime utilized solution:
https://leetcode.com/problems/investments-in-2016/solutions/5040471/explained-perfomand-postgresql-solution-beats-94
*/
-- ex6: leetcode-department-top-three-salaries.

-- ex7: leetcode-last-person-to-fit-in-the-bus.
SELECT person_name
FROM 
(
    SELECT person_id 
    , person_name
    , SUM(weight) OVER (ORDER BY turn ASC) AS rolling_weight
    FROM Queue
    ORDER BY turn
) AS weight_sum
WHERE rolling_weight <=1000
ORDER BY rolling_weight DESC
LIMIT 1
  
-- ex8: leetcode-product-price-at-a-given-date.
-- Write your PostgreSQL query statement below
WITH last_value AS
(
    SELECT DISTINCT product_id 
    , new_price 
    , FIRST_VALUE(new_price) OVER (PARTITION BY product_id ORDER BY change_date DESC) AS lastest_price
    FROM Products
    WHERE change_date <='2019-08-16'
)

SELECT DISTINCT PR.product_id
, COALESCE(LV.lastest_price,10) AS price
FROM Products AS PR
LEFT JOIN last_value AS LV
    ON PR.product_id=LV.product_id
