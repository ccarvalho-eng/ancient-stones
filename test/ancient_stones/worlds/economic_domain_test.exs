defmodule AncientStones.Worlds.EconomicDomainTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.Worlds
  alias AncientStones.Worlds.TaxExemption
  alias AncientStones.Worlds.TaxPolicy
  alias AncientStones.Worlds.TaxRevenueShare
  alias AncientStones.Worlds.TradeFlow
  alias AncientStones.Worlds.TradeRoute

  test "creates a world-scoped trade and taxation graph" do
    economy = create_economy("Aldrun")

    assert {:ok, %TradeRoute{} = route} = create_route(economy, "Green Road")
    assert route.seasonality == :year_round
    assert route.risk == :moderate
    assert route.transport_mode == :road
    assert route.status == :active

    assert {:ok, %TradeFlow{} = flow} =
             Worlds.create_trade_flow(
               route,
               %{commodity: "Barley", quantity: "80", unit: "wagon-load", declared_value: "1200"},
               %{currency: economy.currency}
             )

    assert {:ok, %TaxPolicy{} = policy} = create_policy(economy)

    assert {:ok, %TaxExemption{}} =
             Worlds.create_tax_exemption(
               policy,
               %{name: "Winter relief", exemption_percentage: "50"},
               %{trade_route: route}
             )

    assert {:ok, %TaxRevenueShare{}} =
             Worlds.create_tax_revenue_share(
               policy,
               %{percentage: "60"},
               %{political_office: economy.office}
             )

    assert Enum.map(Worlds.list_trade_routes(economy.world), & &1.id) == [route.id]
    assert Enum.map(Worlds.list_trade_flows(economy.world), & &1.id) == [flow.id]
    assert Enum.map(Worlds.list_tax_policies(economy.world), & &1.id) == [policy.id]
    assert length(Worlds.list_tax_exemptions(economy.world)) == 1
    assert length(Worlds.list_tax_revenue_shares(policy)) == 1
  end

  test "rejects references from another world" do
    economy = create_economy("Aldrun")
    other = create_economy("Veyra")

    assert {:error, changeset} =
             Worlds.create_trade_route(
               economy.world,
               %{name: "Impossible Road", transport_mode: "road"},
               %{origin_hold: other.origin_hold, destination_hold: economy.destination_hold}
             )

    assert "does not belong to this world" in errors_on(changeset).origin_hold_id

    {:ok, route} = create_route(economy, "Known Road")

    assert {:error, changeset} =
             Worlds.create_trade_flow(
               route,
               %{commodity: "Salt", quantity: "4", unit: "crate", declared_value: "90"},
               %{currency: other.currency}
             )

    assert "does not belong to this world" in errors_on(changeset).currency_id

    assert {:error, changeset} =
             Worlds.create_trade_flow(
               route,
               %{commodity: "Iron", quantity: "2", unit: "ingot", declared_value: "40"}
             )

    assert "can't be blank" in errors_on(changeset).currency_id
  end

  test "validates endpoint locations and single-scope records" do
    economy = create_economy("Aldrun")

    assert {:error, route_changeset} =
             Worlds.create_trade_route(
               economy.world,
               %{name: "Misplaced Port", transport_mode: "sea"},
               %{
                 origin_hold: economy.origin_hold,
                 destination_hold: economy.destination_hold,
                 origin_location: economy.destination_location
               }
             )

    assert "must belong to its endpoint hold" in errors_on(route_changeset).origin_location_id

    assert {:error, incomplete_route_changeset} =
             Worlds.create_trade_route(
               economy.world,
               %{name: "Unanchored Port", transport_mode: "sea"},
               %{
                 origin_location: economy.origin_location,
                 destination_hold: economy.destination_hold
               }
             )

    assert "requires an endpoint hold" in errors_on(incomplete_route_changeset).origin_location_id

    assert {:error, policy_changeset} =
             Worlds.create_tax_policy(
               economy.world,
               %{name: "Ambiguous Levy", tax_type: "tribute", rate_basis: "fixed", rate: "20"},
               %{continent: economy.continent, hold: economy.origin_hold}
             )

    assert "must select exactly one jurisdiction" in errors_on(policy_changeset).jurisdiction

    assert {:error, currency_changeset} =
             Worlds.create_tax_policy(
               economy.world,
               %{
                 name: "Undenominated Toll",
                 tax_type: "road_toll",
                 rate_basis: "fixed",
                 rate: "2"
               },
               %{hold: economy.origin_hold}
             )

    assert "is required for fixed and per-unit taxes" in errors_on(currency_changeset).currency_id

    {:ok, policy} = create_policy(economy)

    assert {:error, exemption_changeset} =
             Worlds.create_tax_exemption(
               policy,
               %{name: "Ambiguous privilege"},
               %{continent: economy.continent, hold: economy.origin_hold}
             )

    assert "must select exactly one beneficiary" in errors_on(exemption_changeset).beneficiary
  end

  test "rejects revenue allocations above one hundred percent" do
    economy = create_economy("Aldrun")
    {:ok, policy} = create_policy(economy)

    {:ok, second_office} =
      Worlds.create_political_office(
        economy.world,
        %{office: "Road Warden", scope: "hold"},
        %{hold: economy.origin_hold}
      )

    assert {:ok, %TaxRevenueShare{}} =
             Worlds.create_tax_revenue_share(
               policy,
               %{percentage: "70"},
               %{political_office: economy.office}
             )

    assert {:error, changeset} =
             Worlds.create_tax_revenue_share(
               policy,
               %{percentage: "31"},
               %{political_office: second_office}
             )

    assert "would allocate more than 100%" in errors_on(changeset).percentage
  end

  defp create_route(economy, name) do
    Worlds.create_trade_route(
      economy.world,
      %{
        name: name,
        transport_mode: "road",
        distance_km: "240",
        seasonality: "year_round",
        risk: "moderate"
      },
      %{
        origin_hold: economy.origin_hold,
        destination_hold: economy.destination_hold,
        origin_location: economy.origin_location,
        destination_location: economy.destination_location
      }
    )
  end

  defp create_policy(economy) do
    Worlds.create_tax_policy(
      economy.world,
      %{name: "Realm Duty", tax_type: "tribute", rate_basis: "percentage", rate: "5"},
      %{
        continent: economy.continent,
        collecting_office: economy.office,
        currency: economy.currency
      }
    )
  end

  defp create_economy(world_name) do
    {:ok, world} = Worlds.create_world(%{name: world_name})
    {:ok, continent} = Worlds.create_continent(world, %{name: "#{world_name} Reach"})
    {:ok, currency} = Worlds.put_continent_currency(continent, %{name: "#{world_name} Mark"})
    {:ok, province} = Worlds.create_province(continent, %{name: "#{world_name} March"})
    {:ok, origin_hold} = Worlds.create_hold(province, %{name: "West Hold"})
    {:ok, destination_hold} = Worlds.create_hold(province, %{name: "East Hold"})
    {:ok, location_type} = Worlds.create_location_type(world, %{name: "Harbor"})

    {:ok, origin_location} =
      Worlds.create_location(origin_hold, location_type, %{name: "West Quay"})

    {:ok, destination_location} =
      Worlds.create_location(destination_hold, location_type, %{name: "East Quay"})

    {:ok, office} =
      Worlds.create_political_office(
        world,
        %{office: "Toll Keeper", scope: "hold"},
        %{hold: origin_hold}
      )

    %{
      world: world,
      continent: continent,
      currency: currency,
      origin_hold: origin_hold,
      destination_hold: destination_hold,
      origin_location: origin_location,
      destination_location: destination_location,
      office: office
    }
  end
end
