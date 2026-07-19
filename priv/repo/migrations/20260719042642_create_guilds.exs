defmodule AncientStones.Repo.Migrations.CreateGuilds do
  use Ecto.Migration

  def change do
    create table(:guilds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :description, :text
      add :leader, :text
      add :headquarters, :text
      add :alignment, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:guilds, [:world_id, :name])
  end
end
