defmodule AncientStones.Repo.Migrations.AddOrbitalAlignmentToCalendars do
  use Ecto.Migration

  def change do
    alter table(:calendars) do
      add :orbital_period_days, :integer
      add :year_start_angle, :numeric
      add :perihelion_day, :integer
      add :axial_tilt_degrees, :numeric
    end
  end
end
