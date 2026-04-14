SELECT * FROM superstore
LIMIT 5;

ALTER TABLE superstore ADD COLUMN order_date_new DATE;
UPDATE superstore 
SET order_date_new = STR_TO_DATE(order_date, '%m-%d-%Y');

SET SQL_SAFE_UPDATES = 1;

UPDATE superstore 
SET order_date_new = STR_TO_DATE(order_date, '%m-%d-%Y')
WHERE order_date IS NOT NULL;

SELECT order_date, order_date_new FROM superstore LIMIT 10;

## Q1). Total business performance -->Total Sales -->Total Profit -->Total Orders
SELECT ROUND(SUM(sales),2) AS total_sales, ROUND(SUM(profit),2) AS total_profit, COUNT(row_id) AS total_orders
FROM superstore;

## Q2). Sales by Category
## i).Which category sells the most?
SELECT category, ROUND(SUM(sales),2) AS total_sales FROM superstore
GROUP BY category
ORDER BY total_sales DESC
LIMIT 1;

## ii).Which is most profitable?
SELECT category, ROUND(SUM(profit)) AS max_profit FROM superstore
GROUP BY category
LIMIT 1;

## Q3).Top 10 Customers, Who brings the most revenue?
SELECT customer_id, customer_name, ROUND(SUM(sales),2) AS revenue FROM superstore
GROUP  BY customer_id, customer_name
ORDER BY revenue DESC
LIMIT 10;

## Q4). Region-wise performance, -->Sales & profit by region
SELECT region, ROUND(SUM(sales),2) As total_sales, ROUND(SUM(profit),2) AS total_profit FROM superstore
GROUP BY region;

##---------------------------------
ALTER TABLE superstore ADD COLUMN order_date_new DATE;
--
UPDATE superstore 
SET order_date_new = STR_TO_DATE(order_date, '%m-%d-%Y')
WHERE order_date IS NOT NULL;
##---------------------------------

## Q5). Monthly Sales Trend --> Group by: Year,Month
SELECT 
    YEAR(order_date_new) AS year_,
    MONTH(order_date_new) AS month_,
    ROUND(SUM(sales),2) AS total_sales
FROM superstore
GROUP BY YEAR(order_date_new), MONTH(order_date_new)
ORDER BY year_, month_;

##Q6). Profit by Sub-Category Find: i). Most profitable 
SELECT sub_category, ROUND(SUM(profit),2) AS total_profit FROM superstore
GROUP BY sub_category
ORDER BY total_profit DESC
LIMIT 1;

## ii). Loss-making sub-categories
SELECT sub_category, ROUND(SUM(profit),2) AS total_profit FROM superstore
GROUP BY sub_category
ORDER BY total_profit ASC
LIMIT 1;

## Q7). Discount Impact, Compare: Discount vs Profit
SELECT discount_bucket, ROUND(SUM(profit),2) AS profits FROM superstore
GROUP by discount_bucket;

## Q8). Customer Segmentation --Create: High Value,Medium Value,Low Value

WITH customer_sales AS (
    SELECT customer_id,SUM(sales) AS total_sales
    FROM superstore
    GROUP BY customer_id
),
customer_segment AS (
    SELECT 
        customer_id,
        total_sales,
        ROUND(total_sales * 100 / SUM(total_sales) OVER (), 2) AS sales_percentage,
        CASE 
            WHEN total_sales > 10000 THEN 'High Value'
            WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
	   END AS segment
    FROM customer_sales
)
SELECT segment,COUNT(customer_id) AS customer_count,
ROUND(SUM(total_sales) * 100 / SUM(SUM(total_sales)) OVER (), 2) AS contribution_percentage
FROM customer_segment
GROUP BY segment
ORDER BY contribution_percentage DESC;

## Q9). Average Order Value, 
##i).Total Sales
SELECT ROUND(Avg(sales),2) AS avg_sales_per_order FROM  superstore;

##ii).  Number of Orders above avg sales
SELECT ROUND(AVG(sales),2) AS avg_sales,
COUNT(*) AS no_of_orders_greater_than_avg_sales
FROM superstore
WHERE sales > (SELECT AVG(sales) FROM superstore);

## Q10). Repeat vs One-time Customers 
##i).Customers with multiple orders
SELECT COUNT(*) OVER() AS total_multiple_orders,customer_id,total_orders FROM ( SELECT customer_id,COUNT(*) AS total_orders FROM superstore
GROUP BY customer_id)t
WHERE total_orders>1
ORDER BY total_orders DESC;

## ii).Customers with single order
SELECT COUNT(*) OVER () AS total_one_time_customers,
    customer_id,total_orders FROM ( SELECT customer_id, COUNT(*) AS total_orders FROM superstore
				GROUP BY customer_id)t
WHERE total_orders = 1;

## Q11). Top products in each category
SELECT * FROM ( SELECT category,sub_category, ROUND(SUM(sales),2) AS total_sales, RANK() OVER(PARTITION BY category ORDER BY SUM(sales) DESC) AS rnk
				FROM superstore
                GROUP BY category,sub_category)t
WHERE rnk =1;

## Q12). Contribution %, Each category’s % of total sales
WITH sales_percentage AS (
SELECT category, ROUND(SUM(sales) * 100 / SUM(SUM(sales)) OVER(),2) AS percentage FROM superstore
GROUP BY category
)
SELECT * FROM sales_percentage;
