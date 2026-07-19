defmodule AncientStones.Repo.Migrations.CreateProvinces do
  use Ecto.Migration

  def change do
    create table(:provinces, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :terrain, :string
      add :climate, :string

      add :continent_id, references(:continents, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:provinces, [:continent_id])
    create unique_index(:provinces, [:continent_id, :name])
  end
end
