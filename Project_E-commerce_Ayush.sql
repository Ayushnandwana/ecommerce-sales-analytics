



-- Question 14

SELECT
    CustomerID,
    Total_Revenue,
    Order_Frequency,
    Avg_Order_Value,
    ROUND(
        (0.5 * Total_Revenue) +
        (0.3 * Order_Frequency) +
        (0.2 * Avg_Order_Value),
        2
    ) AS Composite_Score
FROM (
    SELECT
        CustomerID,
        ROUND(SUM(`Unit Price` * `Order Quantity`), 2) AS Total_Revenue,
        COUNT(DISTINCT OrderID) AS Order_Frequency,
        ROUND(SUM(`Unit Price` * `Order Quantity`) / COUNT(DISTINCT OrderID), 2) AS Avg_Order_Value
    FROM orders
    WHERE Status = 'Delivered'
    GROUP BY CustomerID
) AS customer_metrics
ORDER BY Composite_Score DESC
LIMIT 5;


-- Question 15

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(STR_TO_DATE(OrderDate, '%d/%m/%Y'), '%Y-%m') AS month,
        SUM(`Sale Price` * `Order Quantity`) AS total_revenue
    FROM orders
    WHERE Status = 'Delivered'
    GROUP BY DATE_FORMAT(STR_TO_DATE(OrderDate, '%d/%m/%Y'), '%Y-%m')
),
mom_calc AS (
    SELECT
        month,
        total_revenue,
        LAG(total_revenue) OVER (ORDER BY month) AS prev_month_revenue
    FROM monthly_revenue
)
SELECT
    month,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(prev_month_revenue, 2) AS prev_month_revenue,
    ROUND(
        ((total_revenue - prev_month_revenue) / prev_month_revenue) * 100,
        2
    ) AS mom_growth_percent
FROM mom_calc
ORDER BY month;

-- Question 16

WITH monthly_category_revenue AS (
    SELECT
        `Product Category`,
        DATE_FORMAT(STR_TO_DATE(OrderDate, '%d/%m/%Y'), '%Y-%m') AS month,
        SUM(`Sale Price` * `Order Quantity`) AS monthly_revenue
    FROM orders
    WHERE Status = 'Delivered'
    GROUP BY
        `Product Category`,
        DATE_FORMAT(STR_TO_DATE(OrderDate, '%d/%m/%Y'), '%Y-%m')
)
SELECT
    `Product Category`,
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(
        AVG(monthly_revenue) OVER (
            PARTITION BY `Product Category`
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_avg_revenue
FROM monthly_category_revenue
ORDER BY `Product Category`, month;




-- Question 17

SET SQL_SAFE_UPDATES = 0;

UPDATE orders o
JOIN (
    SELECT CustomerID
    FROM orders
    GROUP BY CustomerID
    HAVING COUNT(DISTINCT OrderID) >= 10
) c
ON o.CustomerID = c.CustomerID
SET o.`Sale Price` = o.`Sale Price` * 0.85;

 
 -- Question 18
 
 

WITH customer_orders AS (
    SELECT
        CustomerID,
        STR_TO_DATE(OrderDate, '%d/%m/%Y') AS order_date
    FROM orders
    WHERE Status = 'Delivered'
),
ranked_orders AS (
    SELECT
        CustomerID,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY CustomerID
            ORDER BY order_date
        ) AS prev_order_date
    FROM customer_orders
),
order_gaps AS (
    SELECT
        CustomerID,
        DATEDIFF(order_date, prev_order_date) AS gap_days
    FROM ranked_orders
    WHERE prev_order_date IS NOT NULL
),
eligible_customers AS (
    SELECT CustomerID
    FROM customer_orders
    GROUP BY CustomerID
    HAVING COUNT(*) >= 5
)
SELECT
    og.CustomerID,
    ROUND(AVG(og.gap_days), 2) AS avg_days_between_orders
FROM order_gaps og
JOIN eligible_customers ec
    ON og.CustomerID = ec.CustomerID
GROUP BY og.CustomerID
ORDER BY avg_days_between_orders;



-- Question 19

WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(`Unit Price` * `Order Quantity`) AS total_revenue
    FROM orders
    WHERE Status = 'Delivered'
    GROUP BY CustomerID
),
avg_rev AS (
    SELECT AVG(total_revenue) AS avg_revenue_per_customer
    FROM customer_revenue
)
SELECT
    cr.CustomerID,
    ROUND(cr.total_revenue, 2) AS total_revenue,
    ROUND(ar.avg_revenue_per_customer, 2) AS avg_revenue_per_customer
FROM customer_revenue cr
CROSS JOIN avg_rev ar
WHERE cr.total_revenue > (1.30 * ar.avg_revenue_per_customer)
ORDER BY cr.total_revenue DESC;


-- Question 20



WITH yearly_category_sales AS (
    SELECT
        YEAR(STR_TO_DATE(OrderDate, '%d/%m/%Y')) AS order_year,
        `Product Category` as ProductCategory,
        SUM(`Unit Price` * `Order Quantity`) AS total_sales
    FROM orders
    WHERE Status = 'Delivered'
    GROUP BY
        YEAR(STR_TO_DATE(OrderDate, '%d/%m/%Y')),
        `Product Category`
),
latest_year AS (
    SELECT MAX(order_year) AS max_year
    FROM yearly_category_sales
)
SELECT
    ycs.ProductCategory,
    ROUND(SUM(CASE WHEN ycs.order_year = ly.max_year THEN ycs.total_sales END), 2) AS sales_last_year,
    ROUND(SUM(CASE WHEN ycs.order_year = ly.max_year - 1 THEN ycs.total_sales END), 2) AS sales_previous_year,
    ROUND(
        (SUM(CASE WHEN ycs.order_year = ly.max_year THEN ycs.total_sales END) -
         SUM(CASE WHEN ycs.order_year = ly.max_year - 1 THEN ycs.total_sales END)),
        2
    ) AS sales_increase FROM yearly_category_sales ycs
CROSS JOIN latest_year ly
GROUP BY ycs.ProductCategory
HAVING sales_previous_year IS NOT NULL ORDER BY sales_increase DESC LIMIT 3;










































