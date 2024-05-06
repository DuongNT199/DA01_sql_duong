-- EX1: Y-on-Y Growth Rate
WITH this_year AS
(
  SELECT EXTRACT(year FROM transaction_date) AS year
  , product_id
  , SUM(spend) OVER
    (
      PARTITION BY product_id
      , EXTRACT(year FROM transaction_date) 
      ORDER BY product_id, EXTRACT(year FROM transaction_date)
    ) AS curr_year_spend
  FROM user_transactions
)

SELECT year AS yr
, product_id
, curr_year_spend
, LAG(curr_year_spend) OVER (PARTITION BY product_id ORDER BY  product_id, year) AS prev_year_spend
, ROUND
  (
    (curr_year_spend-LAG(curr_year_spend) OVER (PARTITION BY product_id ORDER BY  product_id, year))*100.0/
      LAG(curr_year_spend) OVER (PARTITION BY product_id ORDER BY  product_id, year)
    ,2
  ) AS yoy_rate
FROM this_year;

-- EX2: Card Launch Success
WITH sum_month AS
(
SELECT card_name
, issue_month
, issue_year
, SUM(issued_amount) OVER(PARTITION BY card_name, issue_year, issue_month) AS all_issued_amount
FROM monthly_cards_issued
)

SELECT DISTINCT card_name
, FIRST_VALUE(all_issued_amount) OVER(PARTITION BY card_name ORDER BY issue_year, issue_month) AS issued_amount
FROM sum_month
ORDER BY issued_amount DESC;

/* SOLVE with MIN by DATA LEMUR
WITH card_launch AS (
  SELECT 
    card_name,
    issued_amount,
    MAKE_DATE(issue_year, issue_month, 1) AS issue_date,
    MIN(MAKE_DATE(issue_year, issue_month, 1)) OVER (
      PARTITION BY card_name) AS launch_date
  FROM monthly_cards_issued
)

SELECT 
  card_name, 
  issued_amount
FROM card_launch
WHERE issue_date = launch_date
ORDER BY issued_amount DESC;
*/

-- EX3: User's Third Transaction
WITH twt_third_transaction AS
(
  SELECT user_id
  , spend
  , transaction_date
  , ROW_NUMBER() OVER (
      PARTITION BY user_id ORDER BY transaction_date ASC) AS row_order
  FROM transactions
)

SELECT user_id
, spend
, transaction_date
FROM twt_third_transaction
WHERE row_order = 3;

-- EX4: Histogram of Users and Purchases
WITH count_purchase AS
(
SELECT user_id
, transaction_date
, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY transaction_date DESC) AS last_date_count
, COUNT(*) OVER (PARTITION BY user_id, transaction_date) AS purchase_count
FROM user_transactions
)

SELECT transaction_date
, user_id
, purchase_count
FROM count_purchase
WHERE last_date_count =1
ORDER BY transaction_date;

-- EX5: Tweets' Rolling Averages 
-- LAG(expression [,offset [,default_value]])
WITH accumulated_data AS
(
SELECT user_id
, tweet_date
, tweet_count AS day3
, LAG(tweet_count,1,0) OVER(PARTITION BY user_id ORDER BY tweet_date) AS day2
, LAG(tweet_count,2,0) OVER(PARTITION BY user_id ORDER BY tweet_date) AS day1
, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY tweet_date) AS day_no
FROM tweets
)

SELECT user_id
, tweet_date
, CASE
    WHEN day_no <3 THEN ROUND((day1+day2+day3)*1.00/day_no,2)
    ELSE ROUND((day1+day2+day3)/3.00,2) 
  END AS rolling_avg_3d
FROM accumulated_data;

-- EX6: Repeated Payments
WITH full_info AS
(
  SELECT merchant_id
  , credit_card_id
  , amount
  , transaction_timestamp AS next_trans
  , LAG(transaction_timestamp) OVER(PARTITION BY merchant_id, credit_card_id, amount ORDER BY merchant_id, credit_card_id, transaction_timestamp) AS first_trans
  , COUNT(*) OVER(PARTITION BY merchant_id, credit_card_id, amount ORDER BY merchant_id, credit_card_id, amount)
  FROM transactions
)
, repeat_payment AS
(
  SELECT merchant_id
  , credit_card_id
  , amount
  , EXTRACT(hour FROM (next_trans-first_trans))*60+ EXTRACT(minute FROM (next_trans-first_trans))AS time_btw_trans
  FROM full_info
)

SELECT COUNT(*) AS payment_count
FROM repeat_payment
WHERE time_btw_trans<=10;

-- EX7: Highest-Grossing Items 
SELECT category
, product
, total_spend
FROM 
(
SELECT category
, product
, SUM(spend) AS total_spend
, RANK() OVER (PARTITION BY category ORDER BY SUM(spend) DESC) AS spend_rank
FROM product_spend 
WHERE EXTRACT(year FROM transaction_date) =2022
GROUP BY category,product
) AS ranked_data
WHERE spend_rank IN (1,2)

-- EX8: Top 5 Artists 
WITH artist_top10 AS
(
SELECT ART.artist_name
, COUNT(*) AS chart_frequency
, DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS artist_rank
FROM global_song_rank AS GR
JOIN songs AS SO
  ON GR.song_id = SO.song_id
JOIN artists AS ART
  ON SO.artist_id = ART.artist_id
WHERE GR.rank <=10
GROUP BY ART.artist_name
)

SELECT artist_name
, artist_rank
FROM artist_top10
WHERE artist_rank <6
ORDER BY artist_rank ASC
