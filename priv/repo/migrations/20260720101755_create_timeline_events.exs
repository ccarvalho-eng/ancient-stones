defmodule AncientStones.Repo.Migrations.CreateTimelineEvents do
  use Ecto.Migration

  def change do
    create table(:timeline_events, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :timeline_id, references(:timelines, type: :binary_id, on_delete: :delete_all),
        null: false

      add :timeline_era_id,
          references(:timeline_eras, type: :binary_id, on_delete: :nilify_all)

      add :name, :text, null: false
      add :year, :integer
      add :position, :integer, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:timeline_events, [:timeline_id])
    create index(:timeline_events, [:timeline_era_id])
    create unique_index(:timeline_events, [:timeline_id, :name])
  end
end
