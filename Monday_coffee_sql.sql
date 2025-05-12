Create database Monday_Coffee;
use Monday_Coffee;

select * from city;
select * from customers;
select * from products;
select * from sales;

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name,round(population*0.25)/1000000 
as estimated_coffee_consumers_in_millions
from city
order by population desc;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
where quarter(s.sale_date) = 4
and year(s.sale_date) =2023
group by ci.city_name
order by total_revenue desc;

 -- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT p.product_name,
	COUNT(s.sale_id) as total_units_sold
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units_sold DESC;


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customers,
	ROUND(
			SUM(s.total)/
				COUNT(DISTINCT s.customer_id)
			,2) as avg_sales_per_city
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY avg_sales_per_city DESC;

-- Q.5
-- Provide a list of cities along with their populations and estimated coffee consumers.


-- Step 1: Estimate coffee consumers in each city
WITH estimated_consumers AS (
    SELECT 
        city_name,
        ROUND((population * 0.25)/1000000,2) AS estimated_coffee_consumers_in_millions
    FROM city
),

-- Step 2: Count actual customers who bought coffee
actual_customers AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS total_customers
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name
)

-- Step 3: Join both results together
SELECT 
    e.city_name,
    e.estimated_coffee_consumers_in_millions ,
    a.total_customers
FROM estimated_consumers e
JOIN actual_customers a ON e.city_name = a.city_name;

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

-- Get top 3 selling products in each city based on number of sales
SELECT 
    city_name,
    product_name,
    total_orders,
    product_rank
FROM (
    -- Step 1: Join tables and count product sales per city
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,

        -- Step 2: Rank products within each city based on total sales
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name
            ORDER BY COUNT(s.sale_id) DESC
        ) AS product_rank

    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name, p.product_name
) AS ranked_products

-- Step 3: Keep only top 3 ranked products per city
WHERE product_rank <= 3
ORDER BY city_name, product_rank;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
    ci.city_name,
    ROUND(SUM(s.total) / COUNT(DISTINCT cu.customer_id), 2) AS avg_sale_per_customer,
    ROUND(ci.estimated_rent, 2) AS avg_rent_per_customer
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN city ci ON cu.city_id = ci.city_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY ci.city_name;

-- 8. What are the products with the highest ratings in each city?
SELECT 
    c.city_name,
    p.product_name,
    AVG(s.rating) AS avg_rating
FROM 
    sales s
JOIN 
    customers cu ON s.customer_id = cu.customer_id
JOIN 
    city c ON cu.city_id = c.city_id
JOIN 
    products p ON s.product_id = p.product_id
GROUP BY 
    c.city_name, p.product_name
ORDER BY 
    c.city_name,avg_rating DESC;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city
-- Step 1: Get total sales for each city and each month
-- Step 1: Get total sales for each city and each month
WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, MONTH(s.sale_date), YEAR(s.sale_date)
    ORDER BY ci.city_name, year, month
),

-- Step 2: Get current and previous month's sales
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)

-- Step 3: Calculate percentage growth
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) / last_month_sale * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
order by city_name, year,month;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
SELECT 
    ci.city_name,
    SUM(s.total) AS total_sale,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND((SUM(s.total) * 1.0) / COUNT(DISTINCT c.customer_id), 2) AS avg_revenue_per_customer,
    ci.estimated_rent * COUNT(DISTINCT c.customer_id) AS total_rent,
    ROUND((ci.estimated_rent * 1.0), 2) AS avg_rent_per_customer,
    ROUND((ci.population * 0.25) / 1000000, 2) AS estimated_coffee_consumers_in_millions
FROM sales AS s
JOIN customers AS c ON c.customer_id = s.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name, ci.population, ci.estimated_rent
ORDER BY 
    total_sale DESC,
    estimated_coffee_consumers_in_millions DESC,
    avg_revenue_per_customer DESC,
    avg_rent_per_customer ASC
LIMIT 3;

