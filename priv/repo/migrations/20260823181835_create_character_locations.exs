defmodule AncientStones.Repo.Migrations.CreateCharacterLocations do
  use Ecto.Migration

  def change do
    create table(:character_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :character_id,
          references(:characters, type: :binary_id, on_delete: :delete_all), null: false

      add :location_id,
          references(:locations, type: :binary_id, on_delete: :delete_all), null: false

      add :relationship, :text, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:character_locations, [:location_id])
    create unique_index(:character_locations, [:character_id, :location_id])

    create constraint(:character_locations, :character_locations_relationship_valid,
             check:
               "relationship IN ('resident', 'owner', 'worker', 'keeper', 'guide', 'visitor', 'missing', 'historical')"
           )
  end
end
