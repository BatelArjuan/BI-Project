USE Sales_by_Store;

-- Query 1 - Revenue QoQ
WITH sales_overtime AS (
SELECT
    Transaction_Date AS Tran_Date,
    Quantity * Unit_Price AS Revenue,
    YEAR(Transaction_Date) AS Tran_Year,
    MONTH(Transaction_Date) AS Tran_Month,
    CASE
		WHEN MONTH(Transaction_Date) <=3 THEN 'Q1'
        WHEN MONTH(Transaction_Date) <=6 THEN 'Q2'
        WHEN MONTH(Transaction_Date) <=9 THEN 'Q3'
    ELSE 'Q4' END QTR
    FROM Fact
)
, revenue AS (
    SELECT
		Tran_Year,
        QTR,
        FORMAT(SUM(Revenue),2) AS Revenue
	FROM sales_overtime
    GROUP BY Tran_Year, QTR
)
SELECT
	*,
    FORMAT(LAG(Revenue) OVER(ORDER BY Tran_Year, QTR),2) AS Last_QTR,
    format(((Revenue -   LAG(Revenue) OVER(ORDER BY Tran_Year, QTR)) / 
								LAG(Revenue) OVER(ORDER BY Tran_Year, QTR))*100,2) AS change_percent
FROM revenue
ORDER BY Tran_Year, QTR;

###############################################################

-- Query 2 - Revenue QoQ by Store
WITH sales_overtime AS (
SELECT
	Store_City AS Store_City,
    Transaction_Date AS Tran_Date,
    Quantity * Unit_Price AS Revenue,
    YEAR(Transaction_Date) AS Tran_Year,
    MONTH(Transaction_Date) AS Tran_Month,
    CASE
		WHEN MONTH(Transaction_Date) <=3 THEN 'Q1'
        WHEN MONTH(Transaction_Date) <=6 THEN 'Q2'
        WHEN MONTH(Transaction_Date) <=9 THEN 'Q3'
    ELSE 'Q4' END QTR
    FROM Fact
)
, revenue_store AS (
    SELECT
		Tran_Year,
        QTR,
        Store_City,
        FORMAT(SUM(Revenue),2) AS Revenue
	FROM sales_overtime
    GROUP BY Tran_Year, QTR, store_city
)
SELECT
	*,
    FORMAT(LAG(Revenue) OVER(PARTITION BY store_city ORDER BY Tran_Year, QTR),2) AS Last_QTR,
    FORMAT(((Revenue -   LAG(Revenue) OVER(PARTITION BY store_city ORDER BY Tran_Year, QTR)) / LAG(Revenue) OVER(PARTITION BY store_city ORDER BY Tran_Year, QTR))*100,2) AS change_percent
FROM revenue_store
ORDER BY store_city, Tran_Year, QTR;
###############################################################

-- Query 3 - Revenue QoQ by Product Category
WITH sales_product AS (
SELECT
	p.Product_Category AS Product_Category,
    Transaction_Date AS Tran_Date,
    Quantity * Unit_Price AS Revenue,
    YEAR(Transaction_Date) AS Tran_Year,
    MONTH(Transaction_Date) AS Tran_Month,
    CASE
		WHEN MONTH(Transaction_Date) <=3 THEN 'Q1'
        WHEN MONTH(Transaction_Date) <=6 THEN 'Q2'
        WHEN MONTH(Transaction_Date) <=9 THEN 'Q3'
    ELSE 'Q4' END QTR
    FROM Fact f
		LEFT JOIN Dim_Product p
			ON f.product_id = p.product_id
)
, revenue_product AS (
    SELECT
		Tran_Year,
        QTR,
        Product_Category,
        FORMAT(SUM(Revenue),2) AS Revenue
	FROM sales_product
    GROUP BY Tran_Year, QTR, product_category
)
SELECT
	*,
    FORMAT(LAG(Revenue) OVER(PARTITION BY product_category ORDER BY Tran_Year, QTR),2) AS Last_QTR,
    FORMAT(((Revenue -   LAG(Revenue) OVER(PARTITION BY product_category ORDER BY Tran_Year, QTR)) /
							LAG(Revenue) OVER(PARTITION BY product_category ORDER BY Tran_Year, QTR))*100,2) AS change_percent
FROM revenue_product
ORDER BY product_category, Tran_Year, QTR;

