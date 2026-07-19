defmodule AncientStones.Repo.Migrations.CreateTimelines do
  use Ecto.Migration

  def change do
    create table(:timelines, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:timelines, [:world_id, :name])

    create table(:timeline_eras, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :timeline_id, references(:timelines, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :text, null: false
      add :abbreviation, :text
      add :position, :integer, null: false
      add :starts_at_year, :integer
      add :ends_at_year, :integer
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:timeline_eras, [:timeline_id, :name])
    create unique_index(:timeline_eras, [:timeline_id, :position])

    alter table(:civilizations) do
      add :timeline_era_id, references(:timeline_eras, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:civilizations, [:timeline_era_id])
  end
end
