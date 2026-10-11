-- Import danych do Wind Turbine DB. Uruchom po schema.sql. Zmien /ABSOLUTNA/SCIEZKA/ na realna sciezke do katalogu z CSV.

\copy customers(customer_id,customer_name,country,contract_type,created_at) FROM '/ABSOLUTNA/SCIEZKA/customers.csv' WITH (FORMAT csv, HEADER true);
\copy wind_farms(farm_id,farm_name,customer_id,country,region,commissioning_date) FROM '/ABSOLUTNA/SCIEZKA/wind_farms.csv' WITH (FORMAT csv, HEADER true);
\copy turbines(turbine_id,serial_no,farm_id,model,rated_power_kw,hub_height_m,manufacture_date,install_date,status) FROM '/ABSOLUTNA/SCIEZKA/turbines.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy component_types(component_type_id,component_name,parent_type_id,category,standard_cost) FROM '/ABSOLUTNA/SCIEZKA/component_types.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy work_centers(work_center_id,wc_name,capacity_hours_per_week,hourly_rate) FROM '/ABSOLUTNA/SCIEZKA/work_centers.csv' WITH (FORMAT csv, HEADER true);
\copy production_orders(order_id,turbine_id,work_center_id,operation,planned_hours,actual_hours,planned_start,actual_start,planned_end,actual_end,status) FROM '/ABSOLUTNA/SCIEZKA/production_orders.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy service_events(event_id,turbine_id,event_type,severity,reported_date,resolved_date,downtime_hours,component_type_id,cost) FROM '/ABSOLUTNA/SCIEZKA/service_events.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy spare_parts_orders(sp_order_id,event_id,component_type_id,disposition,quantity,unit_cost,lead_time_days,order_date,received_date) FROM '/ABSOLUTNA/SCIEZKA/spare_parts_orders.csv' WITH (FORMAT csv, HEADER true, NULL '');

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
