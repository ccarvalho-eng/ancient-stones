defmodule AncientStones.Repo.Migrations.CreateHolds do
  use Ecto.Migration

  def change do
    create table(:holds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :terrain, :string
      add :climate, :string

      add :province_id, references(:provinces, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:holds, [:province_id])
    create unique_index(:holds, [:province_id, :name])
  end
end
