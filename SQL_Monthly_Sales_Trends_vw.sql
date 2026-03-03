CREATE VIEW vw_monthly_sales_trends AS
SELECT
    EXTRACT(YEAR FROM o.order_date) AS Year,
    EXTRACT(MONTH FROM o.order_date) AS Month,
    SUM(oi.quantity * oi.unit_price) AS Monthly_Revenue,
    
    ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('year', o.order_date) 
        ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS Month_Rank_In_Year,
    
    LAG(SUM(oi.quantity * oi.unit_price)) OVER (
        ORDER BY DATE_TRUNC('month', o.order_date)) AS Previous_Month_Revenue,
    
    LAG(SUM(oi.quantity * oi.unit_price), 12) OVER (
        ORDER BY DATE_TRUNC('month', o.order_date)) AS Same_Month_Last_Year_Revenue,
    
    ROUND(((SUM(oi.quantity * oi.unit_price) - LAG(SUM(oi.quantity * oi.unit_price)) OVER (ORDER BY DATE_TRUNC('month', o.order_date)))
        / NULLIF(LAG(SUM(oi.quantity * oi.unit_price)) OVER (ORDER BY DATE_TRUNC('month', o.order_date)), 0)) * 100, 2) AS MoM_Change_Pct,
    
    ROUND(((SUM(oi.quantity * oi.unit_price) - LAG(SUM(oi.quantity * oi.unit_price), 12) OVER (ORDER BY DATE_TRUNC('month', o.order_date)))
        / NULLIF(LAG(SUM(oi.quantity * oi.unit_price), 12) OVER (ORDER BY DATE_TRUNC('month', o.order_date)), 0)) * 100, 2) AS YoY_Change_Pct,
    
    ROUND(AVG(SUM(oi.quantity * oi.unit_price)) OVER (
        ORDER BY DATE_TRUNC('month', o.order_date) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS Rolling_Avg_3_Months

FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 
    DATE_TRUNC('year', o.order_date), 
    DATE_TRUNC('month', o.order_date), 
    EXTRACT(YEAR FROM o.order_date), 
    EXTRACT(MONTH FROM o.order_date)
ORDER BY 
    EXTRACT(YEAR FROM o.order_date), 
    EXTRACT(MONTH FROM o.order_date);
