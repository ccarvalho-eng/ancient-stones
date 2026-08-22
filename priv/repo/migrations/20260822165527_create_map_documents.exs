defmodule AncientStones.Repo.Migrations.CreateMapDocuments do
  use Ecto.Migration

  def change do
    create table(:map_documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :document, :map, null: false, default: %{"objects" => []}
      add :width, :integer, null: false, default: 1600
      add :height, :integer, null: false, default: 1000

      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:map_documents, [:world_id])
  end
end
