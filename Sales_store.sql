  CREATE TABLE sale_store(
  transaction_id VARCHAR(15),
  customer_id VARCHAR(15),
  customer_name VARCHAR(30),
  customer_age  INT,
  gender VARCHAR(15),
  product_id VARCHAR(15),
  product_name  VARCHAR(15),
  product_category  VARCHAR(15),
  quantiy INT,
  prce FLOAT,
  payment_mode VARCHAR(15),
  purchase_date DATE,
  time_of_purchase TIME,
  status VARCHAR(15)
  );



  SELECT * 
  FROM sale_store;

  -- Import Data 

  SET DATEFORMAT dmy
  BULK INSERT sale_store
  FROM 'C:\Users\almagd-tec\Downloads\archive (1)\sales-store.csv'
	WITH (
		FIRSTROW=2,
		FIELDTERMINATOR= ',',
		ROWTERMINATOR='\n'
	);



--  Making a Copy of Data 

SELECT * INTO sales
FROM sale_store

-- Data Cleaning 

-- Step 1 : Check for Duplicates
SELECT transaction_id, COUNT(*)
FROM sales 
GROUP BY transaction_id
HAVING COUNT(transaction_id) > 1 

WITH CTE AS (
SELECT *,
	ROW_NUMBER() OVER
	(PARTITION BY transaction_id
	ORDER BY transaction_id) AS Row_num
FROM sales
) 
--DELETE FROM CTE 
--WHERE Row_num = 2
SELECT * FROM CTE 
WHERE transaction_id IN ( 'TXN240646' ,'TXN342128', 'TXN855235', 'TXN981773')

-- Step 2 Correction of Headers 
SELECT * 
FROM sales

EXEC sp_rename'sales.quantiy','quantity', 'COLUMN'
EXEC sp_rename'sales.prce','price', 'COLUMN'


-- Step 3 Check Data Types 

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME= 'sales';


-- Step 4 Check For NUll Values 
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
            COUNT(*) AS NullCount
     FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
     WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
    ' UNION ALL '
) WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

EXEC sp_executesql @SQL;


-- Treating NUll Values
SELECT *
FROM sales
WHERE transaction_id IS NULL
   OR time_of_purchase IS NULL
   OR customer_id IS NULL
   OR customer_age IS NULL
   OR customer_name IS NULL
   OR gender IS NULL
   OR payment_mode IS NULL
   OR price IS NULL
   OR quantity IS NULL
   OR status IS NULL;

DELETE FROM sales
WHERE transaction_id IS NULL


SELECT * 
FROM sales
WHERE customer_name = 'Ehsaan Ram'

UPDATE sales
SET customer_id= 'CUST9494'
WHERE transaction_id='TXN977900'


SELECT * 
FROM sales
WHERE customer_name = 'Damini Raju'

UPDATE sales
SET customer_id='CUST1401'
WHERE transaction_id= 'TXN985663'

SELECT * 
FROM sales
WHERE customer_id = 'CUST1003'

UPDATE sales
SET customer_name='CUST1401', customer_age= 35, gender='Male'
WHERE transaction_id= 'TXN432798'


-- Step 5 Data Cleaning 
SElECT DISTINCT gender 
FROM sales


UPDATE sales 
SET gender= 'M'
WHERE gender= 'Male'

UPDATE sales 
SET gender= 'F'
WHERE gender= 'Female'


SELECT DISTINCT payment_mode
FROM sales 

UPDATE sales 
SET payment_mode= 'CC'
WHERE payment_mode= 'Credit Card'


UPDATE sales 
SET payment_mode= 'Credit Card'
WHERE payment_mode= 'CC'



-- Data Analysis 

--- 1. What are the top 5 Most Selling Products By quantity
SELECT TOP 5 product_name,
       SUM(quantity) AS total_quantity_sold
FROM sales
WHERE status= 'delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC; 

--Business Problem: We don't know which products are most in demand.
--Business Impact: Helps prioritize stock and boost sales through targeted promotions.


----------------------------------------------------------

-- 2. Which Products are most frequently Canceled
SELECT  TOP 5 product_name,COUNT(*) AS total_canceled
FROM sales 
WHERE status = 'cancelled'
GROUP BY product_name
ORDER BY total_canceled DESC


