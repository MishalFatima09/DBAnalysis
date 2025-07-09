create database BrazillianECommerce

use BrazillianECommerce

--Trying a primary key
ALTER TABLE olist_geolocation
ADD id INT IDENTITY(1,1);

ALTER TABLE olist_geolocation
ADD CONSTRAINT PK_olist_geolocation PRIMARY KEY (id, geolocation_zip_code_prefix);

--checking uniqueness
SELECT id, geolocation_zip_code_prefix, COUNT(*) AS count
FROM olist_geolocation
GROUP BY id, geolocation_zip_code_prefix
HAVING COUNT(*) > 1;
--returns zero! hence we are successful

--adding foreign keys
ALTER TABLE olist_order_reviews
ADD CONSTRAINT FK_order_reviews FOREIGN KEY (order_id)
REFERENCES olist_orders(order_id)
ON DELETE CASCADE;

ALTER TABLE olist_order_payments
ADD CONSTRAINT FK_order_payments FOREIGN KEY (order_id)
REFERENCES olist_orders(order_id)
ON DELETE CASCADE;

ALTER TABLE olist_order_items
ADD CONSTRAINT FK_order_items FOREIGN KEY (order_id)
REFERENCES olist_orders(order_id)
ON DELETE CASCADE;

ALTER TABLE olist_orders
ADD CONSTRAINT FK_orders FOREIGN KEY (customer_id)
REFERENCES olist_customers(customer_id)
ON DELETE CASCADE;

ALTER TABLE olist_order_items
ADD CONSTRAINT FK_order_products FOREIGN KEY (product_id)
REFERENCES olist_products(product_id)
ON DELETE CASCADE;

ALTER TABLE olist_order_items
ADD CONSTRAINT FK_order_sellers FOREIGN KEY (seller_id)
REFERENCES olist_sellers(seller_id)
ON DELETE CASCADE;

ALTER TABLE olist_sellers
ADD geolocation_id INT; -- corresponding `id` from `olist_geolocation`

ALTER TABLE olist_sellers
ADD CONSTRAINT FK_sellers_geolocation FOREIGN KEY (geolocation_id, seller_zip_code_prefix)
REFERENCES olist_geolocation(id, geolocation_zip_code_prefix)
ON DELETE CASCADE;


ALTER TABLE olist_customers
ADD geolocation_id INT; -- corresponding `id` from `olist_geolocation`

ALTER TABLE olist_customers
ADD CONSTRAINT FK_customers_geolocation FOREIGN KEY (geolocation_id,customer_zip_code_prefix)
REFERENCES olist_geolocation(id, geolocation_zip_code_prefix)
ON DELETE NO ACTION;





--+++++++++++++++++++++++++        ORDER ANALYSIS     ++++++++++++++++++++++++++++++++++++++++

--1. Percentage of orders that got delayed beyond the estimated date.

SELECT (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_orders)) AS delayed_percentage
FROM olist_orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;

--2. What are the peak months of order delays?
--more than ten records
SELECT 
    MONTH(order_delivered_customer_date) AS delayed_month,
    YEAR(order_delivered_customer_date) AS delayed_year,
    COUNT(*) AS delayed_orders
FROM olist_orders
WHERE order_delivered_customer_date > order_estimated_delivery_date
AND order_delivered_customer_date IS NOT NULL
GROUP BY YEAR(order_delivered_customer_date), MONTH(order_delivered_customer_date)
ORDER BY delayed_orders DESC;

--3. Which state experiences the highest order delays?
SELECT TOP 1
    g.geolocation_state AS state,
    COUNT(o.order_id) AS delayed_orders
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
JOIN olist_geolocation g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY g.geolocation_state
ORDER BY delayed_orders DESC;

--4. See how many orders are still in “pending” status for each year.

SELECT YEAR(order_purchase_timestamp) AS order_year, COUNT(order_id) AS pending_orders
FROM olist_orders
WHERE order_status = 'pending'
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;


--5. What is the average delay duration per seller?

