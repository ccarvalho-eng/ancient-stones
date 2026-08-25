defmodule AncientStonesWeb.WorldLive.WatersDashboardTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.ProvinceWaterBody
  alias AncientStones.Worlds.TradeRouteLeg
  alias AncientStones.Worlds.TradeRouteStop
  alias AncientStones.Worlds.WaterBody
  alias AncientStones.Worlds.WaterBodyConnection

  test "manages named waters, connections, province relationships, location links, and search", %{
    conn: conn
  } do
    geography = create_geography("Audrun")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{geography.world}/dashboard?section=waters&mode=body")

    assert has_element?(view, "#waters-dashboard")
    assert has_element?(view, "#water-body-form")

    view
    |> form("#water-body-form",
      water_body: %{
        name: "Skeld Sea",
        kind: "sea",
        salinity: "saline",
        navigability: "coastal",
        freeze_pattern: "rare",
        status: "active"
      }
    )
    |> render_submit()

    sea = Repo.get_by!(WaterBody, name: "Skeld Sea")
    assert has_element?(view, "#waters-water_body-#{sea.id}")

    view
    |> form("#water-body-form",
      water_body: %{
        name: "Eirwater",
        kind: "river",
        salinity: "fresh",
        navigability: "shallow_draft",
        freeze_pattern: "seasonal",
        status: "seasonal"
      }
    )
    |> render_submit()

    river = Repo.get_by!(WaterBody, name: "Eirwater")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{geography.world}/dashboard?section=waters&mode=connection")

    view
    |> form("#water-body-connection-form",
      water_body_connection: %{
        origin_water_body_id: river.id,
        destination_water_body_id: sea.id,
        connection_type: "flows_into",
        directionality: "one_way",
        navigation_directionality: "two_way",
        navigability: "shallow_draft",
        seasonality: "spring_to_autumn",
        distance_km: 180
      }
    )
    |> render_submit()

    connection = Repo.get_by!(WaterBodyConnection, origin_water_body_id: river.id)
    assert has_element?(view, "#waters-water_body_connection-#{connection.id}")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{geography.world}/dashboard?section=waters&mode=province")

    view
    |> form("#province-water-body-form",
      province_water_body: %{
        province_id: geography.province.id,
        water_body_id: river.id,
        relationship: "drains_to"
      }
    )
    |> render_submit()

    link = Repo.get_by!(ProvinceWaterBody, water_body_id: river.id)
    assert has_element?(view, "#waters-province_water_body-#{link.id}")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{geography.world}/dashboard?section=waters&mode=location")

    view
    |> form("#location-water-body-form",
      location_water_body: %{
        location_id: geography.origin_location.id,
        water_body_id: river.id
      }
    )
    |> render_submit()

    assert Worlds.get_location!(geography.origin_location.id).water_body_id == river.id
    assert has_element?(view, "#waters-water_location-#{geography.origin_location.id}")

    view
    |> element("#waters-water_location-#{geography.origin_location.id}")
    |> render_click()

    assert has_element?(view, "#water-detail-fields")

    view
    |> form("#dashboard-search-form-mobile", search: %{query: "unmapped water"})
    |> render_change()

    refute has_element?(view, "#waters-water_body-#{river.id}")
    assert has_element?(view, "#waters-water_body-empty")
  end

  test "rejects forged water references from another world", %{conn: conn} do
    geography = create_geography("Audrun")
    other = create_geography("Veyra")
    {:ok, local} = create_water(geography.world, "Skeld Sea")
    {:ok, foreign} = create_water(other.world, "Far Sea")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{geography.world}/dashboard?section=waters&mode=connection")

    render_submit(view, "save_water_body_connection", %{
      "water_body_connection" => %{
        "origin_water_body_id" => local.id,
        "destination_water_body_id" => foreign.id,
        "connection_type" => "opens_to",
        "navigability" => "coastal"
      }
    })

    refute Repo.get_by(WaterBodyConnection, origin_water_body_id: local.id)
  end

  test "manages ordered stops and legs from a selected trade route", %{conn: conn} do
    geography = create_geography("Audrun")
    {:ok, river} = create_water(geography.world, "Eirwater", :river)

    {:ok, _province_link} =
      Worlds.create_province_water_body(geography.province, river, %{relationship: :contains})

    {:ok, _origin_location} =
      Worlds.set_location_water_body(geography.world, geography.origin_location, river)

    {:ok, _destination_location} =
      Worlds.set_location_water_body(geography.world, geography.destination_location, river)

    {:ok, view, _html} =
      live(
        conn,
        ~p"/worlds/#{geography.world}/dashboard?section=economy&mode=route&trade_route_id=#{geography.route.id}"
      )

    assert has_element?(view, "#trade-route-topology")

    view
    |> form("#trade-route-stop-form",
      trade_route_stop: %{location_id: geography.origin_location.id, position: 1}
    )
    |> render_submit()

    origin_stop = Repo.get_by!(TradeRouteStop, trade_route_id: geography.route.id, position: 1)

    view
    |> form("#trade-route-stop-form",
      trade_route_stop: %{location_id: geography.destination_location.id, position: 2}
    )
    |> render_submit()

    destination_stop =
      Repo.get_by!(TradeRouteStop, trade_route_id: geography.route.id, position: 2)

    assert has_element?(view, "#economy-trade_route_stop-#{origin_stop.id}")
    assert has_element?(view, "#economy-trade_route_stop-#{destination_stop.id}")

    view
    |> form("#trade-route-leg-form",
      trade_route_leg: %{
        origin_stop_id: origin_stop.id,
        destination_stop_id: destination_stop.id,
        water_body_id: river.id,
        position: 1,
        transport_mode: "river",
        distance_km: 84,
        typical_travel_days: "2.5",
        seasonality: "spring_to_autumn",
        risk: "moderate"
      }
    )
    |> render_submit()

    leg = Repo.get_by!(TradeRouteLeg, trade_route_id: geography.route.id)
    assert has_element?(view, "#economy-trade_route_leg-#{leg.id}")
    assert has_element?(view, "#trade-route-leg-water-path-#{leg.id}", "Eirwater")

    view
    |> element("#economy-trade_route_leg-#{leg.id}")
    |> render_click()

    view
    |> form("#trade-route-leg-form", trade_route_leg: %{typical_travel_days: "3"})
    |> render_submit()

    assert Decimal.equal?(Repo.get!(TradeRouteLeg, leg.id).typical_travel_days, Decimal.new(3))

    view
    |> element("#delete-trade_route_leg-#{leg.id}")
    |> render_click()

    refute Repo.get(TradeRouteLeg, leg.id)
  end

  defp create_water(world, name, kind \\ :sea) do
    Worlds.create_water_body(world, %{
      name: name,
      kind: kind,
      salinity: if(kind == :river, do: :fresh, else: :saline),
      navigability: if(kind == :river, do: :shallow_draft, else: :coastal),
      freeze_pattern: if(kind == :river, do: :seasonal, else: :rare),
      status: :active
    })
  end

  defp create_geography(world_name) do
    {:ok, world} = Worlds.create_world(%{name: world_name})
    {:ok, continent} = Worlds.create_continent(world, %{name: "#{world_name} Reach"})
    {:ok, province} = Worlds.create_province(continent, %{name: "#{world_name} March"})
    {:ok, origin_hold} = Worlds.create_hold(province, %{name: "West Hold"})
    {:ok, destination_hold} = Worlds.create_hold(province, %{name: "East Hold"})
    {:ok, location_type} = Worlds.create_location_type(world, %{name: "Landing"})

    {:ok, origin_location} =
      Worlds.create_location(origin_hold, location_type, %{name: "West Quay"})

    {:ok, destination_location} =
      Worlds.create_location(destination_hold, location_type, %{name: "East Quay"})

    {:ok, route} =
      Worlds.create_trade_route(
        world,
        %{name: "Known Road", transport_mode: :mixed, status: :active},
        %{origin_hold: origin_hold, destination_hold: destination_hold}
      )

    %{
      world: world,
      province: province,
      origin_location: origin_location,
      destination_location: destination_location,
      route: route
    }
  end
end
