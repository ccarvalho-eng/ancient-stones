defmodule AncientStones.Worlds.WorldGuide do
  import Ecto.Query

  alias AncientStones.Repo
  alias AncientStones.Worlds.Assembly
  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CommodityBalance
  alias AncientStones.Worlds.CommercialVenture
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.HoldCommerceEntry
  alias AncientStones.Worlds.HoldEconomicProfile
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.TaxExemption
  alias AncientStones.Worlds.TaxAssessment
  alias AncientStones.Worlds.TaxPolicy
  alias AncientStones.Worlds.TaxRevenueShare
  alias AncientStones.Worlds.TradeFlow
  alias AncientStones.Worlds.TradeRoute
  alias AncientStones.Worlds.WaterBody
  alias AncientStones.Worlds.WaterBodyConnection
  alias AncientStones.Worlds.World

  def load!(world_id) do
    world =
      World
      |> Repo.get!(world_id)
      |> Repo.preload(:galaxy)

    continents = list_by_world(Continent, world.id)
    provinces = list_by_parent(Province, :continent_id, Enum.map(continents, & &1.id))
    holds = list_by_parent(Hold, :province_id, Enum.map(provinces, & &1.id))

    locations =
      Location
      |> list_by_parent(:hold_id, Enum.map(holds, & &1.id))
      |> Repo.preload([:water_body, :gods, :location_gods])

    calendars = list_by_parent(Calendar, :continent_id, Enum.map(continents, & &1.id))
    offices = list_offices(world.id)
    commerce = list_by_parent(HoldCommerceEntry, :hold_id, Enum.map(holds, & &1.id))

    economic_profiles =
      list_hold_economic_profiles(Enum.map(holds, & &1.id))

    commodity_balances =
      list_commodity_balances(Enum.map(holds, & &1.id))

    trade_routes = list_trade_routes(world.id)
    trade_flows = world.id |> list_trade_flows() |> Enum.group_by(& &1.trade_route_id)
    tax_policies = list_tax_policies(world.id)
    tax_exemptions = world.id |> list_tax_exemptions() |> Enum.group_by(& &1.tax_policy_id)
    revenue_shares = world.id |> list_revenue_shares() |> Enum.group_by(& &1.tax_policy_id)
    tax_assessments = world.id |> list_tax_assessments() |> Enum.group_by(& &1.tax_policy_id)
    water_bodies = list_water_bodies(world.id)
    water_connections = list_water_connections(world.id)
    commercial_ventures = list_commercial_ventures(world.id)
    assemblies = list_assemblies(world.id)

    %{
      world: world_card(world),
      continents:
        geography(
          continents,
          provinces,
          holds,
          locations,
          calendars,
          offices,
          commerce,
          economic_profiles,
          commodity_balances
        ),
      characters: world.id |> list_by_world(Character) |> Enum.map(&card/1),
      guilds: world.id |> list_by_world(Guild) |> Enum.map(&card/1),
      trade_routes:
        Enum.map(trade_routes, fn route ->
          trade_route_card(route, Map.get(trade_flows, route.id, []))
        end),
      tax_policies:
        Enum.map(tax_policies, fn policy ->
          tax_policy_card(
            policy,
            Map.get(tax_exemptions, policy.id, []),
            Map.get(revenue_shares, policy.id, []),
            Map.get(tax_assessments, policy.id, [])
          )
        end),
      economic_profiles: Enum.map(economic_profiles, &economic_profile_card/1),
      commodity_balances: Enum.map(commodity_balances, &commodity_balance_card/1),
      tax_assessments:
        tax_assessments |> Map.values() |> List.flatten() |> Enum.map(&tax_assessment_card/1),
      water_bodies: Enum.map(water_bodies, &water_body_card/1),
      water_connections: Enum.map(water_connections, &water_connection_card/1),
      commercial_ventures: Enum.map(commercial_ventures, &commercial_venture_card/1),
      assemblies: Enum.map(assemblies, &assembly_card/1)
    }
  end

  defp list_by_world(world_id, schema) when is_binary(world_id) do
    list_by_world(schema, world_id)
  end

  defp list_by_world(schema, world_id) do
    schema
    |> where([entity], entity.world_id == ^world_id)
    |> order_by([entity], asc: entity.name)
    |> Repo.all()
  end

  defp list_by_parent(_schema, _field, []) do
    []
  end

  defp list_by_parent(schema, field, ids) do
    schema
    |> where([entity], field(entity, ^field) in ^ids)
    |> order_by([entity], asc: entity.name)
    |> Repo.all()
  end

  defp list_commercial_ventures(world_id) do
    CommercialVenture
    |> where([venture], venture.world_id == ^world_id)
    |> order_by([venture], asc: venture.name)
    |> Repo.all()
    |> Repo.preload([
      :home_location,
      memberships: [:character, :household],
      trade_route_links: [:trade_route]
    ])
  end

  defp list_hold_economic_profiles([]) do
    []
  end

  defp list_hold_economic_profiles(hold_ids) do
    HoldEconomicProfile
    |> where([profile], profile.hold_id in ^hold_ids)
    |> order_by([profile], asc: profile.assessment_label)
    |> Repo.all()
    |> Repo.preload(:hold)
  end

  defp list_commodity_balances([]) do
    []
  end

  defp list_commodity_balances(hold_ids) do
    CommodityBalance
    |> where([balance], balance.hold_id in ^hold_ids)
    |> order_by([balance], asc: balance.commodity)
    |> Repo.all()
    |> Repo.preload(:hold)
  end

  defp list_offices(world_id) do
    PoliticalOffice
    |> where([office], office.world_id == ^world_id)
    |> order_by([office], asc: office.office)
    |> Repo.all()
    |> Repo.preload([:character, :designated_successor])
  end

  defp list_assemblies(world_id) do
    Assembly
    |> where([assembly], assembly.world_id == ^world_id)
    |> order_by([assembly], asc: assembly.scope, asc: assembly.name)
    |> Repo.all()
    |> Repo.preload([:continent, :province, :hold, :location])
  end

  defp list_trade_routes(world_id) do
    TradeRoute
    |> where([route], route.world_id == ^world_id)
    |> order_by([route], asc: route.name)
    |> Repo.all()
    |> Repo.preload([
      :origin_hold,
      :destination_hold,
      stops: [location: :hold],
      legs: [
        :water_body,
        water_traversals: :water_body,
        origin_stop: [location: :hold],
        destination_stop: [location: :hold]
      ]
    ])
  end

  defp list_water_bodies(world_id) do
    WaterBody
    |> where([water], water.world_id == ^world_id)
    |> order_by([water], asc: water.name)
    |> Repo.all()
    |> Repo.preload([:parent_water_body, province_links: :province])
  end

  defp list_water_connections(world_id) do
    WaterBodyConnection
    |> join(:inner, [connection], origin in assoc(connection, :origin_water_body))
    |> where([_connection, origin], origin.world_id == ^world_id)
    |> order_by([connection], asc: connection.connection_type)
    |> Repo.all()
    |> Repo.preload([:origin_water_body, :destination_water_body])
  end

  defp list_trade_flows(world_id) do
    TradeFlow
    |> join(:inner, [flow], route in assoc(flow, :trade_route))
    |> where([_flow, route], route.world_id == ^world_id)
    |> order_by([flow], asc: flow.commodity)
    |> Repo.all()
    |> Repo.preload(:currency)
  end

  defp list_tax_policies(world_id) do
    TaxPolicy
    |> where([policy], policy.world_id == ^world_id)
    |> order_by([policy], asc: policy.name)
    |> Repo.all()
    |> Repo.preload([:continent, :province, :hold, :collecting_office, :currency])
  end

  defp list_tax_exemptions(world_id) do
    TaxExemption
    |> join(:inner, [exemption], policy in assoc(exemption, :tax_policy))
    |> where([_exemption, policy], policy.world_id == ^world_id)
    |> order_by([exemption], asc: exemption.name)
    |> Repo.all()
    |> Repo.preload([:guild, :trade_route, :continent, :province, :hold])
  end

  defp list_revenue_shares(world_id) do
    TaxRevenueShare
    |> join(:inner, [share], policy in assoc(share, :tax_policy))
    |> where([_share, policy], policy.world_id == ^world_id)
    |> order_by([share], desc: share.percentage)
    |> Repo.all()
    |> Repo.preload(:political_office)
  end

  defp list_tax_assessments(world_id) do
    TaxAssessment
    |> join(:inner, [assessment], policy in assoc(assessment, :tax_policy))
    |> where([_assessment, policy], policy.world_id == ^world_id)
    |> order_by([assessment], desc: assessment.assessment_period_label)
    |> Repo.all()
    |> Repo.preload([:currency, :tax_policy])
  end

  defp geography(
         continents,
         provinces,
         holds,
         locations,
         calendars,
         offices,
         commerce,
         economic_profiles,
         commodity_balances
       ) do
    provinces_by_continent = Enum.group_by(provinces, & &1.continent_id)
    holds_by_province = Enum.group_by(holds, & &1.province_id)
    locations_by_hold = Enum.group_by(locations, & &1.hold_id)
    calendars_by_continent = Enum.group_by(calendars, & &1.continent_id)
    continent_offices = Enum.group_by(offices, & &1.continent_id)
    province_offices = Enum.group_by(offices, & &1.province_id)
    hold_offices = Enum.group_by(offices, & &1.hold_id)
    commerce_by_hold = Enum.group_by(commerce, & &1.hold_id)
    economic_profiles_by_hold = Map.new(economic_profiles, &{&1.hold_id, &1})
    commodity_balances_by_hold = Enum.group_by(commodity_balances, & &1.hold_id)

    Enum.map(continents, fn continent ->
      continent_provinces = Map.get(provinces_by_continent, continent.id, [])

      continent
      |> card()
      |> Map.put(
        :calendar,
        calendar_card(List.first(Map.get(calendars_by_continent, continent.id, [])))
      )
      |> Map.put(:offices, office_cards(Map.get(continent_offices, continent.id, [])))
      |> Map.put(
        :provinces,
        Enum.map(continent_provinces, fn province ->
          province_holds = Map.get(holds_by_province, province.id, [])

          province
          |> card()
          |> Map.put(:offices, office_cards(Map.get(province_offices, province.id, [])))
          |> Map.put(
            :holds,
            Enum.map(province_holds, fn hold ->
              hold
              |> card()
              |> Map.put(:offices, office_cards(Map.get(hold_offices, hold.id, [])))
              |> Map.put(:commerce, commerce_cards(Map.get(commerce_by_hold, hold.id, [])))
              |> Map.put(
                :economic_profile,
                economic_profile_card(Map.get(economic_profiles_by_hold, hold.id))
              )
              |> Map.put(
                :commodity_balances,
                Enum.map(
                  Map.get(commodity_balances_by_hold, hold.id, []),
                  &commodity_balance_card/1
                )
              )
              |> Map.put(
                :locations,
                Enum.map(Map.get(locations_by_hold, hold.id, []), &location_card/1)
              )
            end)
          )
        end)
      )
    end)
  end

  defp card(entity) do
    entity
    |> Map.take([
      :terrain,
      :climate,
      :climate_zone,
      :moisture_regime,
      :elevation_profile,
      :geology,
      :watershed,
      :area_km2,
      :latitude,
      :longitude,
      :mean_winter_temperature_c,
      :mean_summer_temperature_c,
      :annual_precipitation_mm,
      :frost_free_days
    ])
    |> Map.merge(%{
      name: Map.get(entity, :name) || "Untitled",
      description: Map.get(entity, :description) || Map.get(entity, :notes)
    })
  end

  defp location_card(location) do
    %{
      name: location.name,
      description: location.description,
      detail: loaded_name(location.water_body),
      latitude: location.latitude,
      longitude: location.longitude,
      population_estimate: location.population_estimate,
      record_scope: label(location.record_scope),
      gods: Enum.map(location.gods, &loaded_name/1)
    }
  end

  defp world_card(world) do
    %{
      id: world.id,
      name: world.name,
      description: world.description,
      galaxy_name: world.galaxy && world.galaxy.name,
      galaxy_description: world.galaxy && world.galaxy.description,
      primary_star_name: world.primary_star_name,
      orbital_period_days: world.orbital_period_days,
      axial_tilt_degrees: world.axial_tilt_degrees,
      day_length_hours: world.day_length_hours,
      mean_radius_km: world.mean_radius_km,
      mass_earths: world.mass_earths,
      surface_gravity_m_s2: world.surface_gravity_m_s2,
      orbital_distance_au: world.orbital_distance_au,
      orbital_eccentricity: world.orbital_eccentricity,
      atmospheric_pressure_atm: world.atmospheric_pressure_atm,
      bond_albedo: world.bond_albedo,
      ocean_fraction: world.ocean_fraction,
      star_mass_solar: world.star_mass_solar,
      star_luminosity_solar: world.star_luminosity_solar,
      star_temperature_k: world.star_temperature_k,
      map_projection: world.map_projection
    }
  end

  defp calendar_card(nil) do
    nil
  end

  defp calendar_card(calendar) do
    %{
      name: calendar.name,
      days_per_week: calendar.days_per_week,
      weekday_names: calendar.weekday_names || []
    }
  end

  defp office_cards(offices) do
    Enum.map(offices, fn office ->
      holder = if Ecto.assoc_loaded?(office.character), do: office.character, else: nil

      %{
        name: Map.get(office, :office) || Map.get(office, :title) || "Office",
        holder: holder && holder.name,
        detail:
          [
            holder && holder.name,
            office.selection_method,
            office.term_started_year && "from year #{office.term_started_year}"
          ]
          |> Enum.reject(&is_nil/1)
          |> Enum.join(" - "),
        description: office.succession_rule || office.description,
        selection_method: office.selection_method,
        succession_rule: office.succession_rule,
        term_started_year: office.term_started_year,
        term_length_years: office.term_length_years
      }
    end)
  end

  defp commerce_cards(entries) do
    Enum.map(entries, fn entry ->
      detail =
        [
          Map.get(entry, :kind),
          Map.get(entry, :frequency),
          label(Map.get(entry, :accounting_scope)),
          label(Map.get(entry, :coverage_scope))
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(" - ")

      %{name: entry.name, description: detail}
    end)
  end

  defp trade_route_card(route, flows) do
    %{
      name: route.name,
      description: route.description,
      detail:
        Enum.join(
          [
            "#{route.origin_hold.name} to #{route.destination_hold.name}",
            label(route.transport_mode),
            label(route.status),
            route.distance_km && "#{route.distance_km} km"
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        ),
      annual_capacity_tonnes: route.annual_capacity_tonnes,
      capacity_basis: route.capacity_basis,
      flows: Enum.map(flows, &trade_flow_card/1),
      stops:
        route.stops
        |> Enum.sort_by(& &1.position)
        |> Enum.map(&trade_route_stop_card/1),
      legs:
        route.legs
        |> Enum.sort_by(& &1.position)
        |> Enum.map(&trade_route_leg_card/1)
    }
  end

  defp commercial_venture_card(venture) do
    %{
      name: venture.name,
      description: venture.description,
      detail:
        Enum.join(
          [
            venture_type_label(venture.venture_type),
            label(venture.status),
            venture.purpose,
            loaded_name(venture.home_location)
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        ),
      capital_basis: venture.capital_basis,
      formation_label: venture.formation_label,
      end_label: venture.end_label,
      members: Enum.map(venture.memberships, &venture_membership_card/1),
      routes: Enum.map(venture.trade_route_links, &venture_trade_route_card/1)
    }
  end

  defp venture_membership_card(membership) do
    member = loaded_name(membership.character) || loaded_name(membership.household)

    %{
      name: member,
      description: membership.description || membership.contribution,
      detail:
        Enum.join(
          [
            membership.role,
            membership.share_percentage && "#{membership.share_percentage}% share",
            label(membership.status)
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        )
    }
  end

  defp venture_trade_route_card(link) do
    %{
      name: loaded_name(link.trade_route),
      description: link.description,
      detail: label(link.role)
    }
  end

  defp venture_type_label(:felag) do
    "Partnership (felag)"
  end

  defp venture_type_label(venture_type) do
    label(venture_type)
  end

  defp trade_route_stop_card(stop) do
    %{
      name: "#{stop.position}. #{stop.location.name}",
      description: stop.description,
      detail:
        Enum.join(
          [stop.location.hold.name, stop.handling_notes]
          |> Enum.reject(&is_nil/1),
          " - "
        )
    }
  end

  defp trade_route_leg_card(leg) do
    water_path =
      leg.water_traversals
      |> Enum.sort_by(& &1.position)
      |> Enum.map_join(" to ", &loaded_name(&1.water_body))

    %{
      name: "#{leg.origin_stop.location.name} to #{leg.destination_stop.location.name}",
      description: leg.description,
      detail:
        Enum.join(
          [
            label(leg.transport_mode),
            "#{leg.distance_km} km",
            "#{leg.typical_travel_days} days",
            water_path,
            label(leg.seasonality),
            label(leg.risk),
            leg.handling_notes
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        )
    }
  end

  defp water_body_card(water) do
    %{
      name: water.name,
      description: water.description,
      detail:
        Enum.join(
          [
            label(water.kind),
            label(water.salinity),
            label(water.navigability),
            label(water.freeze_pattern),
            water.parent_water_body && water.parent_water_body.name,
            label(water.status)
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        ),
      prevailing_conditions: water.prevailing_conditions,
      hazards: water.hazards,
      latitude: water.latitude,
      longitude: water.longitude,
      source_latitude: water.source_latitude,
      source_longitude: water.source_longitude,
      mouth_latitude: water.mouth_latitude,
      mouth_longitude: water.mouth_longitude,
      length_km: water.length_km,
      area_km2: water.area_km2,
      drainage_area_km2: water.drainage_area_km2,
      source_elevation_m: water.source_elevation_m,
      mean_discharge_m3_s: water.mean_discharge_m3_s,
      provinces:
        Enum.map(water.province_links, fn link ->
          %{
            name: link.province.name,
            detail: label(link.relationship),
            description: link.description
          }
        end)
    }
  end

  defp water_connection_card(connection) do
    %{
      name: "#{connection.origin_water_body.name} to #{connection.destination_water_body.name}",
      description: connection.description,
      detail:
        Enum.join(
          [
            label(connection.connection_type),
            "Hydrology: #{label(connection.directionality)}",
            "Navigation: #{label(connection.navigation_directionality)}",
            label(connection.navigability),
            label(connection.seasonality),
            connection.distance_km && "#{connection.distance_km} km"
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        )
    }
  end

  defp trade_flow_card(flow) do
    %{
      name: flow.commodity,
      description: flow.description,
      detail:
        Enum.join(
          [
            label(flow.category),
            "#{flow.quantity} #{flow.unit}",
            "#{flow.declared_value} #{flow.currency.name}",
            label(flow.frequency),
            label(flow.coverage_scope),
            flow.quantity_basis,
            flow.unit_mass_kg && "#{flow.unit_mass_kg} kg per unit",
            flow.annual_consignment_count &&
              "#{flow.annual_consignment_count} consignments/year"
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        )
    }
  end

  defp tax_policy_card(policy, exemptions, revenue_shares, assessments) do
    jurisdiction = policy.continent || policy.province || policy.hold
    collector = policy.collecting_office

    %{
      name: policy.name,
      description: policy.description,
      detail:
        Enum.join(
          [
            label(policy.tax_type),
            "#{policy.rate}% #{label(policy.rate_basis)}",
            jurisdiction && jurisdiction.name,
            collector && Map.get(collector, :office),
            label(policy.status)
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        ),
      effective_from_year: policy.effective_from_year,
      effective_to_year: policy.effective_to_year,
      exemptions: Enum.map(exemptions, &tax_exemption_card/1),
      revenue_shares: Enum.map(revenue_shares, &revenue_share_card/1),
      assessments: Enum.map(assessments, &tax_assessment_card/1)
    }
  end

  defp economic_profile_card(nil) do
    nil
  end

  defp economic_profile_card(profile) do
    hold = if Ecto.assoc_loaded?(profile.hold), do: profile.hold, else: nil

    %{
      name: (hold && hold.name) || profile.assessment_label,
      description: profile.description,
      detail: "#{profile.population_estimate} people - #{profile.household_estimate} households",
      population_estimate: profile.population_estimate,
      household_estimate: profile.household_estimate,
      urban_population_estimate: profile.urban_population_estimate,
      arable_hectares_estimate: profile.arable_hectares_estimate,
      pasture_hectares_estimate: profile.pasture_hectares_estimate,
      staple_reserve_months: profile.staple_reserve_months,
      assessment_label: profile.assessment_label,
      confidence: label(profile.confidence)
    }
  end

  defp commodity_balance_card(balance) do
    hold = if Ecto.assoc_loaded?(balance.hold), do: balance.hold, else: nil

    %{
      name: balance.commodity,
      description: balance.description,
      detail:
        Enum.join(
          [
            hold && hold.name,
            "#{balance.annual_output} #{balance.unit} output",
            "#{balance.annual_local_need} #{balance.unit} local need",
            "#{CommodityBalance.ordinary_balance(balance)} #{balance.unit} ordinary balance",
            "#{balance.stored_reserve} #{balance.unit} stored",
            "#{balance.bad_year_output_percentage}% bad-year output"
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        )
    }
  end

  defp tax_assessment_card(assessment) do
    policy = if Ecto.assoc_loaded?(assessment.tax_policy), do: assessment.tax_policy, else: nil

    %{
      name: (policy && policy.name) || assessment.assessment_period_label,
      description: assessment.description,
      assessed_unit: assessment.assessed_unit,
      assessed_unit_count: assessment.assessed_unit_count,
      coverage_percentage: assessment.coverage_percentage,
      valuation_basis: assessment.valuation_basis,
      detail:
        Enum.join(
          [
            assessment.assessment_period_label,
            "#{assessment.cash_yield} #{assessment.currency.name} cash",
            "#{assessment.in_kind_value} #{assessment.currency.name} in kind",
            "#{assessment.customary_labor_days} customary labor days",
            assessment.assessed_unit_count &&
              "#{assessment.assessed_unit_count} #{assessment.assessed_unit}",
            assessment.coverage_percentage && "#{assessment.coverage_percentage}% coverage",
            assessment.valuation_basis,
            label(assessment.confidence)
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        )
    }
  end

  defp tax_exemption_card(exemption) do
    beneficiary =
      [
        exemption.guild,
        exemption.trade_route,
        exemption.continent,
        exemption.province,
        exemption.hold
      ]
      |> Enum.find(&(not is_nil(loaded_name(&1))))
      |> loaded_name()

    %{
      name: exemption.name,
      description: exemption.description,
      detail: "#{beneficiary}: #{exemption.exemption_percentage}% relief"
    }
  end

  defp revenue_share_card(share) do
    %{
      name: share.political_office.office,
      description: nil,
      detail: "#{share.percentage}% of collected revenue"
    }
  end

  defp assembly_card(assembly) do
    target = assembly.continent || assembly.province || assembly.hold

    %{
      name: assembly.name,
      description: assembly.description,
      detail:
        [label(assembly.scope), loaded_name(target), label(assembly.status)]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(" - "),
      meeting_cycle: assembly.meeting_cycle,
      membership_rule: assembly.membership_rule,
      jurisdiction: assembly.jurisdiction,
      appeal_path: assembly.appeal_path,
      enforcement: assembly.enforcement,
      location: loaded_name(assembly.location)
    }
  end

  defp loaded_name(nil) do
    nil
  end

  defp loaded_name(%Ecto.Association.NotLoaded{}) do
    nil
  end

  defp loaded_name(entity) do
    Map.get(entity, :name)
  end

  defp label(nil) do
    nil
  end

  defp label(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
