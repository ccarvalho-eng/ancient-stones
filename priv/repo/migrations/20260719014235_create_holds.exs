defmodule AncientStone.Repo.Migrations.CreateHolds do
  use Ecto.Migration

  def change do
    create table(:holds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text
      add :province_id, references(:provinces, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:holds, [:province_id])
  end
end