SELECT oi.seller_id, AVG(DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS avg_delay_days
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY oi.seller_id
ORDER BY avg_delay_days DESC;
--what do sm records

--worst 
SELECT TOP 1 oi.seller_id, AVG(DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS avg_delay_days
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY oi.seller_id
ORDER BY avg_delay_days DESC;

--overall
SELECT AVG(avg_delay_days) AS overall_avg_delay
FROM (
    SELECT oi.seller_id, AVG(DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS avg_delay_days
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
    GROUP BY oi.seller_id
) AS seller_delays;
--more than 10 days
SELECT COUNT(*) AS sellers_with_long_delays
FROM (
    SELECT oi.seller_id, AVG(DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS avg_delay_days
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
    GROUP BY oi.seller_id
) AS seller_delays
WHERE avg_delay_days > 10;



--6 Find the average shipping cost for delayed and on-time orders.

SELECT 'Delayed' AS DeliveryStatus, AVG(oi.freight_value)  AS AverageAmount
FROM olist_order_items oi
JOIN olist_orders o on oi.order_id = o.order_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date

UNION ALL

SELECT 'On Time' AS DeliveryStatus, AVG(oi.freight_value)  AS AverageAmount
FROM olist_order_items oi
JOIN olist_orders o on oi.order_id = o.order_id
WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date


--7. Which product category experience the most order delays.

SELECT TOP 1 t.column2 AS product_category,  -- English category name
    COUNT(o.order_id) AS delayed_orders
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id
JOIN olist_products p ON oi.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.column1
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY t.column2
ORDER BY delayed_orders DESC;

--8. Find the average number of items for delayed and on time orders.

SELECT 'Delayed' AS DeliveryStatus, AVG(items_per_order) AS AverageAmount
FROM (
    SELECT o.order_id, COUNT(oi.order_item_id) AS items_per_order
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
    GROUP BY o.order_id
) AS DelayedOrders

UNION ALL

SELECT 'On Time' AS DeliveryStatus, AVG(items_per_order) AS AverageAmount
FROM (
    SELECT o.order_id, COUNT(oi.order_item_id) AS items_per_order
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date
    GROUP BY o.order_id
) AS OnTimeOrders





-- =========================== PRODUCT ANALYSIS ==========================

--1.What is the most profitable product category per state?

--resulted in more than ten records

SELECT c.customer_state, pct.column2 as ProductName, SUM(oi.price) as total_sales 
FROM olist_customers c 
JOIN olist_orders o on c.customer_id = o.customer_id
JOIN olist_order_items oi on oi.order_id = o.order_id
JOIN olist_products p on p.product_id = oi.product_id
JOIN product_category_name_translation pct on p.product_category_name = pct.column1
GROUP BY c.customer_state, pct.column2
HAVING SUM(oi.price) = (
    SELECT MAX(TotalSales)
    FROM (
        SELECT 
            c2.customer_state, 
            pct2.column2 AS ProductName, 
            SUM(oi2.price) AS TotalSales
        FROM olist_customers c2
        JOIN olist_orders o2 ON c2.customer_id = o2.customer_id
        JOIN olist_order_items oi2 ON oi2.order_id = o2.order_id
        JOIN olist_products p2 ON p2.product_id = oi2.product_id
        JOIN product_category_name_translation pct2 ON p2.product_category_name = pct2.column1
        WHERE c2.customer_state = c.customer_state
        GROUP BY c2.customer_state, pct2.column2
    ) AS subquery
)
ORDER BY c.customer_state


--2. Find which hours of the day have the highest number of order placements for each product category.

SELECT 
   ProductCategoryName, OrderHour, TotalOrders
FROM (
    SELECT pct.column2 AS ProductCategoryName, DATEPART(HOUR, o.order_approved_at) AS OrderHour,
        COUNT(*) AS TotalOrders
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation pct ON p.product_category_name = pct.column1
    WHERE o.order_approved_at IS NOT NULL
    GROUP BY pct.column2, DATEPART(HOUR, o.order_approved_at)
) AS OrdersPerHour
WHERE TotalOrders = (
    SELECT MAX(TotalOrders)
    FROM (
        SELECT 
            DATEPART(HOUR, o2.order_approved_at) AS hour,
            COUNT(*) AS TotalOrders
        FROM olist_orders o2
        JOIN olist_order_items oi2 ON o2.order_id = oi2.order_id
        JOIN olist_products p2 ON oi2.product_id = p2.product_id
        JOIN product_category_name_translation pct2 ON p2.product_category_name = pct2.column1
        WHERE o2.order_approved_at IS NOT NULL
          AND pct2.column2 = OrdersPerHour.ProductCategoryName
        GROUP BY DATEPART(HOUR, o2.order_approved_at)
    ) AS CategoryHours
)
ORDER BY ProductCategoryName;
--resulted in mroe than ten records
--one for each product category


--3. Find the top 5 product categories with the highest number of delayed orders.

SELECT TOP 5 pct.column2 AS ProductCategoryName,  COUNT(*) AS DelayedOrderCount
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation pct ON p.product_category_name = pct.column1
    WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
    GROUP BY pct.column2
	ORDER BY DelayedOrderCount DESC

--4. Find whether higher-priced products sell less by comparing average price vs. total sales.

SELECT 
    pct.column2 AS ProductCategoryName,  
    AVG(oi.price) AS AveragePrice,  
    COUNT(*) AS NumberOfItemsSold
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
JOIN product_category_name_translation pct ON p.product_category_name = pct.column1
GROUP BY pct.column2
ORDER BY AveragePrice DESC;


--5.Which products are most frequently bought together? Find the most frequently purchased product pairs.

SELECT 
    p1.product_id AS Product1,
    p2.product_id AS Product2,
    COUNT(*) AS TimesBoughtTogether
FROM olist_order_items p1
JOIN olist_order_items p2
    ON p1.order_id = p2.order_id
    AND p1.product_id != p2.product_id 
GROUP BY p1.product_id, p2.product_id
ORDER BY TimesBoughtTogether DESC;


--f. Calculate the total revenue per product category by summing order item prices.

SELECT 
    pct.column2 AS ProductCategoryName,  
    SUM(oi.price) AS TotalRevenue
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
JOIN product_category_name_translation pct ON p.product_category_name = pct.column1
GROUP BY pct.column2
ORDER BY TotalRevenue DESC;

--g. Compute the average review score for each product category.

SELECT 
    pct.column2 AS ProductCategoryName,  
    AVG(r.review_score) AS ReviewScore
	FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation pct ON p.product_category_name = pct.column1
	JOIN olist_order_reviews r on r.order_id = o.order_id 
GROUP BY pct.column2
ORDER BY ReviewScore DESC;

--more than ten!

--h. Retrieve the top 5 products based on total sales revenue.

SELECT TOP 7
    pct.column2 AS ProductCategoryName,  
    SUM(oi.price) AS TotalRevenue
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
JOIN product_category_name_translation pct ON p.product_category_name = pct.column1
GROUP BY p.product_id, pct.column2
ORDER BY TotalRevenue DESC;
