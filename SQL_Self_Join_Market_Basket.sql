WITH total_orders AS (
    SELECT COUNT(order_id) AS orders_count
    FROM orders
),
order_values AS (
    SELECT
        order_id,
        SUM(quantity * unit_price) AS order_value
    FROM order_items
    GROUP BY order_id
)
SELECT
    p1.product_name AS Product_A,
    p2.product_name AS Product_B,
    COUNT(*) AS Times_Bought_Together,
    ROUND((COUNT(*) * 100.0 / t.orders_count), 2) AS Order_Coverage_Pct,
    SUM(ov.order_value) AS Total_Revenue,
    ROUND(AVG(ov.order_value), 2) AS Avg_Order_Value
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id
JOIN products p1 ON oi1.product_id = p1.product_id 
JOIN products p2 ON oi2.product_id = p2.product_id
JOIN order_values ov ON oi1.order_id = ov.order_id
CROSS JOIN total_orders t
WHERE oi1.product_id < oi2.product_id
GROUP BY p1.product_name, p2.product_name, t.orders_count
ORDER BY Times_Bought_Together DESC
LIMIT 10;