WITH customer_lifetime_value AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    GROUP BY o.customer_id
),
customer_purchase_patterns AS (
    SELECT
        o.customer_id,
        DATE(DATE_TRUNC('month', o.order_date)) AS cohort_month,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS purchase_sequence,
        COUNT(*) OVER (PARTITION BY o.customer_id) AS total_orders,
        DATE(LEAD(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC))
            - DATE(o.order_date) AS days_to_next_purchase
    FROM orders o
)
SELECT
    cpp.cohort_month AS Cohort_Month,
    COUNT(*) AS Cohort_Size,
    ROUND(AVG(clv.total_revenue), 2) AS Avg_Customer_Lifetime_Value,
    ROUND(SUM(CASE WHEN days_to_next_purchase <= 90 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Q1_Retention_Rate,
    ROUND(SUM(CASE WHEN days_to_next_purchase <= 180 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS H1_Retention_Rate,
    ROUND(SUM(CASE WHEN days_to_next_purchase <= 365 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Y1_Retention_Rate
FROM customer_purchase_patterns cpp
JOIN customer_lifetime_value clv ON cpp.customer_id = clv.customer_id
WHERE cpp.purchase_sequence = 1
AND cpp.total_orders > 1
GROUP BY cpp.cohort_month
ORDER BY cpp.cohort_month;