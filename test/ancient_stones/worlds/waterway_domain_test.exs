defmodule AncientStones.Worlds.WaterwayDomainTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.TradeRouteLeg
  alias AncientStones.Worlds.TradeRouteLegWater
  alias AncientStones.Worlds.TradeRouteStop
  alias AncientStones.Worlds.WaterBody
  alias AncientStones.Worlds.WaterBodyConnection

  test "creates world-scoped waters, connections, province links, and location links" do
    geography = create_geography("Audrun")

    {:ok, sea} = create_water(geography.world, "Skeld Sea", :sea)

    {:ok, river} =
      create_water(geography.world, "Eirwater", :river,
        salinity: :fresh,
        navigability: :shallow_draft,
        freeze_pattern: :seasonal
      )

    assert {:ok, %WaterBodyConnection{} = connection} =
             Worlds.create_water_body_connection(
               geography.world,
               %{
                 connection_type: :flows_into,
                 directionality: :one_way,
                 navigability: :shallow_draft,
                 seasonality: :spring_to_autumn,
                 distance_km: 180
               },
               %{origin_water_body: river, destination_water_body: sea}
             )

    assert {:ok, province_link} =
             Worlds.create_province_water_body(geography.province, river, %{
               relationship: :drains_to
             })

    assert {:ok, location} =
             Worlds.set_location_water_body(geography.world, geography.origin_location, river)

    assert location.water_body_id == river.id

    assert {:error, :province_water_has_locations} =
             Worlds.delete_province_water_body(province_link)

    assert Enum.map(Worlds.list_water_bodies(geography.world), & &1.id) == [river.id, sea.id]

    assert Enum.map(Worlds.list_water_body_connections(geography.world), & &1.id) == [
             connection.id
           ]

    assert Enum.map(Worlds.list_province_water_bodies(geography.world), & &1.id) == [
             province_link.id
           ]
  end

  test "rejects cross-world water references and self-links" do
    geography = create_geography("Audrun")
    other = create_geography("Veyra")
    {:ok, local_sea} = create_water(geography.world, "Skeld Sea", :sea)
    {:ok, foreign_sea} = create_water(other.world, "Far Sea", :sea)

    assert {:error, changeset} =
             Worlds.create_water_body_connection(
               geography.world,
               %{connection_type: :opens_to, navigability: :coastal},
               %{origin_water_body: local_sea, destination_water_body: foreign_sea}
             )

    assert "does not belong to this world" in errors_on(changeset).destination_water_body_id

    assert {:error, changeset} =
             Worlds.create_water_body_connection(
               geography.world,
               %{connection_type: :opens_to, navigability: :coastal},
               %{origin_water_body: local_sea, destination_water_body: local_sea}
             )

    assert "must differ from origin" in errors_on(changeset).destination_water_body_id

    assert {:error, :water_not_linked_to_location_province} =
             Worlds.set_location_water_body(
               geography.world,
               geography.origin_location,
               local_sea
             )

    assert {:error, :reference_outside_world} =
             Worlds.set_location_water_body(
               geography.world,
               geography.origin_location,
               foreign_sea
             )
  end

  test "records ordered route stops and forward legs" do
    geography = create_geography("Audrun")
    {:ok, river} = create_water(geography.world, "Eirwater", :river)
    {:ok, _province_link} = link_water_to_province(geography.province, river)

    {:ok, _origin_location} =
      Worlds.set_location_water_body(geography.world, geography.origin_location, river)

    {:ok, _destination_location} =
      Worlds.set_location_water_body(geography.world, geography.destination_location, river)

    {:ok, origin_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.origin_location, %{
        position: 1,
        handling_notes: "Load above the ferry landing"
      })

    {:ok, destination_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.destination_location, %{
        position: 2
      })

    assert {:ok, %TradeRouteLeg{} = leg} =
             Worlds.create_trade_route_leg(
               geography.route,
               %{
                 position: 1,
                 transport_mode: :river,
                 distance_km: 84,
                 typical_travel_days: "2.5",
                 seasonality: :spring_to_autumn,
                 risk: :moderate
               },
               %{
                 origin_stop: origin_stop,
                 destination_stop: destination_stop,
                 water_body: river
               }
             )

    assert Enum.map(Worlds.list_trade_route_stops(geography.route), & &1.position) == [1, 2]
    assert Enum.map(Worlds.list_trade_route_legs(geography.route), & &1.id) == [leg.id]
    assert [%TradeRouteLegWater{water_body_id: water_body_id}] = leg.water_traversals
    assert water_body_id == river.id

    assert {:error, changeset} =
             Worlds.create_trade_route_leg(
               geography.route,
               %{
                 position: 2,
                 transport_mode: :river,
                 distance_km: 84,
                 typical_travel_days: 2
               },
               %{origin_stop: destination_stop, destination_stop: origin_stop}
             )

    assert "must immediately follow the origin stop" in errors_on(changeset).destination_stop_id
  end

  test "derives a connected ordered water path and rejects unreachable principal water" do
    geography = create_geography("Audrun")
    {:ok, fjord} = create_water(geography.world, "Hrafn Fjord", :fjord)
    {:ok, open_sea} = create_water(geography.world, "Hrafn Sea", :sea)
    {:ok, coast} = create_water(geography.world, "Skeld Sea", :sea)
    {:ok, remote} = create_water(geography.world, "Remote Sea", :sea)
    {:ok, _province_link} = link_water_to_province(geography.province, fjord)
    {:ok, _province_link} = link_water_to_province(geography.province, coast)

    {:ok, _connection} =
      create_connection(geography.world, fjord, open_sea, :opens_to)

    {:ok, _connection} =
      create_connection(geography.world, open_sea, coast, :opens_to)

    {:ok, _origin_location} =
      Worlds.set_location_water_body(geography.world, geography.origin_location, fjord)

    {:ok, _destination_location} =
      Worlds.set_location_water_body(geography.world, geography.destination_location, coast)

    {:ok, origin_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.origin_location, %{position: 1})

    {:ok, destination_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.destination_location, %{
        position: 2
      })

    assert {:ok, leg} =
             Worlds.create_trade_route_leg(
               geography.route,
               %{
                 position: 1,
                 transport_mode: :sea,
                 distance_km: 120,
                 typical_travel_days: 3,
                 seasonality: :spring_to_autumn
               },
               %{
                 origin_stop: origin_stop,
                 destination_stop: destination_stop,
                 water_body: open_sea
               }
             )

    assert Enum.map(leg.water_traversals, & &1.water_body.name) == [
             "Hrafn Fjord",
             "Hrafn Sea",
             "Skeld Sea"
           ]

    assert {:error, changeset} =
             Worlds.update_trade_route_leg(leg, %{}, %{water_body: remote})

    assert "is not on a navigable path between the stops" in errors_on(changeset).water_body_id
  end

  test "rejects route gaps, reverse symmetric water links, parent cycles, and protected geography deletion" do
    geography = create_geography("Audrun")
    {:ok, sea} = create_water(geography.world, "Skeld Sea", :sea)
    {:ok, _province_link} = link_water_to_province(geography.province, sea)
    {:ok, sound} = create_water(geography.world, "Swan Sound", :sound)

    {:ok, _connection} = create_connection(geography.world, sea, sound, :opens_to)

    assert {:error, changeset} = create_connection(geography.world, sound, sea, :opens_to)
    assert "already exists in either direction" in errors_on(changeset).destination_water_body_id

    assert {:ok, _water} =
             Worlds.update_water_body(sound, %{}, parent_water_body: sea)

    assert {:error, changeset} =
             Worlds.update_water_body(sea, %{}, parent_water_body: sound)

    assert "would create a containment cycle" in errors_on(changeset).parent_water_body_id

    {:ok, _stop} =
      Worlds.create_trade_route_stop(geography.route, geography.origin_location, %{position: 1})

    assert {:error, changeset} =
             Worlds.create_trade_route_stop(geography.route, geography.destination_location, %{
               position: 3
             })

    assert "must be the next itinerary position" in errors_on(changeset).position

    assert {:error, :geography_has_trade_route_stops} =
             Worlds.delete_location(geography.origin_location)

    assert {:error, :geography_has_trade_route_stops} =
             Worlds.delete_location_type(geography.location_type)

    assert {:error, :geography_has_trade_route_stops} =
             Worlds.delete_hold(geography.origin_hold)

    assert {:error, :geography_has_trade_route_stops} =
             Worlds.delete_province(geography.province)

    assert {:error, :geography_has_trade_route_stops} =
             Worlds.delete_continent(geography.continent)
  end

  test "preserves complete route topology across edits and deletions" do
    geography = create_geography("Audrun")

    {:ok, middle_location} =
      Worlds.create_location(geography.origin_hold, geography.location_type, %{
        name: "Middle Shelter"
      })

    {:ok, first_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.origin_location, %{position: 1})

    {:ok, middle_stop} =
      Worlds.create_trade_route_stop(geography.route, middle_location, %{position: 2})

    {:ok, final_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.destination_location, %{
        position: 3
      })

    {:ok, first_leg} =
      Worlds.create_trade_route_leg(
        geography.route,
        %{
          position: 1,
          transport_mode: :road,
          distance_km: 12,
          typical_travel_days: 1
        },
        %{origin_stop: first_stop, destination_stop: middle_stop}
      )

    {:ok, _final_leg} =
      Worlds.create_trade_route_leg(
        geography.route,
        %{
          position: 2,
          transport_mode: :road,
          distance_km: 18,
          typical_travel_days: 1
        },
        %{origin_stop: middle_stop, destination_stop: final_stop}
      )

    assert {:error, changeset} = Worlds.delete_trade_route_leg(first_leg)
    assert "only the final leg can be removed" in errors_on(changeset).position

    assert {:error, changeset} =
             Worlds.update_trade_route_stop(middle_stop, %{position: 3})

    assert "cannot be reordered after creation" in errors_on(changeset).position

    assert {:error, changeset} =
             Worlds.update_trade_route(geography.route, %{distance_km: 999})

    assert "route distance must equal the sum of its legs" in errors_on(changeset).base
  end

  test "rejects a route leg that borrows a stop from another route" do
    geography = create_geography("Audrun")

    {:ok, second_route} =
      Worlds.create_trade_route(
        geography.world,
        %{name: "Second Road", transport_mode: :road},
        %{origin_hold: geography.destination_hold, destination_hold: geography.origin_hold}
      )

    {:ok, origin_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.origin_location, %{position: 1})

    {:ok, foreign_stop} =
      Worlds.create_trade_route_stop(second_route, geography.destination_location, %{position: 1})

    assert {:error, changeset} =
             Worlds.create_trade_route_leg(
               geography.route,
               %{
                 position: 1,
                 transport_mode: :road,
                 distance_km: 20,
                 typical_travel_days: 1
               },
               %{origin_stop: origin_stop, destination_stop: foreign_stop}
             )

    assert "must belong to this route" in errors_on(changeset).destination_stop_id
  end

  test "rejects transport and water combinations that cannot describe a physical leg" do
    geography = create_geography("Audrun")
    {:ok, river} = create_water(geography.world, "Eirwater", :river)
    {:ok, _province_link} = link_water_to_province(geography.province, river)

    {:ok, _origin_location} =
      Worlds.set_location_water_body(geography.world, geography.origin_location, river)

    {:ok, _destination_location} =
      Worlds.set_location_water_body(geography.world, geography.destination_location, river)

    {:ok, origin_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.origin_location, %{position: 1})

    {:ok, destination_stop} =
      Worlds.create_trade_route_stop(geography.route, geography.destination_location, %{
        position: 2
      })

    attrs = %{position: 1, distance_km: 20, typical_travel_days: 1}

    assert {:error, changeset} =
             Worlds.create_trade_route_leg(
               geography.route,
               Map.put(attrs, :transport_mode, :river),
               %{origin_stop: origin_stop, destination_stop: destination_stop}
             )

    assert "is required for water transport" in errors_on(changeset).water_body_id

    assert {:error, changeset} =
             Worlds.create_trade_route_leg(
               geography.route,
               Map.put(attrs, :transport_mode, :road),
               %{
                 origin_stop: origin_stop,
                 destination_stop: destination_stop,
                 water_body: river
               }
             )

    assert "must be empty for overland transport" in errors_on(changeset).water_body_id
  end

  test "protects referenced waters and removes the complete graph with its world" do
    geography = create_geography("Audrun")
    {:ok, sea} = create_water(geography.world, "Skeld Sea", :sea)
    {:ok, _province_link} = link_water_to_province(geography.province, sea)

    {:ok, _location} =
      Worlds.set_location_water_body(geography.world, geography.origin_location, sea)

    {:ok, stop} =
      Worlds.create_trade_route_stop(geography.route, geography.origin_location, %{position: 1})

    assert {:error, changeset} = Worlds.delete_water_body(sea)
    assert errors_on(changeset).province_links != []

    assert {:ok, _world} = Worlds.delete_world(geography.world)
    assert Repo.get(WaterBody, sea.id) == nil
    assert Repo.get(TradeRouteStop, stop.id) == nil
  end

  defp create_water(world, name, kind, overrides \\ []) do
    attrs =
      overrides
      |> Enum.into(%{
        name: name,
        kind: kind,
        salinity: :saline,
        navigability: :coastal,
        freeze_pattern: :rare,
        status: :active
      })

    Worlds.create_water_body(world, attrs)
  end

  defp create_connection(world, origin, destination, connection_type) do
    Worlds.create_water_body_connection(
      world,
      %{
        connection_type: connection_type,
        directionality: :two_way,
        navigation_directionality: :two_way,
        navigability: :coastal,
        seasonality: :spring_to_autumn,
        distance_km: 20
      },
      %{origin_water_body: origin, destination_water_body: destination}
    )
  end

  defp link_water_to_province(province, water) do
    Worlds.create_province_water_body(province, water, %{relationship: :contains})
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
        %{name: "Known Road", transport_mode: :mixed},
        %{origin_hold: origin_hold, destination_hold: destination_hold}
      )

    %{
      world: world,
      continent: continent,
      province: province,
      origin_hold: origin_hold,
      destination_hold: destination_hold,
      origin_location: origin_location,
      destination_location: destination_location,
      location_type: location_type,
      route: route
    }
  end
end
