defmodule AncientStones.Repo.Migrations.CreateRaces do
  use Ecto.Migration

  def change do
    create table(:races, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:races, [:world_id, :name])
  end
end
