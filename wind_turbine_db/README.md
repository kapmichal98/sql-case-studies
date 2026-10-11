# Wind Turbine Manufacturing & O&M — SQL Analytics

Projekt analityczny SQL na syntetycznej bazie symulującej producenta turbin
wiatrowych: produkcję (montaż job-shop, każda turbina to osobny przypadek) oraz
serwis O&M w polu (awarie, przeglądy, dostępność, koszty, części zamienne).

Dane są w pełni fikcyjne — nazwy, numery seryjne, daty, koszty i zdarzenia zostały
wygenerowane losowo. Baza nie odwzorowuje żadnej realnej firmy.

Stack: PostgreSQL.

## Schemat bazy (ERD)

```mermaid
erDiagram
    customers ||--o{ wind_farms : "posiada"
    wind_farms ||--o{ turbines : "zawiera"
    turbines ||--o{ production_orders : "ma operacje"
    work_centers ||--o{ production_orders : "realizuje"
    turbines ||--o{ service_events : "generuje"
    component_types ||--o{ service_events : "dotyczy"
    component_types ||--o{ component_types : "parent (BOM)"
    service_events ||--o{ spare_parts_orders : "wyzwala"
    component_types ||--o{ spare_parts_orders : "identyfikuje"

    customers {
        int customer_id PK
        varchar customer_name
        char country
        varchar contract_type
        date created_at
    }
    wind_farms {
        int farm_id PK
        int customer_id FK
        varchar farm_name
        varchar region
        date commissioning_date
    }
    turbines {
        int turbine_id PK
        varchar serial_no UK
        int farm_id FK
        varchar model
        int rated_power_kw
        date manufacture_date
        date install_date
        varchar status
    }
    component_types {
        int component_type_id PK
        int parent_type_id FK
        varchar component_name
        varchar category
        numeric standard_cost
    }
    work_centers {
        int work_center_id PK
        varchar wc_name
        int capacity_hours_per_week
        numeric hourly_rate
    }
    production_orders {
        int order_id PK
        int turbine_id FK
        int work_center_id FK
        varchar operation
        numeric planned_hours
        numeric actual_hours
        varchar status
    }
    service_events {
        int event_id PK
        int turbine_id FK
        int component_type_id FK
        varchar event_type
        varchar severity
        int downtime_hours
        numeric cost
    }
    spare_parts_orders {
        int sp_order_id PK
        int event_id FK
        int component_type_id FK
        varchar disposition
        int quantity
        int lead_time_days
    }
```

## Tabele

| Tabela | Opis | Wierszy |
|---|---|---|
| `customers` | Operatorzy / właściciele farm | 60 |
| `wind_farms` | Farmy wiatrowe | 250 |
| `turbines` | Turbiny jako aktywa (cykl życia) | 8 000 |
| `component_types` | Struktura wyrobu BOM (samoreferencja, 4 poziomy) | 45 |
| `work_centers` | Stanowiska produkcyjne + zdolność | 16 |
| `production_orders` | Operacje montażu: plan vs wykonanie | 64 000 |
| `service_events` | Serwis O&M: downtime, koszty (2013–2025) | 287 446 |
| `spare_parts_orders` | Dyspozycje i zamówienia części | 186 934 |

Łącznie ~0,55 mln wierszy.

## Jak uruchomić

```bash
# 1. utwórz bazę
createdb wind_turbine_db

# 2. schemat
psql -d wind_turbine_db -f schema.sql

# 3. dane — najpierw podmień /ABSOLUTNA/SCIEZKA/ na ścieżkę do katalogu z CSV
psql -d wind_turbine_db -f import_data.sql
```

W pgAdmin użyj `import_data_pgadmin.sql` (polecenie `COPY` zamiast `\copy`).

## Analizy

Katalog `queries/` — śledztwo kosztowe floty: które turbiny i komponenty generują
koszty serwisu i gdzie szukać oszczędności (CTE, funkcje okienkowe, normalizacja).
