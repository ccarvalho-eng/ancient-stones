defmodule AncientStonesWeb.WorldLive.EconomicDashboardTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.TaxExemption
  alias AncientStones.Worlds.TaxPolicy
  alias AncientStones.Worlds.TaxRevenueShare
  alias AncientStones.Worlds.TradeFlow
  alias AncientStones.Worlds.TradeRoute

  test "provides CRUD forms for the complete economic model", %{conn: conn} do
    economy = create_economy()
    {:ok, view, _html} = live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy")
    assert has_element?(view, "#economy-dashboard")

    view
    |> form("#trade-route-form",
      trade_route: %{
        name: "Green Road",
        origin_hold_id: economy.origin_hold.id,
        destination_hold_id: economy.destination_hold.id,
        transport_mode: "road",
        status: "active"
      }
    )
    |> render_submit()

    route = Repo.get_by!(TradeRoute, name: "Green Road")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=flow")

    view
    |> form("#trade-flow-form",
      trade_flow: %{
        trade_route_id: route.id,
        commodity: "Barley",
        quantity: "12",
        unit: "wagon-load",
        declared_value: "240",
        currency_id: economy.currency.id,
        frequency: "annual"
      }
    )
    |> render_submit()

    assert Repo.get_by!(TradeFlow, commodity: "Barley")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=policy")

    view
    |> form("#tax-policy-form",
      tax_policy: %{
        name: "Green Road Toll",
        jurisdiction: "hold:#{economy.destination_hold.id}",
        tax_type: "road_toll",
        rate_basis: "percentage",
        rate: "4",
        direction: "internal",
        status: "active"
      }
    )
    |> render_submit()

    policy = Repo.get_by!(TaxPolicy, name: "Green Road Toll")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=exemption")

    view
    |> form("#tax-exemption-form",
      tax_exemption: %{
        name: "Winter relief",
        tax_policy_id: policy.id,
        beneficiary: "trade_route:#{route.id}",
        exemption_percentage: "50"
      }
    )
    |> render_submit()

    assert Repo.get_by!(TaxExemption, name: "Winter relief")

    {:ok, view, _html} =
      live(
        conn,
        ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=share&tax_policy_id=#{policy.id}"
      )

    view
    |> form("#tax-revenue-share-form",
      tax_revenue_share: %{
        tax_policy_id: policy.id,
        political_office_id: economy.office.id,
        percentage: "100"
      }
    )
    |> render_submit()

    share = Repo.get_by!(TaxRevenueShare, tax_policy_id: policy.id)

    view
    |> element("#economy-tax_revenue_share-#{share.id}")
    |> render_click()

    view
    |> form("#tax-revenue-share-form", tax_revenue_share: %{percentage: "90"})
    |> render_submit()

    assert Decimal.equal?(Repo.get!(TaxRevenueShare, share.id).percentage, Decimal.new("90"))

    {:ok, policy_view, _html} =
      live(
        conn,
        ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=policy&tax_policy_id=#{policy.id}"
      )

    assert has_element?(policy_view, "#economy-detail-fields")
    assert has_element?(policy_view, "#economy-related-revenue-shares article")
    assert has_element?(policy_view, "#economy-related-tax-exemptions article")

    {:ok, view, _html} =
      live(
        conn,
        ~p"/worlds/#{economy.world}/dashboard?section=economy&trade_route_id=#{route.id}"
      )

    assert has_element?(view, "#economy-detail-fields")
    assert has_element?(view, "#economy-related-trade-flows article")

    view
    |> form("#trade-route-form", trade_route: %{name: "Green King Road"})
    |> render_submit()

    assert Repo.get!(TradeRoute, route.id).name == "Green King Road"
    view |> element("#delete-trade_route-#{route.id}") |> render_click()
    refute Repo.get(TradeRoute, route.id)
  end

  defp create_economy do
    {:ok, world} = Worlds.create_world(%{name: "Aldrun"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Thyrven"})
    {:ok, currency} = Worlds.put_continent_currency(continent, %{name: "Frostmark"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Frostgard"})
    {:ok, origin_hold} = Worlds.create_hold(province, %{name: "Gronvale"})
    {:ok, destination_hold} = Worlds.create_hold(province, %{name: "Smidvang"})

    {:ok, office} =
      Worlds.create_political_office(world, %{office: "Toll Keeper", scope: "hold"}, %{
        hold: destination_hold
      })

    %{
      world: world,
      currency: currency,
      origin_hold: origin_hold,
      destination_hold: destination_hold,
      office: office
    }
  end
end
