--- Ex1
SELECT DISTINCT CITY
FROM STATION
WHERE ID%2=0

--- EX2
SELECT COUNT(CITY)-COUNT(DISTINCT CITY)
FROM STATION

--- EX3
SELECT CEIL(
  AVG(Salary)-AVG(REPLACE(Salary,'0',''))
  )
FROM EMPLOYEES 

--- EX4
SELECT 
  ROUND(
    CAST(
      SUM(item_count*order_occurrences)/SUM(order_occurrences) AS DECIMAL
          )
          ,1)
FROM items_per_order;

/* 
Với hàm ROUND, phải để type dữ liệu DECIMAL thì mới có giá trị thập phân để ROUND
Kiểu dữ liệu INT, khi chia INT/INT => trả về INT (không có giá trị sau dấu phẩy => không round được)
Để chuyển kiểu dữu liệu, dùng CAST hoặc CONVERT
*/

--- EX 5
SELECT candidate_id
FROM candidates
WHERE skill IN ('Python', 'Tableau', 'PostgreSQL') -- Lọc bảng candidate có 3 kn y/c
GROUP BY candidate_id
HAVING COUNT(candidate_id)=3 -- Trong bảng 3 kỹ năng, chỉ lấy candidate có xuất hiện 3 lần <=> có cả 3 KN
ORDER BY candidate_id;

-- EX 6
SELECT user_id
, MAX(DATE(post_date))-MIN(DATE(post_date)) AS days_between
FROM posts
WHERE Date_part('year',post_date) = 2021 -- chỉ lấy năm 2021
GROUP BY user_id
HAVING COUNT(user_id)>1

-- EX 7
SELECT card_name
, (MAX(issued_amount)-MIN(issued_amount)) AS difference
FROM monthly_cards_issued
GROUP BY card_name
ORDER BY difference DESC

-- EX 8
SELECT manufacturer
, COUNT(drug) AS drug_count
, ABS(SUM((total_sales-cogs))) AS total_losses
FROM pharmacy_sales
WHERE total_sales<cogs
GROUP BY manufacturer
ORDER BY total_losses DESC;

-- EX 9
SELECT *
FROM Cinema
WHERE id%2=1
    AND description <>'boring'
ORDER BY rating DESC

-- EX 10
SELECT teacher_id
, COUNT(DISTINCT subject_id) as cnt 
FROM Teacher
GROUP BY teacher_id

-- EX 11
SELECT user_id 
, COUNT(follower_id) AS followers_count
FROM Followers
GROUP BY user_id 
ORDER BY user_id ASC

-- EX 12
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student)>4
