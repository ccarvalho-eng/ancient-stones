defmodule AncientStones.Repo.Migrations.CreateRaceTraits do
  use Ecto.Migration

  def change do
    create table(:race_traits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :race_id, references(:races, type: :binary_id, on_delete: :delete_all), null: false
      add :category, :text, null: false
      add :name, :text, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:race_traits, [:race_id, :category, :name])
  end
end
