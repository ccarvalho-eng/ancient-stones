defmodule AncientStones.Repo.Migrations.AddOrbitalAlignmentToWorlds do
  use Ecto.Migration

  def change do
    alter table(:worlds) do
      add :primary_star_name, :text
      add :orbital_period_days, :integer
      add :axial_tilt_degrees, :numeric
    end

    alter table(:calendars) do
      remove :orbital_period_days, :integer
      remove :axial_tilt_degrees, :numeric
    end
  end
end