-- Business Problem: Frequent Cancellation affect Revenue and Customer Trust 
-- Business Impact: Identify poor-performing products to improve quality or remove from catalog.


-------------------------------------------------------
-- 3. What time of the day has the highest number of Purchases



SELECT 
	CASE
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	END AS time_of_day,
	COUNT(*) AS total_orders
FROM sales
GROUP BY 
		CASE
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	END 
ORDER BY total_orders DESC 


--Business Problem Solved: Find peak sales times.
--Business Impact: Optimize staffing, promotions, and server loads.


--- 4- Who are the top 5 Highest Spending Customers? 

SELECT TOP 5 customer_name,
	FORMAT(SUM(price*quantity),'C0', 'en_IN') AS Total_Spend
FROM sales 
GROUP BY customer_name
ORDER BY SUM(price*quantity) DESC

-- Business Problem Solved: Identify VIP customers
-- Business Impact: Personalized offers, loyalty rewards, and retentic

-------------------------------------------------------------------------------

--- 5. which product categories generate the highest revenue? 

SELECT 
	product_category,
	FORMAT(SUM(price*quantity),'C0', 'en_IN') AS Revenue
FROM sales
GROUP BY product_category
ORDER BY SUM(price*quantity) DESC;

--Business Problem Solved: Identify top-performing product categories.

--Business Impact: Refine product strategy, supply chain, and promotions,
--allowing the business to invest more in high-margin or high-demand categories.

-----------------------------------------------------------------------------------

-- 6. What is the return/cancellation rate per product category
-- Cancellation
SELECT product_category,
       FORMAT(COUNT(CASE
	   WHEN status = 'cancelled' THEN 1
	   END) * 100.0 / COUNT(*), 'N3')+'%'
       AS cancelled_percent
FROM sales
GROUP BY product_category
ORDER BY cancelled_percent DESC;

-- Return 
SELECT product_category,
       FORMAT(COUNT(CASE
	   WHEN status = 'returned' THEN 1
	   END) * 100.0 / COUNT(*), 'N3')+'%'
       AS Returned_percent
FROM sales
GROUP BY product_category
ORDER BY Returned_percent DESC; 

---Business Impact: Reduce returns, improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.
------------------------------------------------------------

-- Q 7. What is the most preferred payment mode?

SELECT payment_mode, COUNT(payment_mode) AS Total_Count
FROM sales
GROUP BY payment_mode
ORDER BY Total_Count DESC


--Business Problem Solved: Know which payment options customers prefer.

--Business Impact: Streamline payment processing, prioritize popular modes.

------------------------------------------------------------

--  8. How does age group affect purchasing behavior?
SELECT * 
FROM sales
--SELECT MIN(customer_age), MAX(customer_age)
--From sales

SELECT 
	CASE
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 35 AND 50 THEN '36-50'
		ELSE '51+'
	END AS Age_group, 
	FORMAT(SUM(price*quantity),'C0', 'en_IN') AS total_purchase
FROM sales
GROUP BY 	CASE
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 35 AND 50 THEN '36-50'
		ELSE '51+'
	END
ORDER BY SUM(price*quantity) DESC 

--Business Problem Solved: Understand customer demographics.

--Business Impact: Targeted marketing and product recommendations by age group.

------------------------------------------------------------

--  9. What’s the monthly sales trend?


SELECT 
	FORMAT(purchase_date, 'yyyy-MM') AS Month_Year,
	FORMAT(SUM(price*quantity),'C0','en_IN') AS total_sales,
	SUM(quantity) AS total_quantity
FROM sales 
GROUP BY FORMAT(purchase_date, 'yyyy-MM')



--Business Problem: Sales fluctuations go unnoticed.

--Business Impact: Plan inventory and marketing according to seasonal trends.

--------------------------------------------------------------------------------

--  10. Are certain genders buying more specific product categories?


SELECT *
FROM (
	SELECT gender, product_category
	FROM sales
	) AS Source_table

PIVOT (
	COUNT(gender)
	FOR gender IN ([Male],[Female])
	) AS pivot_table
ORDER BY product_category

-- Business Problem Solved: Gender-based product preferences
-- Business Impact: Personalized ads, gender-focused Campaigns