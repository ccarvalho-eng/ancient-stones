defmodule AncientStones.Repo.Migrations.CreateCreatures do
  use Ecto.Migration

  def change do
    create table(:creature_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:creature_types, [:world_id, :name])

    create table(:creatures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false

      add :creature_type_id,
          references(:creature_types, type: :binary_id, on_delete: :nilify_all)

      add :name, :text, null: false
      add :habitat, :text
      add :temperament, :text
      add :danger_level, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:creatures, [:creature_type_id])
    create unique_index(:creatures, [:world_id, :name])

    create table(:creature_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :creature_id, references(:creatures, type: :binary_id, on_delete: :delete_all),
        null: false

      add :location_id, references(:locations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :presence, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:creature_locations, [:location_id])
    create unique_index(:creature_locations, [:creature_id, :location_id])
  end
end
