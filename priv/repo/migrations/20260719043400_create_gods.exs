defmodule AncientStones.Repo.Migrations.CreateGods do
  use Ecto.Migration

  def change do
    create table(:gods, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :pantheon, :text
      add :domain, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:gods, [:world_id, :name])
  end
end
