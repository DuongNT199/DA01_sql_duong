/* B1: Chuyển data type:
ordernumber -> int
quantityordered -> int
priceeach -> decimal
orderlinenumber -> int
sales -> decimal
orderdate -> date
msrp -> int
*/

-- Postgre không cast tự động type varchar -> int được, phải chỉ dẫn bằng USING;
-- Trim để loại bỏ khoảng trắng trong tên cột
ALTER TABLE sales_dataset_rfm_prj
--	ALTER COLUMN ordernumber TYPE INT USING (CAST(TRIM(ordernumber) AS INT))
	ALTER COLUMN quantityordered TYPE INT USING TRIM(quantityordered) :: INT
,	ALTER COLUMN priceeach TYPE DECIMAL USING TRIM(priceeach) :: DECIMAL
,	ALTER COLUMN orderlinenumber TYPE INT USING TRIM(orderlinenumber):: INT
,	ALTER COLUMN sales TYPE DECIMAL USING TRIM(sales) :: DECIMAL
,	ALTER COLUMN orderdate TYPE DATE USING TO_DATE(orderdate,'MM-DD-YYYY') :: DATE 
,	ALTER COLUMN msrp TYPE INT USING msrp :: INT;

-- Check KQ
SELECT *
FROM sales_dataset_rfm_prj;

/* B2: Check NULL/BLANK
ORDERNUMBER, QUANTITYORDERED, PRICEEACH, ORDERLINENUMBER, SALES, ORDERDATE.
*/

SELECT ordernumber
, quantityordered
, priceeach
, orderlinenumber
, sales
, orderdate
FROM sales_dataset_rfm_prj
WHERE ordernumber IS NULL
	OR quantityordered IS NULL
	OR priceeach IS NULL
	OR orderlinenumber IS NULL
	OR sales IS NULL
	OR orderdate IS NULL;
--> no null

/* B3
Thêm cột CONTACTLASTNAME, CONTACTFIRSTNAME được tách ra từ CONTACTFULLNAME . 
Chuẩn hóa CONTACTLASTNAME, CONTACTFIRSTNAME theo định dạng chữ cái đầu tiên viết hoa, chữ cái tiếp theo viết thường.
*/

-- Tạo 2 cột 
ALTER TABLE sales_dataset_rfm_prj
ADD COLUMN contactlastname VARCHAR (50)
, ADD COLUMN contactfirstname  VARCHAR(50);

-- Update giá trị tên họ, initcap về dạng proper
UPDATE sales_dataset_rfm_prj
SET contactlastname = nm.last_name
, contactfirstname = nm.first_name
FROM
(
	SELECT INITCAP(LEFT(contactfullname, POSITION('-' IN contactfullname)-1)) AS last_name
	, INITCAP(RIGHT(contactfullname, LENGTH(contactfullname) - POSITION('-' IN contactfullname))) AS first_name
	FROM sales_dataset_rfm_prj
	) AS nm;

-- Check kết quả
SELECT contactlastname
, contactfirstname
FROM sales_dataset_rfm_prj;


/*B4:
Thêm cột QTR_ID, MONTH_ID, YEAR_ID lần lượt là Qúy, tháng, năm được lấy ra từ ORDERDATE 
*/
 -- Tạo cột
ALTER TABLE sales_dataset_rfm_prj
ADD COLUMN qtr_id INT
, ADD COLUMN month_id  INT
, ADD COLUMN year_id  INT

-- Update thông tin
UPDATE sales_dataset_rfm_prj
SET qtr_id = qtr
, month_id = mth
, year_id = yr
FROM
(
	SELECT EXTRACT(quarter FROM orderdate) AS qtr
	, EXTRACT(month FROM orderdate) AS mth
	, EXTRACT(year FROM orderdate) AS yr
	FROM sales_dataset_rfm_prj
) AS date_table

-- Check KQ
SELECT orderdate
, qtr_id
, month_id
, year_id
FROM sales_dataset_rfm_prj

/*B5:
Hãy tìm outlier (nếu có) cho cột QUANTITYORDERED 
Chọn cách xử lý cho bản ghi đó (2 cách) ( Không chạy câu lệnh trước khi bài được review)
*/
-- Lọc outlier
WITH box_data AS
(
	SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantityordered) AS Q1
	, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantityordered) AS Q3
	, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantityordered) - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantityordered) AS IQR
	FROM sales_dataset_rfm_prj
)
, min_max AS
(
	SELECT (Q1-1.5*IQR) AS min_val
	, (Q3+1.5*IQR) AS max_val
	FROM box_data
)
, out_lier AS
(
	SELECT ordernumber
	FROM sales_dataset_rfm_prj
	WHERE quantityordered > (SELECT max_val FROM min_max) -- 67
		OR quantityordered < (SELECT min_val FROM min_max) -- 3
	 
)

SELECT *
FROM sales_dataset_rfm_prj
WHERE quantityordered > (SELECT max_val FROM min_max) -- 67
	OR quantityordered < (SELECT min_val FROM min_max) -- 3
	
-- Xử lý outlier
-- C1: DELETE
WITH box_data AS
(
	SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantityordered) AS Q1
	, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantityordered) AS Q3
	, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantityordered) - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantityordered) AS IQR
	FROM sales_dataset_rfm_prj
)
, min_max AS
(
	SELECT (Q1-1.5*IQR) AS min_val
	, (Q3+1.5*IQR) AS max_val
	FROM box_data
)
, out_lier AS
(
	SELECT ordernumber
	FROM sales_dataset_rfm_prj
	WHERE quantityordered > (SELECT max_val FROM min_max) -- 67
		OR quantityordered < (SELECT min_val FROM min_max) -- 3
	 
)

DELETE FROM  sales_dataset_rfm_prj
WHERE ordernumber IN ( SELECT * FROM out_lier)

-- C2: Update bằng giá trị trung bình
WITH box_data AS
(
	SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantityordered) AS Q1
	, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantityordered) AS Q3
	, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantityordered) - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantityordered) AS IQR
	FROM sales_dataset_rfm_prj
)
, min_max AS
(
	SELECT (Q1-1.5*IQR) AS min_val
	, (Q3+1.5*IQR) AS max_val
	FROM box_data
)
, out_lier AS
(
	SELECT ordernumber
	FROM sales_dataset_rfm_prj
	WHERE quantityordered > (SELECT max_val FROM min_max) -- 67
		OR quantityordered < (SELECT min_val FROM min_max) -- 3
	 
)

UPDATE sales_dataset_rfm_prj
SET quantityordered = (SELECT AVG(quantityordered) FROM sales_dataset_rfm_prj) 
WHERE ordernumber IN ( SELECT * FROM out_lier)

/*B6:
Sau khi làm sạch dữ liệu, hãy lưu vào bảng mới  tên là SALES_DATASET_RFM_PRJ_CLEAN
*/
CREATE TABLE SALES_DATASET_RFM_PRJ_CLEAN AS
(SELECT * FROM sales_dataset_rfm_prj)
