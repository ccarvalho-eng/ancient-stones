defmodule AncientStones.Repo.Migrations.CreateGalaxiesAndPlanets do
  use Ecto.Migration

  def change do
    create table(:galaxies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :text, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:galaxies, [:name])

    alter table(:worlds) do
      add :galaxy_id, references(:galaxies, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:worlds, [:galaxy_id])
  end
end
