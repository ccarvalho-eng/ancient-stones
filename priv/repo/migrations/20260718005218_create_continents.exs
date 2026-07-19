defmodule AncientStones.Repo.Migrations.CreateContinents do
  use Ecto.Migration

  def change do
    create table(:continents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :world_id, references(:worlds, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:continents, [:world_id])
    create unique_index(:continents, [:world_id, :name])
  end
end
