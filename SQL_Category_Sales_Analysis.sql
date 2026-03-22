WITH category_revenue_analysis AS (
    SELECT
        c.category_name,
        EXTRACT(YEAR FROM o.order_date) AS year,
        EXTRACT(QUARTER FROM o.order_date) AS quarter,
        SUM(oi.quantity * oi.unit_price) AS quarterly_revenue        
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY c.category_name, EXTRACT(YEAR FROM o.order_date), EXTRACT(QUARTER FROM o.order_date)
)
SELECT
    year AS Year,
    quarter AS Quarter,
    category_name AS Category_Name,
    quarterly_revenue AS Quarterly_Revenue,
    LAG(quarterly_revenue) OVER (PARTITION BY category_name ORDER BY year, quarter) AS Previous_Quarter_Revenue,
    ROUND(    
        ((quarterly_revenue - LAG(quarterly_revenue) OVER (PARTITION BY category_name ORDER BY year, quarter))
        / NULLIF(LAG(quarterly_revenue) OVER (PARTITION BY category_name ORDER BY year, quarter), 0)) 
        * 100,
    2) AS QoQ_Change_Pct,
    ROUND((quarterly_revenue / SUM(quarterly_revenue) OVER (PARTITION BY year, quarter)) * 100, 2) AS Category_Share_Pct,
    RANK() OVER (PARTITION BY year, quarter ORDER BY quarterly_revenue DESC) AS Category_Rank,
    ROUND(AVG(quarterly_revenue) OVER (PARTITION BY category_name ORDER BY year, quarter ROWS BETWEEN 1 PRECEDING AND CURRENT ROW), 2) AS Rolling_Avg_2Q
FROM category_revenue_analysis
ORDER BY year, quarter, Category_Rank;