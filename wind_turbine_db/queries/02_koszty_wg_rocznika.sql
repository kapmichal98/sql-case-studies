-- Top 500 turbin wg kosztu serwisu - rozkład wg rocznika produkcji
WITH services_cost AS (
    SELECT turbine_id, SUM(cost) AS total_service_cost
    FROM service_events
    GROUP BY turbine_id
    ORDER BY SUM(cost) DESC
    LIMIT 500
)
SELECT EXTRACT(YEAR FROM t.manufacture_date) AS rok_produkcji,
       COUNT(*) AS liczba_w_top500
FROM turbines t
JOIN services_cost sc ON t.turbine_id = sc.turbine_id
GROUP BY EXTRACT(YEAR FROM t.manufacture_date)
ORDER BY liczba_w_top500 DESC;
