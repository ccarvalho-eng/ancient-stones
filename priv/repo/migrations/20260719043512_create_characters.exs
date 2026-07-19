defmodule AncientStones.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :race_id, references(:races, type: :binary_id, on_delete: :nilify_all)
      add :guild_id, references(:guilds, type: :binary_id, on_delete: :nilify_all)
      add :home_location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
      add :name, :text, null: false
      add :title, :text
      add :role, :text
      add :politics, :text
      add :status, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:characters, [:world_id, :name])
    create index(:characters, [:race_id])
    create index(:characters, [:guild_id])
    create index(:characters, [:home_location_id])

    create constraint(:characters, :characters_status_valid,
             check: "status IS NULL OR status IN ('alive', 'dead', 'unknown')"
           )

    create table(:guild_influences, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :guild_id, references(:guilds, type: :binary_id, on_delete: :delete_all), null: false
      add :god_id, references(:gods, type: :binary_id, on_delete: :delete_all)
      add :character_id, references(:characters, type: :binary_id, on_delete: :delete_all)
      add :relationship, :text, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:guild_influences, [:god_id])
    create index(:guild_influences, [:character_id])

    create unique_index(:guild_influences, [:guild_id, :god_id, :relationship],
             where: "god_id IS NOT NULL"
           )

    create unique_index(:guild_influences, [:guild_id, :character_id, :relationship],
             where: "character_id IS NOT NULL"
           )

    create constraint(:guild_influences, :guild_influences_one_target,
             check:
               "(god_id IS NOT NULL AND character_id IS NULL) OR (god_id IS NULL AND character_id IS NOT NULL)"
           )
  end
end
