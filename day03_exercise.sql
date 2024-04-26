-- Bài tập 1
SELECT NAME
FROM CITY
WHERE COUNTRYCODE='USA'
AND POPULATION > 120000;

-- Bài tập 2
SELECT *
FROM CITY
WHERE COUNTRYCODE='JPN'

-- Bài tập 3
SELECT CITY
, STATE
FROM STATION

-- Bài tập 4
SELECT DISTINCT CITY
FROM STATION
WHERE CITY LIKE 'A%' 
  OR CITY LIKE 'E%' 
  OR CITY LIKE 'I%' 
  OR CITY LIKE 'O%' 
  OR CITY LIKE 'U%';

-- Bài tập 5
SELECT DISTINCT CITY
FROM STATION
WHERE CITY LIKE '%A' 
  OR CITY LIKE '%E' 
  OR CITY LIKE '%I' 
  OR CITY LIKE '%O' 
  OR CITY LIKE '%U';

-- Bài tập 6
SELECT DISTINCT CITY
FROM STATION
WHERE NOT (CITY LIKE 'A%' 
  OR CITY LIKE 'E%' 
  OR CITY LIKE 'I%' 
  OR CITY LIKE 'O%' 
  OR CITY LIKE 'U%');

-- Bài tập 7
SELECT name
FROM Employee
ORDER BY name

-- Bài tập 8
SELECT name
FROM Employee
WHERE salary > 2000 AND months <10
ORDER BY employee_id

-- Bài tập 9
SELECT product_id
FROM Products
WHERE low_fats ='Y' AND recyclable = 'Y'

-- Bài tập 10
SELECT name
FROM Customer
WHERE referee_id <> 2 OR referee_id IS NULL

-- Bài tập 11
SELECT name
, population
, area
FROM World
WHERE area >=3000000 OR population >=25000000;

-- Bài tập 12
SELECT DISTINCT author_id AS id
FROM Views
WHERE author_id=viewer_id
ORDER BY author_id

-- Bài tập 13
SELECT part
, assembly_step
FROM parts_assembly
WHERE finish_date IS NULL 

-- Bài tập 14
select * 
from lyft_drivers
where yearly_salary <=30000 OR yearly_salary>=70000;

-- Bài tập 15
select * 
from uber_advertising
where uber_advertising.year = 2019 
  AND uber_advertising.money_spent >= 100000;
