-- Średni koszt na rok pracy turbiny wg modelu (normalizacja przez wiek)
WITH turbine_age AS (
    SELECT t.turbine_id, t.model,
           (CURRENT_DATE - t.install_date) / 365.0 AS years
    FROM turbines t
    WHERE t.status <> 'In Production'
),
total_cost_per_turbine AS (
    SELECT turbine_id, SUM(cost) AS total_cost
    FROM service_events
    GROUP BY turbine_id
),
year_cost_per_turbine AS (
    SELECT ta.model,
           COALESCE(tc.total_cost, 0) / ta.years AS cost_per_year
    FROM turbine_age ta
    LEFT JOIN total_cost_per_turbine tc ON ta.turbine_id = tc.turbine_id
)
SELECT model, ROUND(AVG(cost_per_year), 2) AS avg_cost_per_year
FROM year_cost_per_turbine
GROUP BY model
ORDER BY avg_cost_per_year DESC;
