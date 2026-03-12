WITH order_time_analysis AS (
    SELECT
        EXTRACT(ISODOW FROM o.order_date) AS day_num,
        TRIM(TO_CHAR(o.order_date, 'Day')) AS day_of_week,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY EXTRACT(ISODOW FROM o.order_date), TO_CHAR(o.order_date, 'Day')
),
order_avg AS (
    SELECT
        EXTRACT(ISODOW FROM o.order_date) AS day_num,
        ROUND(AVG(order_total), 2) AS avg_order_value
    FROM orders o
    JOIN (
        SELECT order_id, SUM(quantity * unit_price) AS order_total
        FROM order_items
        GROUP BY order_id
    ) oi ON o.order_id = oi.order_id
    GROUP BY EXTRACT(ISODOW FROM o.order_date)
)
SELECT
    ota.day_of_week AS Day_Of_Week,
    ota.total_orders AS Total_Orders,
    ota.total_revenue AS Total_Revenue,
    oa.avg_order_value AS Avg_Order_Value,
    ROUND((ota.total_orders * 100.0 / SUM(ota.total_orders) OVER ()), 2) AS Orders_Share_Pct,
    RANK() OVER (ORDER BY ota.total_orders DESC) AS Popularity_Rank
FROM order_time_analysis ota
JOIN order_avg oa ON ota.day_num = oa.day_num
ORDER BY Popularity_Rank;