-- DataBase:  GreenCycles
/* Q1:
Task: Tạo danh sách tất cả chi phí thay thế (replacement costs) khác nhau của các film.
Question: Chi phí thay thế thấp nhất là bao nhiêu?
*/

SELECT DISTINCT replacement_cost
FROM public.film
ORDER BY replacement_cost
-- Answer: Chi phí thay thế thấp nhất là 9.99

/* Q2:
Viết một truy vấn cung cấp cái nhìn tổng quan về số lượng phim có 
chi phí thay thế trong các phạm vi chi phí sau
1.	low: 9.99 - 19.99
2.	medium: 20.00 - 24.99
3.	high: 25.00 - 29.99
Question: Có bao nhiêu phim có chi phí thay thế thuộc nhóm “low”?
*/

SELECT 
CASE
	WHEN replacement_cost BETWEEN 9.99 AND 19.99 THEN 'low'
	WHEN replacement_cost BETWEEN 20.99 AND 24.99 THEN 'medium'
	ELSE 'high'
END AS replacement_tag
, COUNT(*) AS amount_of_film
FROM public.film
GROUP BY replacement_tag

-- Answer: 514 phim thuộc nhóm chi phí replacement low

/* Q3:
Task: Tạo danh sách các film_title  bao gồm tiêu đề (title), độ dài (length) 
và tên danh mục (category_name) được sắp xếp theo độ dài giảm dần. 
Lọc kết quả để chỉ các phim trong danh mục 'Drama' hoặc 'Sports'.
Question: Phim dài nhất thuộc thể loại nào và dài bao nhiêu?
*/

SELECT FM.title
, FM.length
, CG.name
FROM public.film AS FM
LEFT JOIN public.film_category AS FC
	ON FM.film_id = FC.film_id
LEFT JOIN public.category AS CG
	ON FC.category_id = CG.category_id
WHERE CG.name IN ('Drama','Sports')
ORDER BY FM.length DESC
-- Answer: Phim dài nhất thuộc thể loại Sports và dài 184

/*Q4:
Task: Đưa ra cái nhìn tổng quan về số lượng phim (tilte) trong mỗi danh mục (category).
Question:Thể loại danh mục nào là phổ biến nhất trong số các bộ phim?
*/
SELECT CG.name
, COUNT(FC.film_id) AS film_amt
FROM public.film_category AS FC
LEFT JOIN public.category AS CG
	ON FC.category_id = CG.category_id
GROUP BY CG.name
ORDER BY film_amt DESC
-- Sports là phổ biến nhất, có 74 bộ phim

/*Q5:
Task:Đưa ra cái nhìn tổng quan về họ và tên của các diễn viên
cũng như số lượng phim họ tham gia.
Question: Diễn viên nào đóng nhiều phim nhất?
*/

SELECT FA.actor_id
, ACT.first_name
, ACT.last_name
, COUNT(FA.actor_id) AS acted_film
FROM public.film_actor AS FA
LEFT JOIN actor AS ACT
	ON FA.actor_id = ACT.actor_id
GROUP BY FA.actor_id, ACT.first_name,ACT.last_name
ORDER BY acted_film DESC

-- Answer: Gina Degeneres 42 phim

/* Q6:
Task: Tìm các địa chỉ không liên quan đến bất kỳ khách hàng nào.
Question: Có bao nhiêu địa chỉ như vậy?
*/
SELECT AD.address
FROM public.address AS AD
LEFT JOIN public.customer AS CS
	ON AD.address_id=CS.address_id
WHERE CS.customer_id IS NULL

-- ANSWER: 4 địa chỉ

/* Q7:
Task: Danh sách các thành phố và doanh thu tương ừng trên từng thành phố 
Question:Thành phố nào đạt doanh thu cao nhất?
*/

SELECT CT.city
, SUM(PM.amount) AS revenue
FROM payment AS PM
LEFT JOIN customer AS CS
	ON PM.customer_id = CS.customer_id
LEFT JOIN address AS AD
	ON CS.address_id = AD.address_id
LEFT JOIN city AS CT
	ON AD.city_id = CT.city_id
GROUP BY CT.city
ORDER BY revenue DESC

-- Thành phố Cape Coral có doanh thu cao nhất 221.55

/*Q8:
Task: Tạo danh sách trả ra 2 cột dữ liệu: 
-	cột 1: thông tin thành phố và đất nước ( format: “city, country")
-	cột 2: doanh thu tương ứng với cột 1
Question: thành phố của đất nước nào đat doanh thu cao nhất
*/
SELECT CONCAT(CT.city, ', ', CY.country) AS place
, SUM(PM.amount) AS revenue
FROM payment AS PM
LEFT JOIN customer AS CS
	ON PM.customer_id = CS.customer_id
LEFT JOIN address AS AD
	ON CS.address_id = AD.address_id
LEFT JOIN city AS CT
	ON AD.city_id = CT.city_id
LEFT JOIN country AS CY
	ON CT.country_id = CY.country_id
GROUP BY CY.country, CT.city
ORDER BY revenue DESC

/*
Doanh thu cao nhất: "Cape Coral, United States"  221.55
Doanh thu thấp nhất: "Tallahassee, United States" 50.85
*/
