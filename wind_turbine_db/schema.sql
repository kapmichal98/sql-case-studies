-- Wind Turbine Manufacturing & O&M - schemat (PostgreSQL)
-- Domena: produkcja turbin wiatrowych (job-shop) + serwis w polu (O&M). Dane syntetyczne.

DROP TABLE IF EXISTS spare_parts_orders CASCADE;
DROP TABLE IF EXISTS service_events      CASCADE;
DROP TABLE IF EXISTS production_orders   CASCADE;
DROP TABLE IF EXISTS work_centers        CASCADE;
DROP TABLE IF EXISTS component_types     CASCADE;
DROP TABLE IF EXISTS turbines            CASCADE;
DROP TABLE IF EXISTS wind_farms          CASCADE;
DROP TABLE IF EXISTS customers           CASCADE;

-- ---------------------------------------------------------------------
-- 1. CUSTOMERS — operatorzy / wlasciciele farm
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id    SERIAL PRIMARY KEY,
    customer_name  VARCHAR(80)  NOT NULL,
    country        CHAR(2)      NOT NULL,
    contract_type  VARCHAR(20)  NOT NULL
                   CHECK (contract_type IN ('Full-Service','Warranty','Spot')),
    created_at     DATE         NOT NULL
);
COMMENT ON TABLE  customers IS 'Klienci: operatorzy i wlasciciele farm wiatrowych.';
COMMENT ON COLUMN customers.contract_type IS 'Typ kontraktu serwisowego.';

-- ---------------------------------------------------------------------
-- 2. WIND_FARMS
-- ---------------------------------------------------------------------
CREATE TABLE wind_farms (
    farm_id             SERIAL PRIMARY KEY,
    farm_name           VARCHAR(80) NOT NULL,
    customer_id         INT NOT NULL REFERENCES customers(customer_id),
    country             CHAR(2)     NOT NULL,
    region              VARCHAR(40),
    commissioning_date  DATE
);
COMMENT ON TABLE wind_farms IS 'Farmy wiatrowe nalezace do klientow.';

-- ---------------------------------------------------------------------
-- 3. TURBINES — aktywo (kazda turbina to osobny "przypadek")
-- ---------------------------------------------------------------------
CREATE TABLE turbines (
    turbine_id        SERIAL PRIMARY KEY,
    serial_no         VARCHAR(20) NOT NULL UNIQUE,
    farm_id           INT NOT NULL REFERENCES wind_farms(farm_id),
    model             VARCHAR(10) NOT NULL,
    rated_power_kw    INT         NOT NULL CHECK (rated_power_kw > 0),
    hub_height_m      INT,
    manufacture_date  DATE        NOT NULL,
    install_date      DATE,                         -- NULL = wciaz w produkcji
    status            VARCHAR(20) NOT NULL
                      CHECK (status IN ('In Production','Operational','In Service','Decommissioned'))
);
COMMENT ON TABLE  turbines IS 'Turbiny jako aktywa; install_date IS NULL => w produkcji.';
COMMENT ON COLUMN turbines.status IS 'Cykl zycia turbiny.';

-- ---------------------------------------------------------------------
-- 4. COMPONENT_TYPES — hierarchia BOM (samoreferencja -> recursive CTE)
-- ---------------------------------------------------------------------
CREATE TABLE component_types (
    component_type_id  SERIAL PRIMARY KEY,
    component_name     VARCHAR(60) NOT NULL,
    parent_type_id     INT REFERENCES component_types(component_type_id),  -- NULL = korzen
    category           VARCHAR(20) NOT NULL
                       CHECK (category IN ('Assembly','Module','Part')),
    standard_cost      NUMERIC(12,2) NOT NULL DEFAULT 0
);
COMMENT ON TABLE  component_types IS 'Struktura wyrobu (BOM). parent_type_id buduje drzewo.';
COMMENT ON COLUMN component_types.parent_type_id IS 'Rodzic w hierarchii; NULL dla korzenia.';

