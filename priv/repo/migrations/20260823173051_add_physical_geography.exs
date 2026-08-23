defmodule AncientStones.Repo.Migrations.AddPhysicalGeography do
  use Ecto.Migration

  def change do
    alter table(:worlds) do
      add :day_length_hours, :numeric
      add :mean_radius_km, :integer
      add :map_projection, :text
    end

    alter table(:continents) do
      add :north_latitude, :numeric
      add :south_latitude, :numeric
      add :west_longitude, :numeric
      add :east_longitude, :numeric
      add :area_km2, :bigint
      add :tectonic_setting, :text
      add :prevailing_winds, :text
      add :ocean_currents, :text
      add :major_watersheds, :text
    end

    alter table(:provinces) do
      add :climate_zone, :text
      add :moisture_regime, :text
      add :elevation_profile, :text
      add :geology, :text
      add :watershed, :text
    end

    alter table(:holds) do
      add :climate_zone, :text
      add :moisture_regime, :text
      add :elevation_profile, :text
      add :geology, :text
      add :watershed, :text
    end

    create constraint(:worlds, :worlds_day_length_hours_positive,
             check: "day_length_hours IS NULL OR day_length_hours > 0"
           )

    create constraint(:worlds, :worlds_mean_radius_km_positive,
             check: "mean_radius_km IS NULL OR mean_radius_km > 0"
           )

    create constraint(:continents, :continents_latitude_bounds,
             check:
               "(north_latitude IS NULL OR north_latitude BETWEEN -90 AND 90) AND " <>
                 "(south_latitude IS NULL OR south_latitude BETWEEN -90 AND 90)"
           )

    create constraint(:continents, :continents_longitude_bounds,
             check:
               "(west_longitude IS NULL OR west_longitude BETWEEN -180 AND 180) AND " <>
                 "(east_longitude IS NULL OR east_longitude BETWEEN -180 AND 180)"
           )

    create constraint(:continents, :continents_latitude_order,
             check:
               "north_latitude IS NULL OR south_latitude IS NULL OR " <>
                 "north_latitude >= south_latitude"
           )

    create constraint(:continents, :continents_area_km2_positive,
             check: "area_km2 IS NULL OR area_km2 > 0"
           )
  end
end
