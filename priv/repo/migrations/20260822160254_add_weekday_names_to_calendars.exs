defmodule AncientStones.Repo.Migrations.AddWeekdayNamesToCalendars do
  use Ecto.Migration

  def change do
    alter table(:calendars) do
      add :weekday_names, {:array, :text}, null: false, default: []
    end

    create constraint(:calendars, :calendars_weekday_names_count_matches_days_per_week,
             check:
               "cardinality(weekday_names) = 0 OR (days_per_week IS NOT NULL AND cardinality(weekday_names) = days_per_week)"
           )
  end
end
