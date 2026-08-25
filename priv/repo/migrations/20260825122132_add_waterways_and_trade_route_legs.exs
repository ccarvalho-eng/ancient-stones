defmodule AncientStones.Repo.Migrations.AddWaterwaysAndTradeRouteLegs do
  use Ecto.Migration

  def change do
    create table(:water_bodies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :parent_water_body_id, references(:water_bodies, type: :binary_id, on_delete: :restrict)
      add :name, :text, null: false
      add :kind, :text, null: false
      add :salinity, :text, null: false
      add :navigability, :text, null: false
      add :freeze_pattern, :text, null: false
      add :prevailing_conditions, :text
      add :hazards, :text
      add :status, :text, null: false, default: "active"
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:water_bodies, [:world_id, :name])
    create index(:water_bodies, [:parent_water_body_id])

    create constraint(:water_bodies, :water_bodies_not_own_parent,
             check: "parent_water_body_id IS NULL OR parent_water_body_id <> id"
           )

    create constraint(:water_bodies, :water_bodies_kind,
             check:
               "kind IN ('ocean', 'sea', 'shelf_sea', 'gulf', 'bay', 'strait', 'sound', 'fjord', 'river', 'estuary', 'lake', 'channel')"
           )

    create constraint(:water_bodies, :water_bodies_salinity,
             check: "salinity IN ('fresh', 'brackish', 'saline', 'variable')"
           )

    create constraint(:water_bodies, :water_bodies_navigability,
             check:
               "navigability IN ('none', 'small_craft', 'shallow_draft', 'coastal', 'ocean_going')"
           )

    create constraint(:water_bodies, :water_bodies_freeze_pattern,
             check:
               "freeze_pattern IN ('never', 'rare', 'shore_ice', 'seasonal', 'prolonged', 'perennial')"
           )

    create constraint(:water_bodies, :water_bodies_status,
             check: "status IN ('active', 'seasonal', 'restricted', 'historical')"
           )

    create table(:water_body_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :origin_water_body_id,
          references(:water_bodies, type: :binary_id, on_delete: :restrict), null: false

      add :destination_water_body_id,
          references(:water_bodies, type: :binary_id, on_delete: :restrict), null: false

      add :connection_type, :text, null: false
      add :directionality, :text, null: false, default: "one_way"
      add :navigability, :text, null: false
      add :seasonality, :text
      add :distance_km, :decimal
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(
             :water_body_connections,
             [:origin_water_body_id, :destination_water_body_id, :connection_type],
             name: :water_body_connections_directed_link_index
           )

    create index(:water_body_connections, [:destination_water_body_id])

    create constraint(:water_body_connections, :water_body_connections_distinct_endpoints,
             check: "origin_water_body_id <> destination_water_body_id"
           )

    create constraint(:water_body_connections, :water_body_connections_connection_type,
             check:
               "connection_type IN ('flows_into', 'opens_to', 'narrows_to', 'linked_channel', 'tidal_exchange')"
           )

    create constraint(:water_body_connections, :water_body_connections_directionality,
             check: "directionality IN ('one_way', 'two_way')"
           )

    create constraint(:water_body_connections, :water_body_connections_navigability,
             check:
               "navigability IN ('none', 'small_craft', 'shallow_draft', 'coastal', 'ocean_going')"
           )

    create constraint(:water_body_connections, :water_body_connections_seasonality,
             check:
               "seasonality IS NULL OR seasonality IN ('year_round', 'spring_to_autumn', 'summer_only', 'winter_only', 'dry_season', 'wet_season', 'thaw_only', 'intermittent')"
           )

    create constraint(:water_body_connections, :water_body_connections_distance_non_negative,
             check: "distance_km IS NULL OR distance_km >= 0"
           )

    create table(:province_water_bodies, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :province_id, references(:provinces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :water_body_id, references(:water_bodies, type: :binary_id, on_delete: :restrict),
        null: false

      add :relationship, :text, null: false
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(
             :province_water_bodies,
             [:province_id, :water_body_id, :relationship],
             name: :province_water_bodies_unique_link_index
           )

    create index(:province_water_bodies, [:water_body_id])

    create constraint(:province_water_bodies, :province_water_bodies_relationship,
             check: "relationship IN ('coast', 'contains', 'drains_to', 'source', 'border')"
           )

    alter table(:locations) do
      add :water_body_id, references(:water_bodies, type: :binary_id, on_delete: :restrict)
    end

    create index(:locations, [:water_body_id])

    create table(:trade_route_stops, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :trade_route_id, references(:trade_routes, type: :binary_id, on_delete: :delete_all),
        null: false

      add :location_id, references(:locations, type: :binary_id, on_delete: :restrict),
        null: false

      add :position, :integer, null: false
      add :handling_notes, :text
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:trade_route_stops, [:trade_route_id, :position])
    create index(:trade_route_stops, [:location_id])

    create constraint(:trade_route_stops, :trade_route_stops_position_positive,
             check: "position > 0"
           )

    create table(:trade_route_legs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :trade_route_id, references(:trade_routes, type: :binary_id, on_delete: :delete_all),
        null: false

      add :origin_stop_id,
          references(:trade_route_stops, type: :binary_id, on_delete: :delete_all), null: false

      add :destination_stop_id,
          references(:trade_route_stops, type: :binary_id, on_delete: :delete_all), null: false

      add :water_body_id, references(:water_bodies, type: :binary_id, on_delete: :restrict)
      add :position, :integer, null: false
      add :transport_mode, :text, null: false
      add :distance_km, :decimal, null: false
      add :typical_travel_days, :decimal, null: false
      add :seasonality, :text
      add :risk, :text
      add :handling_notes, :text
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:trade_route_legs, [:trade_route_id, :position])
    create index(:trade_route_legs, [:origin_stop_id])
    create index(:trade_route_legs, [:destination_stop_id])
    create index(:trade_route_legs, [:water_body_id])

    create constraint(:trade_route_legs, :trade_route_legs_distinct_stops,
             check: "origin_stop_id <> destination_stop_id"
           )

    create constraint(:trade_route_legs, :trade_route_legs_position_positive,
             check: "position > 0"
           )

    create constraint(:trade_route_legs, :trade_route_legs_distance_non_negative,
             check: "distance_km >= 0"
           )

    create constraint(:trade_route_legs, :trade_route_legs_travel_time_positive,
             check: "typical_travel_days > 0"
           )

    create constraint(:trade_route_legs, :trade_route_legs_transport_mode,
             check: "transport_mode IN ('caravan', 'river', 'sea', 'road', 'trail', 'mixed')"
           )

    create constraint(:trade_route_legs, :trade_route_legs_seasonality,
             check:
               "seasonality IS NULL OR seasonality IN ('year_round', 'spring_to_autumn', 'summer_only', 'winter_only', 'dry_season', 'wet_season', 'thaw_only', 'intermittent')"
           )

    create constraint(:trade_route_legs, :trade_route_legs_risk,
             check: "risk IS NULL OR risk IN ('negligible', 'low', 'moderate', 'high', 'severe')"
           )
  end
end
