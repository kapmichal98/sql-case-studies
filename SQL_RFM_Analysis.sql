WITH rfm_data AS (
    SELECT
        o.customer_id,
        EXTRACT(DAY FROM CURRENT_DATE - MAX(o.order_date)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS orders_count,
        ROUND(
            EXTRACT(DAY FROM MAX(o.order_date) - MIN(o.order_date))::NUMERIC
            / NULLIF(COUNT(DISTINCT o.order_id) - 1, 0),
        2) AS frequency_avg,
        SUM(oi.quantity * oi.unit_price) AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
    HAVING COUNT(DISTINCT o.order_id) > 1
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        orders_count,
        frequency_avg,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency_avg DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_data
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    rs.recency_days,
    rs.orders_count,
    rs.frequency_avg,
    rs.monetary,
    rs.r_score,
    rs.f_score,
    rs.m_score,
    rs.r_score + rs.f_score + rs.m_score AS rfm_score,
    CASE
        WHEN rs.r_score + rs.f_score + rs.m_score >= 13 THEN 'Champions'
        WHEN rs.r_score + rs.f_score + rs.m_score >= 10 THEN 'Loyal Customers'
        WHEN rs.r_score + rs.f_score + rs.m_score >= 7 THEN 'Potential Loyalists'
        WHEN rs.r_score + rs.f_score + rs.m_score >= 4 THEN 'At Risk'
        ELSE 'Lost'
    END AS rfm_segment
FROM rfm_scores rs
JOIN customers c ON rs.customer_id = c.customer_id
ORDER BY rfm_score DESC, c.customer_id;