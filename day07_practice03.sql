-- EX 1

SELECT Name
FROM STUDENTS
WHERE Marks>75
ORDER BY RIGHT(Name,3), ID ASC

--- EX2 (ussing PostgreSQL)
SELECT user_id
, CONCAT(UPPER(LEFT(name,1)), LOWER(RIGHT(name,LENGTH(name)-1)))
FROM Users
ORDER BY user_id

--- EX 3
SELECT manufacturer
, CONCAT('$',ROUND(SUM(total_sales)/1000000,0),' ','million') AS sales
FROM pharmacy_sales
GROUP BY manufacturer
ORDER BY (SUM(total_sales)/1000000) DESC, manufacturer
-- Order by theo số chưa làm tròn để xếp đúng thứ tự lớn

--- EX 4
SELECT EXTRACT(month FROM submit_date) AS mth
, product_id AS product
, ROUND(AVG(CAST(stars AS DECIMAL)),2) AS avg_stars
FROM reviews
GROUP BY EXTRACT(month FROM submit_date),product_id
ORDER BY mth, product_id;

--- EX 5
SELECT sender_id
, COUNT(content) AS message_count
FROM messages
WHERE EXTRACT(month FROM sent_date) = 8 AND EXTRACT(year FROM sent_date) = 2022
GROUP BY sender_id
ORDER BY message_count DESC
LIMIT 2;

--- EX 6
SELECT tweet_id
FROM Tweets
WHERE LENGTH(content)>15

--- EX 7
SELECT activity_date AS day
, COUNT(DISTINCT user_id) AS active_users
FROM Activity
WHERE activity_date BETWEEN '2019-06-28' AND '2019-07-28'
GROUP BY activity_date
HAVING active_users >0

--- EX 8
select COUNT(id) AS number_of_employees
from employees
where joining_date BETWEEN '2022-01-01' AND '2022-08-01';

--
select COUNT(id) AS number_of_employees
from employees
where EXTRACT(month from joining_date) BETWEEN 1 AND 7
  AND EXTRACT(year from joining_date)=2022;

--- EX 9
select POSITION('a' IN first_name)
from worker
where first_name = 'Amitah';

--- EX 10
select id
, CAST(SUBSTRING(title FROM LENGTH(winery)+2 FOR 4) AS INT) AS vintage_year
from winemag_p2
where country = 'Macedonia';
