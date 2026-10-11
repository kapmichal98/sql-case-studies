-- Import danych - wersja pod pgAdmin (Query Tool). Uruchom po schema.sql.
-- COPY dziala po stronie serwera (dziala w pgAdmin). \copy dziala po stronie klienta (tylko psql) - patrz import_data.sql.
-- Pliki CSV umiesc w folderze czytelnym dla serwera, np. C:/wind_turbine_db/ (w sciezkach uzywaj ukosnikow "/").

COPY customers(customer_id,customer_name,country,contract_type,created_at)
  FROM 'C:/wind_turbine_db/customers.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

COPY wind_farms(farm_id,farm_name,customer_id,country,region,commissioning_date)
  FROM 'C:/wind_turbine_db/wind_farms.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

COPY turbines(turbine_id,serial_no,farm_id,model,rated_power_kw,hub_height_m,manufacture_date,install_date,status)
  FROM 'C:/wind_turbine_db/turbines.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

COPY component_types(component_type_id,component_name,parent_type_id,category,standard_cost)
  FROM 'C:/wind_turbine_db/component_types.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

COPY work_centers(work_center_id,wc_name,capacity_hours_per_week,hourly_rate)
  FROM 'C:/wind_turbine_db/work_centers.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

COPY production_orders(order_id,turbine_id,work_center_id,operation,planned_hours,actual_hours,planned_start,actual_start,planned_end,actual_end,status)
  FROM 'C:/wind_turbine_db/production_orders.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

COPY service_events(event_id,turbine_id,event_type,severity,reported_date,resolved_date,downtime_hours,component_type_id,cost)
  FROM 'C:/wind_turbine_db/service_events.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

COPY spare_parts_orders(sp_order_id,event_id,component_type_id,disposition,quantity,unit_cost,lead_time_days,order_date,received_date)
  FROM 'C:/wind_turbine_db/spare_parts_orders.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');

-- Reset sekwencji SERIAL po recznym zaladowaniu ID
SELECT setval('customers_customer_id_seq', (SELECT MAX(customer_id) FROM customers));
SELECT setval('wind_farms_farm_id_seq', (SELECT MAX(farm_id) FROM wind_farms));
SELECT setval('turbines_turbine_id_seq', (SELECT MAX(turbine_id) FROM turbines));
SELECT setval('component_types_component_type_id_seq', (SELECT MAX(component_type_id) FROM component_types));
SELECT setval('work_centers_work_center_id_seq', (SELECT MAX(work_center_id) FROM work_centers));
SELECT setval('production_orders_order_id_seq', (SELECT MAX(order_id) FROM production_orders));
SELECT setval('service_events_event_id_seq', (SELECT MAX(event_id) FROM service_events));
SELECT setval('spare_parts_orders_sp_order_id_seq', (SELECT MAX(sp_order_id) FROM spare_parts_orders));

-- Weryfikacja importu
SELECT 'customers' AS tabela, COUNT(*) FROM customers
UNION ALL SELECT 'wind_farms', COUNT(*) FROM wind_farms
UNION ALL SELECT 'turbines', COUNT(*) FROM turbines
UNION ALL SELECT 'component_types', COUNT(*) FROM component_types
UNION ALL SELECT 'work_centers', COUNT(*) FROM work_centers
UNION ALL SELECT 'production_orders', COUNT(*) FROM production_orders
UNION ALL SELECT 'service_events', COUNT(*) FROM service_events
UNION ALL SELECT 'spare_parts_orders', COUNT(*) FROM spare_parts_orders;
