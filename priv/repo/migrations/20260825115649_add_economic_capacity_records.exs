defmodule AncientStones.Repo.Migrations.AddEconomicCapacityRecords do
  use Ecto.Migration

  def change do
    create table(:hold_economic_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :hold_id, references(:holds, type: :binary_id, on_delete: :delete_all), null: false
      add :population_estimate, :bigint, null: false
      add :household_estimate, :bigint, null: false
      add :urban_population_estimate, :bigint, null: false, default: 0
      add :arable_hectares_estimate, :decimal
      add :pasture_hectares_estimate, :decimal
      add :staple_reserve_months, :decimal
      add :assessment_label, :text, null: false
      add :confidence, :text, null: false, default: "medium"
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:hold_economic_profiles, [:hold_id])

    create constraint(:hold_economic_profiles, :hold_economic_profiles_population_non_negative,
             check: "population_estimate >= 0"
           )

    create constraint(:hold_economic_profiles, :hold_economic_profiles_households_non_negative,
             check: "household_estimate >= 0"
           )

    create constraint(:hold_economic_profiles, :hold_economic_profiles_urban_non_negative,
             check: "urban_population_estimate >= 0"
           )

    create constraint(:hold_economic_profiles, :hold_economic_profiles_urban_within_population,
             check: "urban_population_estimate <= population_estimate"
           )

    create constraint(:hold_economic_profiles, :hold_economic_profiles_land_non_negative,
             check:
               "(arable_hectares_estimate IS NULL OR arable_hectares_estimate >= 0) AND (pasture_hectares_estimate IS NULL OR pasture_hectares_estimate >= 0)"
           )

    create constraint(:hold_economic_profiles, :hold_economic_profiles_reserves_non_negative,
             check: "staple_reserve_months IS NULL OR staple_reserve_months >= 0"
           )

    create constraint(:hold_economic_profiles, :hold_economic_profiles_confidence,
             check: "confidence IN ('low', 'medium', 'high')"
           )

    create table(:commodity_balances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :hold_id, references(:holds, type: :binary_id, on_delete: :delete_all), null: false
      add :commodity, :text, null: false
      add :category, :text
      add :unit, :text, null: false
      add :annual_output, :decimal, null: false
      add :annual_local_need, :decimal, null: false
      add :stored_reserve, :decimal, null: false, default: 0
      add :bad_year_output_percentage, :decimal, null: false
      add :storage_loss_percentage, :decimal, null: false, default: 0
      add :status, :text, null: false, default: "active"
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:commodity_balances, [:hold_id, :commodity, :unit])

    create constraint(:commodity_balances, :commodity_balances_amounts_non_negative,
             check: "annual_output >= 0 AND annual_local_need >= 0 AND stored_reserve >= 0"
           )

    create constraint(:commodity_balances, :commodity_balances_bad_year_percentage,
             check: "bad_year_output_percentage >= 0 AND bad_year_output_percentage <= 100"
           )

    create constraint(:commodity_balances, :commodity_balances_storage_loss_percentage,
             check: "storage_loss_percentage >= 0 AND storage_loss_percentage <= 100"
           )

    create constraint(:commodity_balances, :commodity_balances_status,
             check: "status IN ('active', 'provisional', 'historical')"
           )

    create table(:tax_assessments, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tax_policy_id,
          references(:tax_policies, type: :binary_id, on_delete: :delete_all),
          null: false

      add :currency_id,
          references(:continent_currencies, type: :binary_id, on_delete: :restrict),
          null: false

      add :assessment_period_label, :text, null: false
      add :cash_yield, :decimal, null: false, default: 0
      add :in_kind_value, :decimal, null: false, default: 0
      add :customary_labor_days, :bigint, null: false, default: 0
      add :confidence, :text, null: false, default: "medium"
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:tax_assessments, [:tax_policy_id, :assessment_period_label])
    create index(:tax_assessments, [:currency_id])

    create constraint(:tax_assessments, :tax_assessments_values_non_negative,
             check: "cash_yield >= 0 AND in_kind_value >= 0 AND customary_labor_days >= 0"
           )

    create constraint(:tax_assessments, :tax_assessments_confidence,
             check: "confidence IN ('low', 'medium', 'high')"
           )

    alter table(:trade_flows) do
      add :coverage_scope, :text
      add :quantity_basis, :text
    end

    create constraint(:trade_flows, :trade_flows_coverage_scope,
             check:
               "coverage_scope IS NULL OR coverage_scope IN ('representative_consignment', 'minimum_recorded', 'estimated_total')"
           )

    alter table(:hold_commerce_entries) do
      add :accounting_scope, :text
      add :coverage_scope, :text
    end

    create constraint(:hold_commerce_entries, :hold_commerce_entries_accounting_scope,
             check:
               "accounting_scope IS NULL OR accounting_scope IN ('gross_output', 'net_local_income', 'treasury_revenue', 'treasury_outlay', 'asset_value', 'liability')"
           )

    create constraint(:hold_commerce_entries, :hold_commerce_entries_coverage_scope,
             check:
               "coverage_scope IS NULL OR coverage_scope IN ('named_establishment', 'partial_register', 'estimated_total')"
           )
  end
end
