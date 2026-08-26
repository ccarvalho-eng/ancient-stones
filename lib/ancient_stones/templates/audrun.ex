defmodule AncientStones.Templates.Audrun do
  @moduledoc """
  Audrun's complete geography, society, economy, ecology, and material-culture template.
  """

  @snapshot_path Path.expand("../../../priv/templates/audrun_snapshot.json", __DIR__)
  @external_resource @snapshot_path
  @snapshot_json File.read!(@snapshot_path)
  @snapshot_keys ~w(
    abbreviation accounting_scope alignment amount annual_capacity_tonnes annual_consignment_count
    annual_local_need annual_output annual_precipitation_mm appeal_path arable_hectares_estimate
    area_km2 assemblies assessed_unit assessed_unit_count assessment_label assessment_period_label
    assessments atmospheric_pressure_atm authenticity axial_tilt_degrees bad_year_output_percentage
    bond_albedo calendars capacity_basis capital capital_basis cash_yield category character
    character_a character_a_role character_b character_b_role character_locations
    character_relationships character_roles character_skills characters children civilization
    civilization_locations civilization_races civilizations climate climate_zone collecting_office
    commerce_entries commercial_ventures commodity commodity_balances confidence connection_type
    continent continents contribution coverage_percentage coverage_scope creature creature_locations
    creature_types creatures critical_damage currency customary_labor_days damage danger_level
    date_label day_length_hours days days_per_week declared_value dependent_count description
    designated_successor destination_hold destination_location destination_stop_position
    destination_water_body diet direction directionality distance_km documents domain
    drainage_area_km2 east_longitude ecological_role economic_profile economic_uses effective_from
    effective_from_year effective_to effective_to_year effects elevation_profile end_date_label
    end_label ended_at ends_at_year enforcement equipped era eras events exemption_percentage
    exemptions find_location flows formation_label freeze_pattern frequency frost_free_days galaxies
    galaxy gender geology god gods guild guild_influences guild_memberships guilds habitat
    handling_notes hands hazards headquarters health hold holds home_location household
    household_estimate household_type households in_kind_value inclination_degrees intercalary_days
    intercalation_interval_years intercalation_rule inventory_categories inventory_items is_primary
    item items jurisdiction kind landholdings latitude leader legs length_km level levels life_stage
    location location_gods location_types locations longitude lore_connections magicka
    major_watersheds maker map_projection map_x map_y mass_earths mass_lunar material
    mean_discharge_m3_s mean_radius_km mean_summer_temperature_c mean_winter_temperature_c
    meeting_cycle membership_rule memberships minimum_value moisture_regime months moons
    mouth_latitude mouth_longitude name navigability navigation_directionality north_latitude notes
    occupation occupations ocean_currents ocean_fraction office orbital_distance_au
    orbital_eccentricity orbital_period_days origin_hold origin_location origin_stop_position
    origin_water_body pantheon parent pasture_hectares_estimate percentage perihelion_day period_name
    political_office political_offices politics population_estimate population_status position
    presence prevailing_conditions prevailing_winds primary primary_star_name primary_use provenance
    province province_links provinces purpose quantity quantity_basis race races rank rate rate_basis
    record_scope ref relationship relationship_type resident_count revenue_shares risk role salinity scope
    seasonal_pattern seasonality selection_method semi_major_axis_km servant_count share_percentage
    size_hectares skill skill_trees skills social_status source source_elevation_m source_latitude
    source_longitude south_latitude spells stamina staple_reserve_months star_luminosity_solar
    star_mass_solar star_temperature_k start_date_label started_at starts_at_year status stops
    storage_loss_percentage stored_reserve succession_rule surface_gravity_m_s2 target tax_policies
    tax_type tectonic_setting temperament tenure_type term_length_years term_started_year terrain
    tidal_role timeline_era timelines title trade_route trade_routes traits transport_mode type
    typical_travel_days unit unit_mass_kg urban_population_estimate valuation_basis value value_basis
    value_per_unit venture_type visibility water_bodies water_body water_body_connections watershed
    wealth_band weekday_names weight west_longitude world year year_start_angle
  )a

  def data do
    snapshot = Jason.decode!(@snapshot_json, keys: &decode_key/1)

    snapshot
    |> Map.merge(snapshot.world)
    |> Map.delete(:world)
  end

  defp decode_key(key) do
    key_atom = String.to_existing_atom(key)

    if key_atom in @snapshot_keys do
      key_atom
    else
      raise ArgumentError, "unexpected Audrun template key: #{inspect(key)}"
    end
  end
end
