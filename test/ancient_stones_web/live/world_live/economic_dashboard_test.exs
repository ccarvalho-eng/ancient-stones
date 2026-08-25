defmodule AncientStonesWeb.WorldLive.EconomicDashboardTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.CommodityBalance
  alias AncientStones.Worlds.HoldEconomicProfile
  alias AncientStones.Worlds.TaxAssessment
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

  test "manages aggregate profiles, balances, assessments, and search", %{conn: conn} do
    economy = create_economy()

    {:ok, policy} =
      Worlds.create_tax_policy(
        economy.world,
        %{name: "Harvest Levy", tax_type: :land_levy, rate_basis: :percentage, rate: 6},
        %{hold: economy.origin_hold, currency: economy.currency}
      )

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=profile")

    assert has_element?(view, "#hold-economic-profile-form")

    view
    |> form("#hold-economic-profile-form",
      hold_economic_profile: %{
        hold_id: economy.origin_hold.id,
        population_estimate: 24_000,
        household_estimate: 4_900,
        urban_population_estimate: 3_200,
        staple_reserve_months: "3.5",
        assessment_label: "Late harvest estimate",
        confidence: "medium"
      }
    )
    |> render_submit()

    profile = Repo.get_by!(HoldEconomicProfile, hold_id: economy.origin_hold.id)
    assert has_element?(view, "#economy-hold_economic_profile-#{profile.id}")

    view
    |> element("#economy-hold_economic_profile-#{profile.id}")
    |> render_click()

    view
    |> form("#hold-economic-profile-form",
      hold_economic_profile: %{population_estimate: 25_000}
    )
    |> render_submit()

    assert Repo.get!(HoldEconomicProfile, profile.id).population_estimate == 25_000

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=balance")

    view
    |> form("#commodity-balance-form",
      commodity_balance: %{
        hold_id: economy.origin_hold.id,
        commodity: "Rye equivalent",
        category: "staple food",
        unit: "tonne",
        annual_output: 5_100,
        annual_local_need: 4_600,
        stored_reserve: 900,
        bad_year_output_percentage: 62,
        storage_loss_percentage: 8,
        status: "active"
      }
    )
    |> render_submit()

    balance = Repo.get_by!(CommodityBalance, commodity: "Rye equivalent")
    assert has_element?(view, "#economy-commodity_balance-#{balance.id}")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=assessment")

    view
    |> form("#tax-assessment-form",
      tax_assessment: %{
        tax_policy_id: policy.id,
        currency_id: economy.currency.id,
        assessment_period_label: "Common year 312",
        cash_yield: 8_400,
        in_kind_value: 11_600,
        customary_labor_days: 2_900,
        confidence: "medium"
      }
    )
    |> render_submit()

    assessment = Repo.get_by!(TaxAssessment, tax_policy_id: policy.id)
    assert has_element?(view, "#economy-tax_assessment-#{assessment.id}")

    view
    |> form("#dashboard-search-form-mobile", search: %{query: "no matching assessment"})
    |> render_change()

    refute has_element?(view, "#economy-tax_assessment-#{assessment.id}")
    assert has_element?(view, "#economy-tax_assessment-empty")
  end

  test "rejects forged economic references from another world", %{conn: conn} do
    economy = create_economy()
    other = create_economy("Veyra")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{economy.world}/dashboard?section=economy&mode=profile")

    render_submit(view, "save_hold_economic_profile", %{
      "hold_economic_profile" => %{
        "hold_id" => other.origin_hold.id,
        "population_estimate" => 1_000,
        "household_estimate" => 200,
        "urban_population_estimate" => 100,
        "assessment_label" => "Forged estimate"
      }
    })

    refute Repo.get_by(HoldEconomicProfile, hold_id: other.origin_hold.id)
  end

  defp create_economy(world_name \\ "Aldrun") do
    {:ok, world} = Worlds.create_world(%{name: world_name})
    {:ok, continent} = Worlds.create_continent(world, %{name: "#{world_name} Reach"})
    {:ok, currency} = Worlds.put_continent_currency(continent, %{name: "#{world_name} Mark"})
    {:ok, province} = Worlds.create_province(continent, %{name: "#{world_name} March"})
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
