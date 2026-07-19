defmodule AncientStones.Repo.Migrations.CreateCivilizations do
  use Ecto.Migration

  def change do
    create table(:civilizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :era, :text
      add :status, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:civilizations, [:world_id, :name])

    create table(:civilization_races, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :civilization_id,
          references(:civilizations, type: :binary_id, on_delete: :delete_all), null: false

      add :race_id, references(:races, type: :binary_id, on_delete: :delete_all), null: false
      add :relationship, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:civilization_races, [:race_id])
    create unique_index(:civilization_races, [:civilization_id, :race_id])

    create table(:civilization_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :civilization_id,
          references(:civilizations, type: :binary_id, on_delete: :delete_all), null: false

      add :location_id, references(:locations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :relationship, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:civilization_locations, [:location_id])
    create unique_index(:civilization_locations, [:civilization_id, :location_id])
  end
end
