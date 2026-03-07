WITH first_last_category AS (
    SELECT
        o.customer_id,
        c.category_name,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS first_rn,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC) AS last_rn
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
),
customer_categories AS (
    SELECT
        o.customer_id,
        c.category_name,
        COUNT(*) AS orders_in_category,
        SUM(oi.quantity * oi.unit_price) AS category_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id 
            ORDER BY COUNT(*) DESC, SUM(oi.quantity * oi.unit_price) DESC
        ) AS category_rank
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY o.customer_id, p.category_id, c.category_name
),
customer_totals AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT p.category_id) AS unique_categories_count,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.customer_id
)
SELECT
    cust.customer_id,
    cust.first_name,
    cust.last_name,
    fc.category_name AS First_Category,
    lc.category_name AS Last_Category,
    ct.unique_categories_count AS Unique_Categories,
    cc.category_name AS Favorite_Category,
    cc.category_revenue AS Favorite_Category_Revenue,
    ct.total_revenue AS Total_Revenue,
    ROUND((cc.category_revenue / ct.total_revenue) * 100, 2) AS Favorite_Category_Pct
FROM customers cust
JOIN first_last_category fc ON cust.customer_id = fc.customer_id AND fc.first_rn = 1
JOIN first_last_category lc ON cust.customer_id = lc.customer_id AND lc.last_rn = 1
JOIN customer_categories cc ON cust.customer_id = cc.customer_id AND cc.category_rank = 1
JOIN customer_totals ct ON cust.customer_id = ct.customer_id
ORDER BY cust.customer_id;