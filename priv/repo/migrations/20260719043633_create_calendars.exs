defmodule AncientStones.Repo.Migrations.CreateCalendars do
  use Ecto.Migration

  def change do
    create table(:calendars, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :continent_id, references(:continents, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :text, null: false
      add :description, :text
      add :days_per_week, :integer
      add :era, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:calendars, [:continent_id, :name])

    create table(:calendar_months, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :calendar_id, references(:calendars, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :text, null: false
      add :days, :integer, null: false
      add :position, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:calendar_months, [:calendar_id, :name])
    create unique_index(:calendar_months, [:calendar_id, :position])
  end
end
