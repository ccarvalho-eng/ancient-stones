defmodule AncientStones.Repo.Migrations.CreateMoons do
  use Ecto.Migration

  def change do
    create table(:moons, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :orbital_period_days, :decimal, precision: 10, scale: 5
      add :semi_major_axis_km, :bigint
      add :mean_radius_km, :integer
      add :mass_lunar, :decimal, precision: 10, scale: 6
      add :orbital_eccentricity, :decimal, precision: 8, scale: 6
      add :inclination_degrees, :decimal, precision: 7, scale: 4
      add :tidal_role, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:moons, [:world_id, :name])
    create index(:moons, [:world_id])

    create constraint(:moons, :moons_physical_values_positive,
             check:
               "(orbital_period_days IS NULL OR orbital_period_days > 0) AND " <>
                 "(semi_major_axis_km IS NULL OR semi_major_axis_km > 0) AND " <>
                 "(mean_radius_km IS NULL OR mean_radius_km > 0) AND " <>
                 "(mass_lunar IS NULL OR mass_lunar > 0)"
           )

    create constraint(:moons, :moons_orbital_ranges,
             check:
               "(orbital_eccentricity IS NULL OR " <>
                 "(orbital_eccentricity >= 0 AND orbital_eccentricity < 1)) AND " <>
                 "(inclination_degrees IS NULL OR inclination_degrees BETWEEN 0 AND 180)"
           )
  end
end
