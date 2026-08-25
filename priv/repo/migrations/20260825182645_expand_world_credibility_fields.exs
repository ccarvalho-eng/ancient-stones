defmodule AncientStones.Repo.Migrations.ExpandWorldCredibilityFields do
  use Ecto.Migration

  def change do
    alter table(:worlds) do
      add :mass_earths, :decimal, precision: 10, scale: 5
      add :surface_gravity_m_s2, :decimal, precision: 8, scale: 4
      add :orbital_distance_au, :decimal, precision: 10, scale: 6
      add :orbital_eccentricity, :decimal, precision: 8, scale: 6
      add :atmospheric_pressure_atm, :decimal, precision: 8, scale: 4
      add :bond_albedo, :decimal, precision: 6, scale: 5
      add :ocean_fraction, :decimal, precision: 6, scale: 5
      add :star_mass_solar, :decimal, precision: 8, scale: 5
      add :star_luminosity_solar, :decimal, precision: 8, scale: 5
      add :star_temperature_k, :integer
    end

    alter table(:calendars) do
      add :intercalation_interval_years, :integer
      add :intercalary_days, :integer
      add :intercalation_rule, :text
    end

    for table <- [:provinces, :holds] do
      alter table(table) do
        add :area_km2, :bigint
        add :latitude, :decimal, precision: 9, scale: 6
        add :longitude, :decimal, precision: 9, scale: 6
        add :mean_winter_temperature_c, :decimal, precision: 6, scale: 2
        add :mean_summer_temperature_c, :decimal, precision: 6, scale: 2
        add :annual_precipitation_mm, :integer
        add :frost_free_days, :integer
      end
    end

    alter table(:locations) do
      add :latitude, :decimal, precision: 9, scale: 6
      add :longitude, :decimal, precision: 9, scale: 6
    end

    alter table(:households) do
      add :resident_count, :integer
      add :dependent_count, :integer
      add :servant_count, :integer
    end

    alter table(:political_offices) do
      add :selection_method, :text
      add :succession_rule, :text
      add :term_started_year, :integer
      add :term_length_years, :integer
    end

    alter table(:creatures) do
      add :population_status, :string
      add :diet, :text
      add :ecological_role, :text
      add :economic_uses, :text
      add :seasonal_pattern, :text
    end

    create constraint(:worlds, :worlds_physical_values_positive,
             check:
               "(mass_earths IS NULL OR mass_earths > 0) AND " <>
                 "(surface_gravity_m_s2 IS NULL OR surface_gravity_m_s2 > 0) AND " <>
                 "(orbital_distance_au IS NULL OR orbital_distance_au > 0) AND " <>
                 "(atmospheric_pressure_atm IS NULL OR atmospheric_pressure_atm > 0) AND " <>
                 "(star_mass_solar IS NULL OR star_mass_solar > 0) AND " <>
                 "(star_luminosity_solar IS NULL OR star_luminosity_solar > 0) AND " <>
                 "(star_temperature_k IS NULL OR star_temperature_k > 0)"
           )

    create constraint(:worlds, :worlds_orbital_eccentricity_range,
             check:
               "orbital_eccentricity IS NULL OR " <>
                 "(orbital_eccentricity >= 0 AND orbital_eccentricity < 1)"
           )

    create constraint(:worlds, :worlds_physical_fractions_range,
             check:
               "(bond_albedo IS NULL OR bond_albedo BETWEEN 0 AND 1) AND " <>
                 "(ocean_fraction IS NULL OR ocean_fraction BETWEEN 0 AND 1)"
           )

    create constraint(:calendars, :calendars_intercalation_complete,
             check:
               "(intercalation_interval_years IS NULL AND intercalary_days IS NULL) OR " <>
                 "(intercalation_interval_years > 0 AND intercalary_days > 0)"
           )

    for table <- [:provinces, :holds] do
      create constraint(table, String.to_atom("#{table}_measured_geography_range"),
               check:
                 "(area_km2 IS NULL OR area_km2 > 0) AND " <>
                   "(latitude IS NULL OR latitude BETWEEN -90 AND 90) AND " <>
                   "(longitude IS NULL OR longitude BETWEEN -180 AND 180) AND " <>
                   "(annual_precipitation_mm IS NULL OR annual_precipitation_mm >= 0) AND " <>
                   "(frost_free_days IS NULL OR frost_free_days BETWEEN 0 AND 366)"
             )
    end

    create constraint(:locations, :locations_geographic_coordinates_range,
             check:
               "(latitude IS NULL OR latitude BETWEEN -90 AND 90) AND " <>
                 "(longitude IS NULL OR longitude BETWEEN -180 AND 180)"
           )

    create constraint(:households, :households_composition_non_negative,
             check:
               "(resident_count IS NULL OR resident_count >= 1) AND " <>
                 "(dependent_count IS NULL OR dependent_count >= 0) AND " <>
                 "(servant_count IS NULL OR servant_count >= 0)"
           )

    create constraint(:households, :households_composition_within_residents,
             check:
               "resident_count IS NULL OR " <>
                 "COALESCE(dependent_count, 0) + COALESCE(servant_count, 0) <= resident_count"
           )

    create constraint(:political_offices, :political_offices_term_length_positive,
             check: "term_length_years IS NULL OR term_length_years > 0"
           )

    create constraint(:creatures, :creatures_population_status_check,
             check:
               "population_status IS NULL OR " <>
                 "population_status IN ('wild', 'domestic', 'managed', 'feral')"
           )
  end
end
