defmodule AncientStone.Repo.Migrations.CreateWorlds do
  use Ecto.Migration

  def change do
    create table(:worlds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
