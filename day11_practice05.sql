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

-- EX 4

-- EX 5

-- EX 6

-- EX 7
