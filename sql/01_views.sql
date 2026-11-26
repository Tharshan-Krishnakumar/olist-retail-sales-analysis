-- Olist Retail Sales Analysis: cleaning views (PostgreSQL)
-- Run after loading the raw Olist CSVs into tables:
-- orders, order_items, customers, products, reviews, category_translation

-- 1. One review per order: keep the latest answered review.
--    Some orders have more than one review row, which would double-count scores.
CREATE VIEW reviews_clean AS
WITH ranked AS (
    SELECT
        order_id,
        review_score,
        review_creation_date,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY review_answer_timestamp DESC
        ) AS rn
    FROM reviews
)
SELECT order_id, review_score, review_creation_date
FROM ranked
WHERE rn = 1;

-- 2. English category names. LEFT JOIN keeps products with no translation;
--    COALESCE falls back to the Portuguese name, then 'unknown'.
CREATE VIEW products_clean AS
SELECT
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
FROM products p
LEFT JOIN category_translation t
    ON p.product_category_name = t.product_category_name;

-- 3. Analysis table at item grain (one row per item sold), delivered orders only.
CREATE VIEW sales_analysis AS
SELECT
    oi.order_id,
    oi.order_item_id,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_unique_id,
    c.customer_state,
    pc.category,
    oi.price,
    oi.freight_value,
    r.review_score
FROM order_items oi
JOIN orders o           ON oi.order_id = o.order_id
JOIN customers c        ON o.customer_id = c.customer_id
LEFT JOIN products_clean pc ON oi.product_id = pc.product_id
LEFT JOIN reviews_clean r   ON oi.order_id = r.order_id
WHERE o.order_status = 'delivered';
