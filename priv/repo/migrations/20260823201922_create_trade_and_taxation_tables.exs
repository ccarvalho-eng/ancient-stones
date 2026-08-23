defmodule AncientStones.Repo.Migrations.CreateTradeAndTaxationTables do
  use Ecto.Migration

  def change do
    create table(:trade_routes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false

      add :origin_hold_id, references(:holds, type: :binary_id, on_delete: :delete_all),
        null: false

      add :destination_hold_id, references(:holds, type: :binary_id, on_delete: :delete_all),
        null: false

      add :origin_location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)

      add :destination_location_id,
          references(:locations, type: :binary_id, on_delete: :nilify_all)

      add :name, :text, null: false
      add :transport_mode, :text, null: false
      add :distance_km, :decimal
      add :seasonality, :text
      add :risk, :text
      add :status, :text, null: false, default: "active"
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:trade_routes, [:world_id, :name])
    create index(:trade_routes, [:origin_hold_id])
    create index(:trade_routes, [:destination_hold_id])

    create constraint(:trade_routes, :trade_routes_distinct_holds,
             check: "origin_hold_id <> destination_hold_id"
           )

    create constraint(:trade_routes, :trade_routes_distance_non_negative,
             check: "distance_km IS NULL OR distance_km >= 0"
           )

    create constraint(:trade_routes, :trade_routes_seasonality,
             check:
               "seasonality IS NULL OR seasonality IN ('year_round', 'spring_to_autumn', 'summer_only', 'winter_only', 'dry_season', 'wet_season', 'thaw_only', 'intermittent')"
           )

    create constraint(:trade_routes, :trade_routes_risk,
             check: "risk IS NULL OR risk IN ('negligible', 'low', 'moderate', 'high', 'severe')"
           )

    create constraint(:trade_routes, :trade_routes_transport_mode,
             check: "transport_mode IN ('caravan', 'river', 'sea', 'road', 'trail', 'mixed')"
           )

    create constraint(:trade_routes, :trade_routes_status,
             check: "status IN ('active', 'seasonal', 'suspended', 'abandoned')"
           )

    create table(:trade_flows, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :trade_route_id, references(:trade_routes, type: :binary_id, on_delete: :delete_all),
        null: false

      add :currency_id,
          references(:continent_currencies, type: :binary_id, on_delete: :nilify_all)

      add :commodity, :text, null: false
      add :category, :text
      add :quantity, :decimal, null: false
      add :unit, :text, null: false
      add :declared_value, :decimal, null: false
      add :frequency, :text, null: false, default: "annual"
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:trade_flows, [:trade_route_id, :commodity])
    create index(:trade_flows, [:currency_id])
    create constraint(:trade_flows, :trade_flows_quantity_positive, check: "quantity > 0")

    create constraint(:trade_flows, :trade_flows_declared_value_non_negative,
             check: "declared_value >= 0"
           )

    create constraint(:trade_flows, :trade_flows_frequency,
             check: "frequency IN ('daily', 'weekly', 'monthly', 'seasonal', 'annual')"
           )

    create table(:tax_policies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :continent_id, references(:continents, type: :binary_id, on_delete: :delete_all)
      add :province_id, references(:provinces, type: :binary_id, on_delete: :delete_all)
      add :hold_id, references(:holds, type: :binary_id, on_delete: :delete_all)

      add :collecting_office_id,
          references(:political_offices, type: :binary_id, on_delete: :nilify_all)

      add :currency_id,
          references(:continent_currencies, type: :binary_id, on_delete: :nilify_all)

      add :name, :text, null: false
      add :tax_type, :text, null: false
      add :rate_basis, :text, null: false
      add :rate, :decimal, null: false
      add :commodity, :text
      add :category, :text
      add :direction, :text, null: false, default: "any"
      add :effective_from, :date
      add :effective_to, :date
      add :status, :text, null: false, default: "active"
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:tax_policies, [:world_id, :name])
    create index(:tax_policies, [:continent_id])
    create index(:tax_policies, [:province_id])
    create index(:tax_policies, [:hold_id])
    create index(:tax_policies, [:collecting_office_id])
    create index(:tax_policies, [:currency_id])
    create index(:tax_policies, [:world_id, :status])

    create constraint(:tax_policies, :tax_policies_single_jurisdiction,
             check: "num_nonnulls(continent_id, province_id, hold_id) = 1"
           )

    create constraint(:tax_policies, :tax_policies_rate_non_negative, check: "rate >= 0")

    create constraint(:tax_policies, :tax_policies_percentage_rate,
             check: "rate_basis <> 'percentage' OR rate <= 100"
           )

    create constraint(:tax_policies, :tax_policies_effective_dates,
             check:
               "effective_from IS NULL OR effective_to IS NULL OR effective_to >= effective_from"
           )

    create constraint(:tax_policies, :tax_policies_tax_type,
             check:
               "tax_type IN ('import_tariff', 'export_duty', 'road_toll', 'harbor_due', 'market_fee', 'land_levy', 'tribute', 'excise')"
           )

    create constraint(:tax_policies, :tax_policies_rate_basis,
             check: "rate_basis IN ('percentage', 'per_unit', 'fixed')"
           )

    create constraint(:tax_policies, :tax_policies_direction,
             check: "direction IN ('any', 'import', 'export', 'internal')"
           )

    create constraint(:tax_policies, :tax_policies_status,
             check: "status IN ('draft', 'active', 'retired')"
           )

    create table(:tax_exemptions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tax_policy_id, references(:tax_policies, type: :binary_id, on_delete: :delete_all),
        null: false

      add :guild_id, references(:guilds, type: :binary_id, on_delete: :delete_all)
      add :trade_route_id, references(:trade_routes, type: :binary_id, on_delete: :delete_all)
      add :continent_id, references(:continents, type: :binary_id, on_delete: :delete_all)
      add :province_id, references(:provinces, type: :binary_id, on_delete: :delete_all)
      add :hold_id, references(:holds, type: :binary_id, on_delete: :delete_all)
      add :name, :text, null: false
      add :exemption_percentage, :decimal, null: false, default: 100
      add :effective_from, :date
      add :effective_to, :date
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:tax_exemptions, [:tax_policy_id, :name])
    create index(:tax_exemptions, [:guild_id])
    create index(:tax_exemptions, [:trade_route_id])
    create index(:tax_exemptions, [:continent_id])
    create index(:tax_exemptions, [:province_id])
    create index(:tax_exemptions, [:hold_id])

    create constraint(:tax_exemptions, :tax_exemptions_single_beneficiary,
             check:
               "num_nonnulls(guild_id, trade_route_id, continent_id, province_id, hold_id) = 1"
           )

    create constraint(:tax_exemptions, :tax_exemptions_percentage,
             check: "exemption_percentage >= 0 AND exemption_percentage <= 100"
           )

    create constraint(:tax_exemptions, :tax_exemptions_effective_dates,
             check:
               "effective_from IS NULL OR effective_to IS NULL OR effective_to >= effective_from"
           )

    create table(:tax_revenue_shares, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tax_policy_id, references(:tax_policies, type: :binary_id, on_delete: :delete_all),
        null: false

      add :political_office_id,
          references(:political_offices, type: :binary_id, on_delete: :delete_all),
          null: false

      add :percentage, :decimal, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:tax_revenue_shares, [:tax_policy_id, :political_office_id])
    create index(:tax_revenue_shares, [:political_office_id])

    create constraint(:tax_revenue_shares, :tax_revenue_shares_percentage,
             check: "percentage > 0 AND percentage <= 100"
           )
  end
end
