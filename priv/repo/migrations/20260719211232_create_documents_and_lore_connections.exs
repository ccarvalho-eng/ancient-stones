defmodule AncientStones.Repo.Migrations.CreateDocumentsAndLoreConnections do
  use Ecto.Migration

  def change do
    create table(:documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :author_character_id, references(:characters, type: :binary_id, on_delete: :nilify_all)
      add :location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
      add :guild_id, references(:guilds, type: :binary_id, on_delete: :nilify_all)
      add :god_id, references(:gods, type: :binary_id, on_delete: :nilify_all)
      add :race_id, references(:races, type: :binary_id, on_delete: :nilify_all)

      add :civilization_id, references(:civilizations, type: :binary_id, on_delete: :nilify_all)

      add :title, :text, null: false
      add :kind, :text
      add :source, :text
      add :summary, :text
      add :content, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:documents, [:world_id, :title])
    create index(:documents, [:world_id, :kind])
    create index(:documents, [:author_character_id])
    create index(:documents, [:location_id])
    create index(:documents, [:guild_id])
    create index(:documents, [:god_id])
    create index(:documents, [:race_id])
    create index(:documents, [:civilization_id])

    create table(:lore_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false

      add :source_character_id, references(:characters, type: :binary_id, on_delete: :delete_all)
      add :source_guild_id, references(:guilds, type: :binary_id, on_delete: :delete_all)
      add :source_god_id, references(:gods, type: :binary_id, on_delete: :delete_all)
      add :source_race_id, references(:races, type: :binary_id, on_delete: :delete_all)

      add :source_civilization_id,
          references(:civilizations, type: :binary_id, on_delete: :delete_all)

      add :source_location_id, references(:locations, type: :binary_id, on_delete: :delete_all)
      add :source_hold_id, references(:holds, type: :binary_id, on_delete: :delete_all)
      add :source_province_id, references(:provinces, type: :binary_id, on_delete: :delete_all)
      add :source_continent_id, references(:continents, type: :binary_id, on_delete: :delete_all)

      add :target_character_id, references(:characters, type: :binary_id, on_delete: :delete_all)
      add :target_guild_id, references(:guilds, type: :binary_id, on_delete: :delete_all)
      add :target_god_id, references(:gods, type: :binary_id, on_delete: :delete_all)
      add :target_race_id, references(:races, type: :binary_id, on_delete: :delete_all)

      add :target_civilization_id,
          references(:civilizations, type: :binary_id, on_delete: :delete_all)

      add :target_location_id, references(:locations, type: :binary_id, on_delete: :delete_all)
      add :target_hold_id, references(:holds, type: :binary_id, on_delete: :delete_all)
      add :target_province_id, references(:provinces, type: :binary_id, on_delete: :delete_all)
      add :target_continent_id, references(:continents, type: :binary_id, on_delete: :delete_all)

      add :name, :text
      add :connection_type, :text, null: false
      add :status, :text
      add :started_at, :text
      add :ended_at, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:lore_connections, [:world_id])
    create index(:lore_connections, [:world_id, :connection_type])
    create index(:lore_connections, [:source_character_id])
    create index(:lore_connections, [:source_guild_id])
    create index(:lore_connections, [:source_god_id])
    create index(:lore_connections, [:source_race_id])
    create index(:lore_connections, [:source_civilization_id])
    create index(:lore_connections, [:source_location_id])
    create index(:lore_connections, [:source_hold_id])
    create index(:lore_connections, [:source_province_id])
    create index(:lore_connections, [:source_continent_id])
    create index(:lore_connections, [:target_character_id])
    create index(:lore_connections, [:target_guild_id])
    create index(:lore_connections, [:target_god_id])
    create index(:lore_connections, [:target_race_id])
    create index(:lore_connections, [:target_civilization_id])
    create index(:lore_connections, [:target_location_id])
    create index(:lore_connections, [:target_hold_id])
    create index(:lore_connections, [:target_province_id])
    create index(:lore_connections, [:target_continent_id])

    create constraint(:lore_connections, :lore_connections_one_source,
             check:
               "num_nonnulls(source_character_id, source_guild_id, source_god_id, source_race_id, source_civilization_id, source_location_id, source_hold_id, source_province_id, source_continent_id) = 1"
           )

    create constraint(:lore_connections, :lore_connections_one_target,
             check:
               "num_nonnulls(target_character_id, target_guild_id, target_god_id, target_race_id, target_civilization_id, target_location_id, target_hold_id, target_province_id, target_continent_id) = 1"
           )
  end
end
