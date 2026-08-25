defmodule AncientStonesWeb.WorldLive.CommercialVentureDashboardTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.CommercialVenture
  alias AncientStones.Worlds.VentureMembership
  alias AncientStones.Worlds.VentureTradeRoute

  test "manages ventures, partners, route roles, and participation details", %{conn: conn} do
    economy = create_economy()

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=venture")

    assert has_element?(view, "#commercial-venture-form")

    view
    |> form("#commercial-venture-form",
      commercial_venture: %{
        name: "West Sea Shipshare",
        venture_type: "ship_share",
        home_location_id: economy.location.id,
        status: "active",
        purpose: "Own and operate one coastal cargo vessel",
        capital_basis: "Hull shares, sailcloth, and working silver"
      }
    )
    |> render_submit()

    venture = Repo.get_by!(CommercialVenture, name: "West Sea Shipshare")
    assert has_element?(view, "#economy-commercial_venture-#{venture.id}")

    {:ok, view, _html} =
      live(
        conn,
        ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=venture&commercial_venture_id=#{venture.id}"
      )

    assert has_element?(view, "#venture-maintenance")

    view
    |> form("#venture-membership-form",
      venture_membership: %{
        member_ref: "character:#{economy.character.id}",
        role: "sailing partner",
        contribution: "Navigation and one-sixth of the hull",
        share_percentage: "40",
        status: "active"
      }
    )
    |> render_submit()

    membership = Repo.get_by!(VentureMembership, commercial_venture_id: venture.id)
    assert has_element?(view, "#edit-venture-membership-#{membership.id}")

    view
    |> form("#venture-trade-route-form",
      venture_trade_route: %{
        trade_route_id: economy.route.id,
        role: "carrier",
        description: "Operates spring and autumn sailings."
      }
    )
    |> render_submit()

    route_link = Repo.get_by!(VentureTradeRoute, commercial_venture_id: venture.id)
    assert has_element?(view, "#edit-venture-trade-route-#{route_link.id}")
    assert has_element?(view, "#economy-related-venture-members article")
    assert has_element?(view, "#economy-related-venture-routes article")

    {:ok, character_view, _html} =
      live(
        conn,
        ~p"/worlds/#{economy.world}/dashboard?section=characters&character_id=#{economy.character.id}"
      )

    assert has_element?(
             character_view,
             "#character-venture-membership-#{membership.id}"
           )

    {:ok, society_view, _html} =
      live(
        conn,
        ~p"/worlds/#{economy.world}/dashboard?section=society&mode=household&household_id=#{economy.household.id}"
      )

    assert has_element?(society_view, "#household-venture-participation")
  end

  test "rejects forged venture members from another world", %{conn: conn} do
    economy = create_economy()
    other = create_economy("Veyra")

    {:ok, venture} =
      Worlds.create_commercial_venture(economy.world, %{
        name: "Raven Quay Partnership",
        venture_type: :felag,
        purpose: "Pool a fishing boat and seasonal labor"
      })

    {:ok, view, _html} =
      live(
        conn,
        ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=venture&commercial_venture_id=#{venture.id}"
      )

    render_submit(view, "save_venture_membership", %{
      "venture_membership" => %{
        "member_ref" => "character:#{other.character.id}",
        "role" => "partner",
        "status" => "active"
      }
    })

    refute Repo.get_by(VentureMembership,
             commercial_venture_id: venture.id,
             character_id: other.character.id
           )
  end

  defp create_economy(world_name \\ "Audrun") do
    {:ok, world} = Worlds.create_world(%{name: world_name})
    {:ok, continent} = Worlds.create_continent(world, %{name: "#{world_name} Reach"})
    {:ok, province} = Worlds.create_province(continent, %{name: "#{world_name} Coast"})
    {:ok, origin_hold} = Worlds.create_hold(province, %{name: "West Hold"})
    {:ok, destination_hold} = Worlds.create_hold(province, %{name: "East Hold"})
    {:ok, location_type} = Worlds.create_location_type(world, %{name: "Quay"})
    {:ok, location} = Worlds.create_location(origin_hold, location_type, %{name: "Raven Quay"})

    {:ok, route} =
      Worlds.create_trade_route(
        world,
        %{name: "West Sea Lane", transport_mode: :sea},
        %{origin_hold: origin_hold, destination_hold: destination_hold}
      )

    {:ok, character} = Worlds.create_character(world, %{name: "Ragna"})

    {:ok, household} =
      Worlds.create_household(world, %{
        name: "Raven Quay Household",
        household_type: :merchant_household,
        status: :active
      })

    %{
      world: world,
      location: location,
      route: route,
      character: character,
      household: household
    }
  end
end
