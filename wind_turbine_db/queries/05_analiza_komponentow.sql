-- Koszt wg typu komponentu: liczba zdarzeń, koszt łączny, udział %, koszt na zdarzenie
SELECT
    ct.component_name,
    COUNT(se.event_id)                                        AS liczba_zdarzen,
    SUM(se.cost)                                              AS koszt_laczny,
    ROUND(SUM(se.cost) * 100.0 / SUM(SUM(se.cost)) OVER (), 2) AS udzial_proc,
    ROUND(SUM(se.cost) / COUNT(*), 2)                         AS koszt_na_zdarzenie
FROM service_events se
JOIN component_types ct ON se.component_type_id = ct.component_type_id
GROUP BY ct.component_name
ORDER BY koszt_laczny DESC;
