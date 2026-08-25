defmodule AncientStones.Repo.Migrations.CreateHistoricalSocietyCore do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :social_status, :string
      add :life_stage, :string
      add :wealth_band, :string
    end

    create constraint(:characters, :characters_social_status_check,
             check:
               "social_status IS NULL OR social_status IN ('magnate', 'freeholder', 'tenant', 'landless_free', 'freed', 'unfree', 'outsider', 'unknown')"
           )

    create constraint(:characters, :characters_life_stage_check,
             check:
               "life_stage IS NULL OR life_stage IN ('child', 'adolescent', 'adult', 'elder', 'unknown')"
           )

    create constraint(:characters, :characters_wealth_band_check,
             check:
               "wealth_band IS NULL OR wealth_band IN ('destitute', 'poor', 'modest', 'comfortable', 'wealthy', 'exceptional', 'unknown')"
           )

    create table(:households, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false

      add :home_location_id,
          references(:locations, type: :binary_id, on_delete: :nilify_all)

      add :name, :string, null: false
      add :household_type, :string, null: false, default: "farmstead"
      add :status, :string, null: false, default: "active"
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:households, [:world_id, :name])
    create index(:households, [:home_location_id])

    create constraint(:households, :households_type_check,
             check:
               "household_type IN ('farmstead', 'magnate_household', 'royal_household', 'craft_household', 'merchant_household', 'fishing_household', 'religious_household', 'itinerant_household', 'other')"
           )

    create constraint(:households, :households_status_check,
             check: "status IN ('active', 'dispersed', 'extinct', 'historical')"
           )

    create table(:household_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :household_id,
          references(:households, type: :binary_id, on_delete: :delete_all),
          null: false

      add :character_id,
          references(:characters, type: :binary_id, on_delete: :delete_all),
          null: false

      add :role, :string, null: false, default: "dependent"
      add :status, :string, null: false, default: "active"
      add :is_primary, :boolean, null: false, default: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:household_memberships, [:household_id, :character_id])
    create index(:household_memberships, [:character_id])

    create unique_index(:household_memberships, [:character_id],
             where: "is_primary AND status = 'active'",
             name: :household_memberships_one_primary_per_character_index
           )

    create constraint(:household_memberships, :household_memberships_role_check,
             check:
               "role IN ('head', 'spouse', 'child', 'other_kin', 'fosterling', 'dependent', 'servant', 'hired_worker', 'unfree_dependent', 'guest')"
           )

    create constraint(:household_memberships, :household_memberships_status_check,
             check: "status IN ('active', 'absent', 'former', 'deceased')"
           )

    create constraint(:household_memberships, :household_memberships_primary_active_check,
             check: "NOT is_primary OR status = 'active'"
           )

    create table(:character_relationships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false

      add :character_a_id,
          references(:characters, type: :binary_id, on_delete: :delete_all),
          null: false

      add :character_b_id,
          references(:characters, type: :binary_id, on_delete: :delete_all),
          null: false

      add :relationship_type, :string, null: false
      add :character_a_role, :string
      add :character_b_role, :string
      add :status, :string, null: false, default: "active"
      add :start_date_label, :string
      add :end_date_label, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(
             :character_relationships,
             [:world_id, :character_a_id, :character_b_id, :relationship_type],
             name: :character_relationships_unique_pair_index
           )

    create index(:character_relationships, [:character_a_id])
    create index(:character_relationships, [:character_b_id])

    create constraint(:character_relationships, :character_relationships_distinct_characters,
             check: "character_a_id <> character_b_id"
           )

    create constraint(:character_relationships, :character_relationships_canonical_pair,
             check: "character_a_id::text < character_b_id::text"
           )

    create constraint(:character_relationships, :character_relationships_type_check,
             check:
               "relationship_type IN ('parent_child', 'siblings', 'spouses', 'partners', 'betrothed', 'foster_parent_child', 'foster_siblings', 'guardian_ward')"
           )

    create constraint(:character_relationships, :character_relationships_status_check,
             check:
               "status IN ('active', 'estranged', 'dissolved', 'deceased', 'disputed', 'historical')"
           )

    create table(:landholdings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :household_id,
          references(:households, type: :binary_id, on_delete: :restrict),
          null: false

      add :hold_id, references(:holds, type: :binary_id, on_delete: :restrict)
      add :location_id, references(:locations, type: :binary_id, on_delete: :restrict)
      add :name, :string, null: false
      add :tenure_type, :string, null: false
      add :primary_use, :string, null: false, default: "mixed"
      add :size_hectares, :decimal, precision: 12, scale: 2
      add :status, :string, null: false, default: "active"
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:landholdings, [:household_id, :name])
    create index(:landholdings, [:hold_id])
    create index(:landholdings, [:location_id])

    create constraint(:landholdings, :landholdings_single_geographic_scope,
             check: "num_nonnulls(hold_id, location_id) = 1"
           )

    create constraint(:landholdings, :landholdings_size_positive,
             check: "size_hectares IS NULL OR size_hectares > 0"
           )

    create constraint(:landholdings, :landholdings_tenure_type_check,
             check:
               "tenure_type IN ('allodial', 'customary', 'leasehold', 'granted', 'communal_right', 'usufruct', 'disputed', 'other')"
           )

    create constraint(:landholdings, :landholdings_primary_use_check,
             check:
               "primary_use IN ('residence', 'farming', 'pasture', 'woodland', 'fishing', 'mining', 'quarrying', 'workshop', 'trade', 'ritual', 'mixed', 'other')"
           )

    create constraint(:landholdings, :landholdings_status_check,
             check: "status IN ('active', 'disputed', 'abandoned', 'transferred', 'historical')"
           )
  end
end
