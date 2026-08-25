defmodule AncientStones.Repo.Migrations.AddCommercialVentures do
  use Ecto.Migration

  def change do
    create table(:commercial_ventures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false

      add :home_location_id,
          references(:locations, type: :binary_id, on_delete: :nilify_all)

      add :name, :text, null: false
      add :venture_type, :text, null: false
      add :status, :text, null: false, default: "active"
      add :purpose, :text, null: false
      add :capital_basis, :text
      add :formation_label, :text
      add :end_label, :text
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:commercial_ventures, [:world_id, :name])
    create index(:commercial_ventures, [:home_location_id])

    create constraint(:commercial_ventures, :commercial_ventures_type,
             check:
               "venture_type IN ('felag', 'merchant_house', 'ship_share', 'caravan_partnership', 'workshop_partnership')"
           )

    create constraint(:commercial_ventures, :commercial_ventures_status,
             check: "status IN ('active', 'seasonal', 'dormant', 'completed', 'dissolved')"
           )

    create table(:venture_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :commercial_venture_id,
          references(:commercial_ventures, type: :binary_id, on_delete: :delete_all), null: false

      add :household_id, references(:households, type: :binary_id, on_delete: :restrict)
      add :character_id, references(:characters, type: :binary_id, on_delete: :restrict)
      add :role, :text, null: false
      add :contribution, :text
      add :share_percentage, :decimal, precision: 5, scale: 2
      add :status, :text, null: false, default: "active"
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create index(:venture_memberships, [:commercial_venture_id])
    create index(:venture_memberships, [:household_id])
    create index(:venture_memberships, [:character_id])

    create unique_index(:venture_memberships, [:commercial_venture_id, :household_id],
             where: "household_id IS NOT NULL",
             name: :venture_memberships_unique_household_index
           )

    create unique_index(:venture_memberships, [:commercial_venture_id, :character_id],
             where: "character_id IS NOT NULL",
             name: :venture_memberships_unique_character_index
           )

    create constraint(:venture_memberships, :venture_memberships_exactly_one_member,
             check: "(household_id IS NULL) <> (character_id IS NULL)"
           )

    create constraint(:venture_memberships, :venture_memberships_share_range,
             check:
               "share_percentage IS NULL OR (share_percentage > 0 AND share_percentage <= 100)"
           )

    create constraint(:venture_memberships, :venture_memberships_status,
             check: "status IN ('active', 'withdrawn', 'completed', 'inherited')"
           )

    create table(:venture_trade_routes, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :commercial_venture_id,
          references(:commercial_ventures, type: :binary_id, on_delete: :delete_all), null: false

      add :trade_route_id,
          references(:trade_routes, type: :binary_id, on_delete: :delete_all), null: false

      add :role, :text, null: false
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:venture_trade_routes, [:commercial_venture_id, :trade_route_id, :role],
             name: :venture_trade_routes_unique_role_index
           )

    create index(:venture_trade_routes, [:trade_route_id])

    create constraint(:venture_trade_routes, :venture_trade_routes_role,
             check: "role IN ('carrier', 'financier', 'supplier', 'warehouse', 'agent')"
           )
  end
end
