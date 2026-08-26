defmodule AncientStones.Repo.Migrations.AddAudrunCredibilitySupport do
  use Ecto.Migration

  def change do
    create constraint(:provinces, :provinces_terrain_enum,
             check:
               "terrain IS NULL OR terrain IN ('coast', 'forest', 'highlands', 'marsh', 'mountain', 'plains', 'riverlands', 'snowfield', 'tundra', 'volcanic', 'wetlands')"
           )

    create constraint(:provinces, :provinces_climate_enum,
             check:
               "climate IS NULL OR climate IN ('arctic', 'coastal', 'cold', 'dry', 'temperate', 'volcanic', 'wet')"
           )

    create constraint(:holds, :holds_terrain_enum,
             check:
               "terrain IS NULL OR terrain IN ('coast', 'forest', 'highlands', 'marsh', 'mountain', 'plains', 'riverlands', 'snowfield', 'tundra', 'volcanic', 'wetlands')"
           )

    create constraint(:holds, :holds_climate_enum,
             check:
               "climate IS NULL OR climate IN ('arctic', 'coastal', 'cold', 'dry', 'temperate', 'volcanic', 'wet')"
           )

    alter table(:locations) do
      add :population_estimate, :bigint
      add :record_scope, :string
    end

    create constraint(:locations, :locations_population_non_negative,
             check: "population_estimate IS NULL OR population_estimate >= 0"
           )

    create constraint(:locations, :locations_record_scope,
             check:
               "record_scope IS NULL OR record_scope IN ('specific', 'representative', 'comprehensive')"
           )

    alter table(:water_bodies) do
      add :latitude, :decimal, precision: 9, scale: 6
      add :longitude, :decimal, precision: 9, scale: 6
      add :source_latitude, :decimal, precision: 9, scale: 6
      add :source_longitude, :decimal, precision: 9, scale: 6
      add :mouth_latitude, :decimal, precision: 9, scale: 6
      add :mouth_longitude, :decimal, precision: 9, scale: 6
      add :length_km, :decimal, precision: 12, scale: 2
      add :area_km2, :decimal, precision: 14, scale: 2
      add :drainage_area_km2, :decimal, precision: 14, scale: 2
      add :source_elevation_m, :integer
      add :mean_discharge_m3_s, :decimal, precision: 12, scale: 2
    end

    create constraint(:water_bodies, :water_bodies_geographic_ranges,
             check:
               "(latitude IS NULL OR latitude BETWEEN -90 AND 90) AND " <>
                 "(longitude IS NULL OR longitude BETWEEN -180 AND 180) AND " <>
                 "(source_latitude IS NULL OR source_latitude BETWEEN -90 AND 90) AND " <>
                 "(source_longitude IS NULL OR source_longitude BETWEEN -180 AND 180) AND " <>
                 "(mouth_latitude IS NULL OR mouth_latitude BETWEEN -90 AND 90) AND " <>
                 "(mouth_longitude IS NULL OR mouth_longitude BETWEEN -180 AND 180)"
           )

    create constraint(:water_bodies, :water_bodies_measurements_positive,
             check:
               "(length_km IS NULL OR length_km > 0) AND " <>
                 "(area_km2 IS NULL OR area_km2 > 0) AND " <>
                 "(drainage_area_km2 IS NULL OR drainage_area_km2 > 0) AND " <>
                 "(source_elevation_m IS NULL OR source_elevation_m >= 0) AND " <>
                 "(mean_discharge_m3_s IS NULL OR mean_discharge_m3_s > 0)"
           )

    create table(:location_gods, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :location_id,
          references(:locations, type: :binary_id, on_delete: :delete_all),
          null: false

      add :god_id, references(:gods, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "primary"
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:location_gods, [:location_id, :god_id])
    create index(:location_gods, [:god_id])

    create constraint(:location_gods, :location_gods_role,
             check: "role IN ('primary', 'associated', 'shared', 'contested', 'historical')"
           )

    alter table(:trade_routes) do
      add :annual_capacity_tonnes, :decimal, precision: 14, scale: 2
      add :capacity_basis, :text
    end

    create constraint(:trade_routes, :trade_routes_capacity_positive,
             check: "annual_capacity_tonnes IS NULL OR annual_capacity_tonnes > 0"
           )

    alter table(:trade_flows) do
      add :unit_mass_kg, :decimal, precision: 12, scale: 3
      add :annual_consignment_count, :integer
    end

    create constraint(:trade_flows, :trade_flows_mass_and_count_positive,
             check:
               "(unit_mass_kg IS NULL OR unit_mass_kg > 0) AND " <>
                 "(annual_consignment_count IS NULL OR annual_consignment_count > 0)"
           )

    alter table(:tax_policies) do
      add :effective_from_year, :integer
      add :effective_to_year, :integer
    end

    create constraint(:tax_policies, :tax_policies_effective_years,
             check:
               "effective_to_year IS NULL OR effective_from_year IS NULL OR " <>
                 "effective_to_year >= effective_from_year"
           )

    alter table(:tax_assessments) do
      add :assessed_unit, :string
      add :assessed_unit_count, :decimal, precision: 14, scale: 2
      add :coverage_percentage, :decimal, precision: 5, scale: 2
      add :valuation_basis, :text
    end

    create constraint(:tax_assessments, :tax_assessments_coverage,
             check:
               "(assessed_unit_count IS NULL OR assessed_unit_count > 0) AND " <>
                 "(coverage_percentage IS NULL OR coverage_percentage BETWEEN 0 AND 100)"
           )

    alter table(:political_offices) do
      add :designated_successor_id,
          references(:characters, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:political_offices, [:designated_successor_id])

    create table(:assemblies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :continent_id, references(:continents, type: :binary_id, on_delete: :delete_all)
      add :province_id, references(:provinces, type: :binary_id, on_delete: :delete_all)
      add :hold_id, references(:holds, type: :binary_id, on_delete: :delete_all)
      add :location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, null: false
      add :scope, :string, null: false
      add :status, :string, null: false, default: "active"
      add :meeting_cycle, :string, null: false
      add :membership_rule, :text, null: false
      add :jurisdiction, :text, null: false
      add :appeal_path, :text
      add :enforcement, :text, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:assemblies, [:world_id, :name])
    create index(:assemblies, [:continent_id])
    create index(:assemblies, [:province_id])
    create index(:assemblies, [:hold_id])
    create index(:assemblies, [:location_id])

    create constraint(:assemblies, :assemblies_scope_target,
             check:
               "(scope = 'continent' AND continent_id IS NOT NULL AND province_id IS NULL AND hold_id IS NULL) OR " <>
                 "(scope = 'province' AND continent_id IS NULL AND province_id IS NOT NULL AND hold_id IS NULL) OR " <>
                 "(scope = 'hold' AND continent_id IS NULL AND province_id IS NULL AND hold_id IS NOT NULL)"
           )

    create constraint(:assemblies, :assemblies_status,
             check: "status IN ('active', 'suspended', 'historical')"
           )

    alter table(:items) do
      add :period_name, :string
      add :date_label, :string
      add :maker, :string
      add :provenance, :text
      add :authenticity, :string
      add :find_location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:items, [:find_location_id])

    create constraint(:items, :items_authenticity,
             check:
               "authenticity IS NULL OR authenticity IN ('working', 'historic', 'reconstructed', 'disputed', 'legendary')"
           )
  end
end
