-- Olist Retail Sales Analysis: business questions (PostgreSQL)
-- All queries read from the sales_analysis view (item grain, delivered orders).
-- Revenue = sum of item price (freight excluded).

-- Q1. Headline KPIs
SELECT
    COUNT(*)                                   AS items_sold,       -- 110,197
    COUNT(DISTINCT order_id)                   AS total_orders,     -- 96,478
    ROUND(SUM(price), 2)                       AS total_revenue,    -- 13,221,498.11
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS avg_order_value -- 137.04
FROM sales_analysis;

-- Q2. Monthly revenue trend (peak: November 2017, Black Friday)
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
    ROUND(SUM(price), 2)                          AS revenue
FROM sales_analysis
GROUP BY order_month
ORDER BY order_month;

-- Q3. Revenue by category, with share of total (top: health_beauty, 9.32%)
SELECT
    category,
    ROUND(SUM(price), 2) AS revenue,
    ROUND(100 * SUM(price) / SUM(SUM(price)) OVER (), 2) AS pct_of_revenue
FROM sales_analysis
GROUP BY category
ORDER BY revenue DESC;

-- Q4. Late deliveries and customer reviews (order grain)
--     Compare by day, not timestamp: same-day deliveries are on time.
WITH orders_status AS (
    SELECT DISTINCT
        order_id,
        review_score,
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 'no date'
            WHEN DATE_TRUNC('day', order_delivered_customer_date) > order_estimated_delivery_date THEN 'late'
            ELSE 'on time'
        END AS delivery_status
    FROM sales_analysis
)
SELECT
    delivery_status,
    COUNT(*)                                        AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_orders,
    ROUND(AVG(review_score), 2)                     AS avg_review   -- late 2.27, on time 4.29
FROM orders_status
GROUP BY delivery_status
ORDER BY orders DESC;

-- Q5. Revenue and average order value by state (SP = 38.32% of revenue)
SELECT
    customer_state,
    ROUND(SUM(price), 2) AS revenue,
    ROUND(100 * SUM(price) / SUM(SUM(price)) OVER (), 2) AS pct_of_revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)        AS avg_order_value
FROM sales_analysis
GROUP BY customer_state
ORDER BY revenue DESC;