###############################################################
-- Query 4 - Revenue QoQ by Salesperson
WITH sales_staff AS (
SELECT
	Staff_id AS Staff_Id,
    Transaction_Date AS Tran_Date,
    Quantity * Unit_Price AS Revenue,
    YEAR(Transaction_Date) AS Tran_Year,
    MONTH(Transaction_Date) AS Tran_Month,
    CASE
		WHEN MONTH(Transaction_Date) <=3 THEN 'Q1'
        WHEN MONTH(Transaction_Date) <=6 THEN 'Q2'
        WHEN MONTH(Transaction_Date) <=9 THEN 'Q3'
    ELSE 'Q4' END QTR
    FROM Fact
)
, revenue_staff AS (
    SELECT
		Tran_Year,
        QTR,
        Staff_Id,
        FORMAT(SUM(Revenue),2) AS Revenue
	FROM sales_staff
    GROUP BY Tran_Year, QTR, staff_id
)
SELECT
	*,
    FORMAT(LAG(Revenue) OVER(PARTITION BY staff_id ORDER BY Tran_Year, QTR),2) AS Last_QTR,
    FORMAT(((Revenue -   LAG(Revenue) OVER(PARTITION BY staff_id ORDER BY Tran_Year, QTR)) / LAG(Revenue) OVER(PARTITION BY staff_id ORDER BY Tran_Year, QTR))*100,2) AS change_percent
FROM revenue_staff
ORDER BY staff_id, Tran_Year, QTR;

###############################################################

-- Query 5 - Top 5 Salespersons Q3/18
WITH revenueByStaff AS
(
SELECT
	f.Staff_Id AS Staff_Id,
    s.Staff_Name AS Staff_Name,
	ROUND(SUM(unit_price * Quantity),2) AS Revenue
FROM Fact f
	JOIN Dim_Staff s
		ON f.Staff_id = s.staff_id 
WHERE Transaction_Date BETWEEN '2018-07-01' AND '2018-09-30'
GROUP BY Staff_Id
ORDER BY Revenue
)
SELECT
	*,
    DENSE_RANK() OVER (ORDER BY Revenue DESC) AS RN
FROM revenueByStaff
LIMIT 5;

###############################################################

-- Query 6 - Top 3 products
WITH revenueByProduct AS
(
SELECT
	f.Product_Id AS Product_Id,
    p.Product AS Product_Name,
	ROUND(SUM(unit_price * Quantity),2) AS Revenue
FROM Fact f
	JOIN Dim_Product p 
		ON f.Product_Id = p.Product_Id
			AND transaction_date BETWEEN '2018-07-01' AND '2018-09-30'
GROUP BY product_id
ORDER BY Revenue
)
SELECT
	*,
    DENSE_RANK() OVER (ORDER BY Revenue DESC) AS RN
FROM revenueByProduct
LIMIT 3;

###############################################################
-- Query 7 - Top 2 Salespersons for top 3 products

WITH revenueByStaff AS
(
SELECT
	Staff_Id AS Staff_Id,
	ROUND(SUM(unit_price * Quantity),2) AS Revenue
FROM Fact
WHERE Product_Id IN (61, 59, 39)
	AND transaction_date BETWEEN '2018-07-01' AND '2018-09-30'
GROUP BY Staff_Id
ORDER BY Revenue DESC
)
SELECT
	*,
    DENSE_RANK() OVER (ORDER BY Revenue DESC) AS RN
FROM revenueByStaff
LIMIT 2;


###############################################################
-- Query 8 - Revenue by Products- Stores Comparison
SELECT
	f.Product_Id AS Product_Id,
    Product AS Product_Name,
    ROUND(SUM(CASE WHEN Store_City = 'New York' THEN unit_price * Quantity ELSE NULL END),2) AS Revenue_Store_NY,
    ROUND(SUM(CASE WHEN Store_City = 'Long Island City' THEN unit_price * Quantity ELSE NULL END),2) AS Revenue_Store_Long_Island,
    ROUND(SUM(unit_price * Quantity), 2) AS Revenue
FROM Fact f
	JOIN Dim_Product p
		ON f.Product_Id = p.Product_Id
			AND Transaction_Date BETWEEN '2018-07-01' AND '2018-09-30'
GROUP BY Product_Id
ORDER BY Revenue DESC;

###############################################################

-- Qוuery 9 - Revenue, Quanitity, AVG Unit Price by Product
SELECT
	Product_Id,
    ROUND(SUM(unit_price * Quantity),2) AS Revenue,
    SUM(Quantity) AS Qty,
    ROUND(SUM(unit_price * Quantity) / SUM(Quantity),2) AS avg_unit_price 
FROM Fact
GROUP BY Product_Id
ORDER BY Qty DESC, Revenue DESC;

###############################################################
-- Qוuery 10 - Avg days between transactions by products

WITH trans_date AS
(
SELECT
	Transaction_Date AS Tran_Date,
    Product_Id AS Product_Id
FROM Fact
GROUP BY Transaction_Date
ORDER BY Product_Id, Tran_Date
), dates_diff AS
(
SELECT
	*,
    LEAD(tran_date) OVER(PARTITION BY product_id ORDER BY tran_date) AS next_date,
    datediff(LEAD(tran_date) OVER(PARTITION BY product_id ORDER BY tran_date),tran_date) AS date_diff
FROM trans_date
)
SELECT
	Product_Id,
    ROUND(AVG(date_diff),2) AS AVG_days_trasn
FROM dates_diff
GROUP BY Product_Id
ORDER  BY Product_Id;
