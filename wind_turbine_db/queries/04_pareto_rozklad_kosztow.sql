-- Rozkład kosztów wg turbiny + skumulowany udział procentowy (Pareto)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_cost DESC) AS rn,
    turbine_id,
    total_cost,
    ROUND(100.0 * total_cost / SUM(total_cost) OVER (), 4) AS prct_share,
    ROUND(100.0 * SUM(total_cost) OVER (ORDER BY total_cost DESC)
                / SUM(total_cost) OVER (), 2) AS cumulative_prct
FROM (
    SELECT turbine_id, SUM(cost) AS total_cost
    FROM service_events
    GROUP BY turbine_id
) x
ORDER BY total_cost DESC;
