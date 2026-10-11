-- Top 500 turbin wg kosztu serwisu - rozkład wg modelu
WITH services_cost AS (
    SELECT turbine_id, SUM(cost) AS total_service_cost
    FROM service_events
    GROUP BY turbine_id
    ORDER BY SUM(cost) DESC
    LIMIT 500
)
SELECT t.model, COUNT(*) AS model_qty
FROM turbines t
JOIN services_cost sc ON t.turbine_id = sc.turbine_id
GROUP BY t.model
ORDER BY model_qty DESC;
