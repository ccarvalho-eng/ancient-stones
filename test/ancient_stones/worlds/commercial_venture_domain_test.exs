defmodule AncientStones.Worlds.CommercialVentureDomainTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.CommercialVenture
  alias AncientStones.Worlds.VentureMembership
  alias AncientStones.Worlds.VentureTradeRoute

  test "records a partnership, its members, and route roles" do
    economy = create_economy("Audrun")

    assert {:ok, %CommercialVenture{} = venture} = create_venture(economy)

    assert {:ok, %VentureMembership{} = character_membership} =
             Worlds.create_venture_membership(
               venture,
               %{
                 role: "managing partner",
                 contribution: "Navigation and one-sixth of the hull",
                 share_percentage: "40"
               },
               %{character: economy.character}
             )

    assert {:ok, %VentureMembership{} = household_membership} =
             Worlds.create_venture_membership(
               venture,
               %{
                 role: "capital partner",
                 contribution: "Silver and warehouse space",
                 share_percentage: "60"
               },
               %{household: economy.household}
             )

    assert {:ok, %VentureTradeRoute{} = route_link} =
             Worlds.create_venture_trade_route(venture, economy.route, %{
               role: :carrier,
               description: "Operates two spring and two autumn sailings."
             })

    assert Enum.map(Worlds.list_commercial_ventures(economy.world), & &1.id) == [venture.id]

    assert Enum.sort(Enum.map(Worlds.list_venture_memberships(venture), & &1.id)) ==
             Enum.sort([character_membership.id, household_membership.id])

    assert Enum.map(Worlds.list_venture_trade_routes(venture), & &1.id) == [route_link.id]

    assert Enum.map(
             Worlds.list_character_venture_memberships(economy.character),
             & &1.commercial_venture.id
           ) == [venture.id]

    assert Enum.map(
             Worlds.list_household_venture_memberships(economy.household),
             & &1.commercial_venture.id
           ) == [venture.id]
  end

  test "requires exactly one member and rejects duplicate membership" do
    economy = create_economy("Audrun")
    {:ok, venture} = create_venture(economy)

    assert {:error, changeset} =
             Worlds.create_venture_membership(venture, %{role: "partner"}, %{})

    assert "must select exactly one character or household" in errors_on(changeset).member

    assert {:error, changeset} =
             Worlds.create_venture_membership(
               venture,
               %{role: "partner"},
               %{character: economy.character, household: economy.household}
             )

    assert "must select exactly one character or household" in errors_on(changeset).member

    assert {:ok, _membership} =
             Worlds.create_venture_membership(
               venture,
               %{role: "partner"},
               %{character: economy.character}
             )

    assert {:error, changeset} =
             Worlds.create_venture_membership(
               venture,
               %{role: "captain"},
               %{character: economy.character}
             )

    assert "has already been taken" in errors_on(changeset).character_id
  end

  test "locks the venture and rejects active shares above one hundred percent" do
    economy = create_economy("Audrun")
    {:ok, venture} = create_venture(economy)

    assert {:ok, _membership} =
             Worlds.create_venture_membership(
               venture,
               %{role: "capital partner", share_percentage: "75"},
               %{household: economy.household}
             )

    assert {:error, changeset} =
             Worlds.create_venture_membership(
               venture,
               %{role: "working partner", share_percentage: "26"},
               %{character: economy.character}
             )

    assert "would allocate more than 100%" in errors_on(changeset).share_percentage

    assert {:ok, _membership} =
             Worlds.create_venture_membership(
               venture,
               %{role: "former factor", share_percentage: "40", status: :withdrawn},
               %{character: economy.character}
             )
  end

  test "rejects location, member, and route references from another world" do
    economy = create_economy("Audrun")
    other = create_economy("Veyra")

    assert {:error, changeset} =
             Worlds.create_commercial_venture(
               economy.world,
               venture_attrs("Foreign House"),
               %{home_location: other.location}
             )

    assert "does not belong to this world" in errors_on(changeset).home_location_id

    {:ok, venture} = create_venture(economy)

    assert {:error, changeset} =
             Worlds.create_venture_membership(
               venture,
               %{role: "partner"},
               %{character: other.character}
             )

    assert "does not belong to this world" in errors_on(changeset).character_id

    assert {:error, changeset} =
             Worlds.create_venture_trade_route(venture, other.route, %{role: :agent})

    assert "does not belong to this world" in errors_on(changeset).trade_route_id
  end

  test "protects member history and removes the graph with its world" do
    economy = create_economy("Audrun")
    {:ok, venture} = create_venture(economy)

    {:ok, character_membership} =
      Worlds.create_venture_membership(
        venture,
        %{role: "working partner"},
        %{character: economy.character}
      )

    {:ok, _household_membership} =
      Worlds.create_venture_membership(
        venture,
        %{role: "capital partner"},
        %{household: economy.household}
      )

    {:ok, route_link} =
      Worlds.create_venture_trade_route(venture, economy.route, %{role: :supplier})

    assert {:error, :character_has_society_history} = Worlds.delete_character(economy.character)
    assert {:error, :household_has_venture_history} = Worlds.delete_household(economy.household)

    assert {:ok, _world} = Worlds.delete_world(economy.world)
    assert Repo.get(CommercialVenture, venture.id) == nil
    assert Repo.get(VentureMembership, character_membership.id) == nil
    assert Repo.get(VentureTradeRoute, route_link.id) == nil
  end

  defp create_venture(economy) do
    Worlds.create_commercial_venture(
      economy.world,
      venture_attrs("West Sea Shipshare"),
      %{home_location: economy.location}
    )
  end

  defp venture_attrs(name) do
    %{
      name: name,
      venture_type: :ship_share,
      status: :active,
      purpose: "Own and operate one coastal cargo vessel",
      capital_basis: "Hull shares, sailcloth, and working silver",
      formation_label: "Spring compact"
    }
  end

  defp create_economy(world_name) do
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
