defmodule AncientStones.Repo.Migrations.TightenCredibilityConstraints do
  use Ecto.Migration

  def up do
    drop constraint(:calendars, :calendars_intercalation_complete)

    create constraint(:calendars, :calendars_intercalation_complete,
             check:
               "(intercalation_interval_years IS NULL AND intercalary_days IS NULL) OR " <>
                 "(intercalation_interval_years IS NOT NULL AND " <>
                 "intercalary_days IS NOT NULL AND " <>
                 "intercalation_interval_years > 0 AND intercalary_days > 0)"
           )

    create constraint(:households, :households_composition_complete,
             check:
               "resident_count IS NOT NULL OR " <>
                 "(dependent_count IS NULL AND servant_count IS NULL)"
           )

    for table <- [:provinces, :holds] do
      create constraint(table, String.to_atom("#{table}_temperature_order"),
               check:
                 "mean_winter_temperature_c IS NULL OR " <>
                   "mean_summer_temperature_c IS NULL OR " <>
                   "mean_winter_temperature_c <= mean_summer_temperature_c"
             )
    end
  end

  def down do
    for table <- [:provinces, :holds] do
      drop constraint(table, String.to_atom("#{table}_temperature_order"))
    end

    drop constraint(:households, :households_composition_complete)
    drop constraint(:calendars, :calendars_intercalation_complete)

    create constraint(:calendars, :calendars_intercalation_complete,
             check:
               "(intercalation_interval_years IS NULL AND intercalary_days IS NULL) OR " <>
                 "(intercalation_interval_years > 0 AND intercalary_days > 0)"
           )
  end
end
