defmodule AncientStones.Worlds.WorldGuide do
  import Ecto.Query

  alias AncientStones.Repo
  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.HoldCommerceEntry
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.TaxExemption
  alias AncientStones.Worlds.TaxPolicy
  alias AncientStones.Worlds.TaxRevenueShare
  alias AncientStones.Worlds.TradeFlow
  alias AncientStones.Worlds.TradeRoute
  alias AncientStones.Worlds.World

  def load!(world_id) do
    world =
      World
      |> Repo.get!(world_id)
      |> Repo.preload(:galaxy)

    continents = list_by_world(Continent, world.id)
    provinces = list_by_parent(Province, :continent_id, Enum.map(continents, & &1.id))
    holds = list_by_parent(Hold, :province_id, Enum.map(provinces, & &1.id))
    locations = list_by_parent(Location, :hold_id, Enum.map(holds, & &1.id))
    calendars = list_by_parent(Calendar, :continent_id, Enum.map(continents, & &1.id))
    offices = list_offices(world.id)
    commerce = list_by_parent(HoldCommerceEntry, :hold_id, Enum.map(holds, & &1.id))
    trade_routes = list_trade_routes(world.id)
    trade_flows = world.id |> list_trade_flows() |> Enum.group_by(& &1.trade_route_id)
    tax_policies = list_tax_policies(world.id)
    tax_exemptions = world.id |> list_tax_exemptions() |> Enum.group_by(& &1.tax_policy_id)
    revenue_shares = world.id |> list_revenue_shares() |> Enum.group_by(& &1.tax_policy_id)

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
          commerce
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
            Map.get(revenue_shares, policy.id, [])
          )
        end)
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

  defp list_offices(world_id) do
    PoliticalOffice
    |> where([office], office.world_id == ^world_id)
    |> order_by([office], asc: office.office)
    |> Repo.all()
    |> Repo.preload(:character)
  end

  defp list_trade_routes(world_id) do
    TradeRoute
    |> where([route], route.world_id == ^world_id)
    |> order_by([route], asc: route.name)
    |> Repo.all()
    |> Repo.preload([:origin_hold, :destination_hold])
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

  defp geography(continents, provinces, holds, locations, calendars, offices, commerce) do
    provinces_by_continent = Enum.group_by(provinces, & &1.continent_id)
    holds_by_province = Enum.group_by(holds, & &1.province_id)
    locations_by_hold = Enum.group_by(locations, & &1.hold_id)
    calendars_by_continent = Enum.group_by(calendars, & &1.continent_id)
    continent_offices = Enum.group_by(offices, & &1.continent_id)
    province_offices = Enum.group_by(offices, & &1.province_id)
    hold_offices = Enum.group_by(offices, & &1.hold_id)
    commerce_by_hold = Enum.group_by(commerce, & &1.hold_id)

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
              |> Map.put(:locations, Enum.map(Map.get(locations_by_hold, hold.id, []), &card/1))
            end)
          )
        end)
      )
    end)
  end

  defp card(entity) do
    %{
      name: Map.get(entity, :name) || "Untitled",
      description: Map.get(entity, :description) || Map.get(entity, :notes)
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
        holder: holder && holder.name
      }
    end)
  end

  defp commerce_cards(entries) do
    Enum.map(entries, fn entry ->
      detail =
        [Map.get(entry, :kind), Map.get(entry, :frequency)]
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
      flows: Enum.map(flows, &trade_flow_card/1)
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
            label(flow.frequency)
          ]
          |> Enum.reject(&is_nil/1),
          " - "
        )
    }
  end

  defp tax_policy_card(policy, exemptions, revenue_shares) do
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
      exemptions: Enum.map(exemptions, &tax_exemption_card/1),
      revenue_shares: Enum.map(revenue_shares, &revenue_share_card/1)
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