-- ---------------------------------------------------------------------
-- 5. WORK_CENTERS — stanowiska produkcyjne
-- ---------------------------------------------------------------------
CREATE TABLE work_centers (
    work_center_id           SERIAL PRIMARY KEY,
    wc_name                  VARCHAR(40) NOT NULL,
    capacity_hours_per_week  INT NOT NULL CHECK (capacity_hours_per_week > 0),
    hourly_rate              NUMERIC(8,2) NOT NULL
);
COMMENT ON TABLE work_centers IS 'Stanowiska/gniazda produkcyjne z tygodniowa zdolnoscia.';

-- ---------------------------------------------------------------------
-- 6. PRODUCTION_ORDERS — operacje (routing) per turbina
-- ---------------------------------------------------------------------
CREATE TABLE production_orders (
    order_id        SERIAL PRIMARY KEY,
    turbine_id      INT NOT NULL REFERENCES turbines(turbine_id),
    work_center_id  INT NOT NULL REFERENCES work_centers(work_center_id),
    operation       VARCHAR(60) NOT NULL,
    planned_hours   NUMERIC(7,1) NOT NULL,
    actual_hours    NUMERIC(7,1),                 -- NULL dopoki nieukonczone
    planned_start   DATE,
    actual_start    DATE,
    planned_end     DATE,
    actual_end      DATE,
    status          VARCHAR(15) NOT NULL
                    CHECK (status IN ('Planned','In Progress','Completed','On Hold'))
);
COMMENT ON TABLE production_orders IS 'Zlecenia/operacje montazu; planowane vs faktyczne.';

-- ---------------------------------------------------------------------
-- 7. SERVICE_EVENTS — zdarzenia serwisowe O&M w polu
-- ---------------------------------------------------------------------
CREATE TABLE service_events (
    event_id           SERIAL PRIMARY KEY,
    turbine_id         INT NOT NULL REFERENCES turbines(turbine_id),
    event_type         VARCHAR(25) NOT NULL
                       CHECK (event_type IN ('Scheduled Maintenance','Fault','Inspection','Upgrade')),
    severity           VARCHAR(10) NOT NULL
                       CHECK (severity IN ('Low','Medium','High','Critical')),
    reported_date      DATE NOT NULL,
    resolved_date      DATE,
    downtime_hours     INT  NOT NULL CHECK (downtime_hours >= 0),
    component_type_id  INT REFERENCES component_types(component_type_id),
    cost               NUMERIC(12,2) NOT NULL DEFAULT 0
);
COMMENT ON TABLE service_events IS 'Serwis w polu; downtime i koszty do analizy dostepnosci.';

-- ---------------------------------------------------------------------
-- 8. SPARE_PARTS_ORDERS — zamowienia czesci (planowanie materialowe)
-- ---------------------------------------------------------------------
CREATE TABLE spare_parts_orders (
    sp_order_id        SERIAL PRIMARY KEY,
    event_id           INT NOT NULL REFERENCES service_events(event_id),
    component_type_id  INT NOT NULL REFERENCES component_types(component_type_id),
    disposition        VARCHAR(10) NOT NULL
                       CHECK (disposition IN ('Reuse','Repair','Scrap','New')),
    quantity           INT NOT NULL CHECK (quantity > 0),
    unit_cost          NUMERIC(12,2) NOT NULL DEFAULT 0,
    lead_time_days     INT NOT NULL CHECK (lead_time_days >= 0),
    order_date         DATE NOT NULL,
    received_date      DATE
);
COMMENT ON TABLE spare_parts_orders IS 'Dyspozycje i zamowienia czesci pod serwis.';

-- Indeksy pod typowe filtry i JOIN-y
CREATE INDEX idx_turbines_farm          ON turbines(farm_id);
CREATE INDEX idx_turbines_status        ON turbines(status);
CREATE INDEX idx_farms_customer         ON wind_farms(customer_id);
CREATE INDEX idx_comp_parent            ON component_types(parent_type_id);
CREATE INDEX idx_prod_turbine           ON production_orders(turbine_id);
CREATE INDEX idx_prod_wc                ON production_orders(work_center_id);
CREATE INDEX idx_service_turbine        ON service_events(turbine_id);
CREATE INDEX idx_service_reported       ON service_events(reported_date);
CREATE INDEX idx_sp_event              ON spare_parts_orders(event_id);
CREATE INDEX idx_sp_component          ON spare_parts_orders(component_type_id);
