defmodule AncientStonesWeb.WorldLive.DashboardTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.CalendarMonth
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.CreatureLocation
  alias AncientStones.Worlds.CreatureType
  alias AncientStones.Worlds.Document
  alias AncientStones.Worlds.Effect
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.GuildInfluence
  alias AncientStones.Worlds.CharacterInventoryCategory
  alias AncientStones.Worlds.CharacterInventoryItem
  alias AncientStones.Worlds.CharacterRole
  alias AncientStones.Worlds.ContinentCurrency
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.HoldCommerceEntry
  alias AncientStones.Worlds.Item
  alias AncientStones.Worlds.ItemEffect
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.Moon
  alias AncientStones.Worlds.Occupation
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.LoreConnection
  alias AncientStones.Worlds.Skill
  alias AncientStones.Worlds.SkillLevel
  alias AncientStones.Worlds.SkillTreePerk
  alias AncientStones.Worlds.Spell
  alias AncientStones.Worlds.Timeline
  alias AncientStones.Worlds.TimelineEvent

  test "renders the geography dashboard", %{conn: conn} do
    world = create_world!()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    assert has_element?(view, "#geography-dashboard.stone-theme-system")
    assert has_element?(view, "#geography-dashboard[phx-hook='AncientStonesTheme']")

    assert has_element?(
             view,
             "#geography-tree[data-storage-key='ancient-stones:world:#{world.id}:geography-disclosures'][data-disclosure-ready='false']"
           )

    assert has_element?(view, "#action-list")
    assert has_element?(view, "#continent-form")
    refute has_element?(view, "#province-form")
    refute has_element?(view, "button[phx-value-action='province']")
    refute has_element?(view, "button[phx-value-action='hold']")
    refute has_element?(view, "button[phx-value-action='location']")

    open_action(view, "continent")

    refute has_element?(view, "#continent-form")
  end

  test "renders geography cards collapsed regardless of the selected path", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    continent = hd(dashboard.continents)
    province = hd(continent.provinces)

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    assert has_element?(view, "details#geography-continent-#{continent.id}:not([open])")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?province_id=#{province.id}")

    assert has_element?(view, "details#geography-continent-#{continent.id}:not([open])")
    assert has_element?(view, "details#geography-province-#{province.id}:not([open])")
  end

  test "updates world name from the action form", %{conn: conn} do
    world = create_world!()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    open_action(view, "world")
    assert has_element?(view, "#world_name[value='Eldoria']")

    view
    |> form("#dashboard-world-form", world: %{name: "Eldoria Prime"})
    |> render_submit()

    assert has_element?(view, "#world_name[value='Eldoria Prime']")
    assert Worlds.get_world!(world.id).name == "Eldoria Prime"
  end

  test "updates galaxy name from the action form", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    open_action(view, "galaxy")
    assert has_element?(view, "#dashboard-galaxy-form")

    world = Worlds.get_world_dashboard!(world.id)
    assert world.galaxy
    assert has_element?(view, "#galaxy_name[value='#{world.galaxy.name}']")

    view
    |> form("#dashboard-galaxy-form", galaxy: %{name: "Mundus Prime"})
    |> render_submit()

    assert has_element?(view, "#galaxy_name[value='Mundus Prime']")
    assert Worlds.get_world_dashboard!(world.id).galaxy.name == "Mundus Prime"
  end

  test "shows worlds as the breadcrumb parent for a world with a galaxy", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    assert has_element?(view, "nav[aria-label='Breadcrumb'] a", "Worlds")
    assert has_element?(view, "nav[aria-label='Breadcrumb'] span", "Northern Realm")
  end

  test "does not show galaxy action form for worlds without a galaxy", %{conn: conn} do
    world = create_world!()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    refute has_element?(view, "#dashboard-galaxy-form")
  end

  test "searches every populated dashboard section without crashing", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})

    for section <- [
          "geography",
          "races",
          "guilds",
          "gods",
          "civilizations",
          "documents",
          "connections",
          "characters",
          "skills",
          "spells",
          "items",
          "bestiary",
          "calendar",
          "timeline"
        ] do
      {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=#{section}")

      view
      |> form("#dashboard-search-form", search: %{query: "a"})
      |> render_change()

      assert has_element?(view, "#dashboard-search-query[value='a']")
    end
  end

  test "creates geography records from dashboard forms", %{conn: conn} do
    world = create_world!()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    view
    |> form("#continent-form",
      continent: %{
        name: "Tamriel",
        description: "A vast continent",
        map_x: -20,
        map_y: 35,
        visibility: "known"
      }
    )
    |> render_submit()

    world = Worlds.get_world_dashboard!(world.id)
    [continent] = world.continents
    assert continent.map_x == -20
    assert continent.map_y == 35
    assert continent.visibility == :known

    open_action(view, "province")

    view
    |> form("#province-form",
      province: %{
        continent_id: continent.id,
        name: "Skyrim",
        terrain: "mountain",
        climate: "cold",
        description: "A cold northern province",
        map_x: -12,
        map_y: 42,
        visibility: "rumored"
      }
    )
    |> render_submit()

    world = Worlds.get_world_dashboard!(world.id)
    [continent] = world.continents
    [province] = continent.provinces
    assert province.map_x == -12
    assert province.map_y == 42
    assert province.visibility == :rumored

    open_action(view, "hold")

    view
    |> form("#hold-form",
      hold: %{
        province_id: province.id,
        name: "Whiterun",
        terrain: "plains",
        climate: "temperate",
        description: "Central open tundra",
        map_x: 4,
        map_y: 18,
        visibility: "hidden"
      }
    )
    |> render_submit()

    dashboard = Worlds.get_world_dashboard!(world.id)
    [continent] = dashboard.continents
    [province] = continent.provinces
    [hold] = province.holds

    assert hold.name == "Whiterun"
    assert hold.map_x == 4
    assert hold.map_y == 18
    assert hold.visibility == :hidden

    assert has_element?(
             view,
             "#province-geography-#{province.id}.grid-cols-2"
           )

    assert has_element?(
             view,
             "#province-geography-#{province.id}-terrain .hero-arrow-trending-up"
           )

    assert has_element?(view, "#province-geography-#{province.id}-climate .hero-cloud")
    assert has_element?(view, "#hold-geography-#{hold.id}.grid-cols-2")
    assert has_element?(view, "#hold-geography-#{hold.id}-terrain .hero-minus")
    assert has_element?(view, "#hold-geography-#{hold.id}-climate .hero-sun")
  end

  test "clears geography create forms after creation", %{conn: conn} do
    world = create_world!()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    view
    |> form("#continent-form",
      continent: %{
        name: "Tamriel",
        description: "A vast continent"
      }
    )
    |> render_submit()

    refute has_element?(view, "#continent_name[value='Tamriel']")
    refute has_element?(view, "#continent_description", "A vast continent")

    [continent] = Worlds.get_world_dashboard!(world.id).continents

    open_action(view, "province")

    view
    |> form("#province-form",
      province: %{
        continent_id: continent.id,
        name: "Skyrim",
        terrain: "mountain",
        climate: "cold",
        description: "A cold northern province"
      }
    )
    |> render_submit()

    refute has_element?(view, "#province_name[value='Skyrim']")
    refute has_element?(view, "#province_description", "A cold northern province")

    [continent] = Worlds.get_world_dashboard!(world.id).continents
    [province] = continent.provinces

    open_action(view, "hold")

    view
    |> form("#hold-form",
      hold: %{
        province_id: province.id,
        name: "Whiterun",
        terrain: "plains",
        climate: "temperate",
        description: "Central open tundra"
      }
    )
    |> render_submit()

    refute has_element?(view, "#hold_name[value='Whiterun']")
    refute has_element?(view, "#hold_description", "Central open tundra")
  end

  test "saves selected provinces and holds from their dashboard forms", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?continent_id=#{continent.id}")

    assert has_element?(view, "#continent-form button", "Save")
    assert has_element?(view, "#continent_name[value='Tamriel']")

    view
    |> form("#continent-form",
      continent: %{
        name: "Greater Tamriel",
        description: "Edited continent",
        map_x: -30,
        map_y: 45,
        visibility: "lost",
        currency_name: "Frostmarks",
        currency_description: "Stamped silver rings traded by weight",
        currency_value_per_unit: "1.00",
        currency_value_basis: "hearth-day"
      }
    )
    |> render_submit()

    continent = Repo.get!(Continent, continent.id)
    currency = Repo.get_by!(ContinentCurrency, continent_id: continent.id)

    assert continent.name == "Greater Tamriel"
    assert continent.description == "Edited continent"
    assert continent.map_x == -30
    assert continent.map_y == 45
    assert continent.visibility == :lost
    assert currency.name == "Frostmarks"
    assert currency.description == "Stamped silver rings traded by weight"
    assert Decimal.equal?(currency.value_per_unit, Decimal.new("1.00"))
    assert currency.value_basis == "hearth-day"
    assert has_element?(view, "#continent-details", "Frostmarks")
    assert has_element?(view, "#continent-details", "1 hearth-day")
    assert has_element?(view, "#continent-details", "X -30, Y 45")
    assert has_element?(view, "#continent-details", "Lost")

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?province_id=#{province.id}")

    assert has_element?(view, "#province-form button", "Save")
    assert has_element?(view, "#province_name[value='Skyrim']")

    view
    |> form("#province-form",
      province: %{
        continent_id: continent.id,
        name: "Northern Skyrim",
        terrain: "mountain",
        climate: "cold",
        description: "Edited province",
        map_x: -11,
        map_y: 39,
        visibility: "rumored"
      }
    )
    |> render_submit()

    province = Repo.get!(Province, province.id)

    assert province.name == "Northern Skyrim"
    assert province.description == "Edited province"
    assert province.map_x == -11
    assert province.map_y == 39
    assert province.visibility == :rumored

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{hold.id}")

    assert has_element?(view, "#hold-form button", "Save")
    assert has_element?(view, "#hold_name[value='Whiterun']")

    view
    |> form("#hold-form",
      hold: %{
        province_id: province.id,
        name: "Greater Whiterun",
        terrain: "plains",
        climate: "temperate",
        description: "Edited hold",
        map_x: 8,
        map_y: 16,
        visibility: "hidden",
        province_capital: "false"
      }
    )
    |> render_submit()

    hold = Repo.get!(Hold, hold.id)

    assert hold.name == "Greater Whiterun"
    assert hold.description == "Edited hold"
    assert hold.map_x == 8
    assert hold.map_y == 16
    assert hold.visibility == :hidden
  end

  test "shows province politics in province and continent details", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, skyrim} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, cyrodiil} = Worlds.create_province(continent, %{name: "Cyrodiil"})
    {:ok, whiterun} = Worlds.create_hold(skyrim, %{name: "Whiterun"})
    {:ok, high_king} = Worlds.create_character(world, %{name: "Eirik Frost-Crowned"})
    {:ok, chancellor} = Worlds.create_character(world, %{name: "Valdemar Reed-Speaker"})
    {:ok, jarl} = Worlds.create_character(world, %{name: "Hakon Wave-Bound"})

    {:ok, _office} =
      Worlds.create_political_office(
        world,
        %{
          office: "High King",
          scope: "province",
          politics: "Crown Moot",
          description: "Chosen by jarls and oath-speakers"
        },
        %{province: skyrim, character: high_king}
      )

    {:ok, _office} =
      Worlds.create_political_office(
        world,
        %{
          office: "Chancellor",
          scope: "province",
          politics: "Gold Road Council",
          description: "Keeps the imperial road ledgers"
        },
        %{province: cyrodiil, character: chancellor}
      )

    {:ok, _office} =
      Worlds.create_political_office(
        world,
        %{
          office: "Jarl",
          scope: "hold",
          politics: "Fjord Clans",
          description: "Rules the hold moot"
        },
        %{hold: whiterun, character: jarl}
      )

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?province_id=#{skyrim.id}")

    assert has_element?(view, "#province-political-office-details", "High King")
    assert has_element?(view, "#province-political-office-details", "Eirik Frost-Crowned")
    assert has_element?(view, "#province-political-office-details", "Crown Moot")

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{whiterun.id}")

    assert has_element?(view, "#political-office-details", "Hold Offices")
    assert has_element?(view, "#political-office-details", "Hakon Wave-Bound")
    refute has_element?(view, "#political-office-details", "High King")

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?continent_id=#{continent.id}")

    assert has_element?(view, "#continent-political-office-details", "Skyrim")
    assert has_element?(view, "#continent-political-office-details", "Eirik Frost-Crowned")
    assert has_element?(view, "#continent-political-office-details", "Cyrodiil")
    assert has_element?(view, "#continent-political-office-details", "Valdemar Reed-Speaker")
  end

  test "sets and clears a selected hold as the province capital from the hold form", %{
    conn: conn
  } do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{hold.id}")

    assert has_element?(view, "#hold_province_capital")

    view
    |> form("#hold-form",
      hold: %{
        province_id: province.id,
        name: "Whiterun",
        terrain: "plains",
        climate: "temperate",
        description: "Central open tundra",
        province_capital: "true"
      }
    )
    |> render_submit()

    province = Repo.get!(Province, province.id)

    assert province.capital_hold_id == hold.id
    assert has_element?(view, "#hold-details", "Province Capital")
    assert has_element?(view, "#hold-details", "Yes")

    view
    |> form("#hold-form",
      hold: %{
        province_id: province.id,
        name: "Whiterun",
        terrain: "plains",
        climate: "temperate",
        description: "Central open tundra",
        province_capital: "false"
      }
    )
    |> render_submit()

    province = Repo.get!(Province, province.id)

    refute province.capital_hold_id
  end

  test "selecting geography records expands the matching action form", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})
    {:ok, whiterun} = Worlds.create_location(hold, city, %{name: "Whiterun"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    assert has_element?(view, "#continent-form")

    view
    |> element("a[href='#{~p"/worlds/#{world}/dashboard?continent_id=#{continent.id}"}']")
    |> render_click()

    assert has_element?(view, "#continent-form button", "Save")

    view
    |> element("a[href='#{~p"/worlds/#{world}/dashboard?province_id=#{province.id}"}']")
    |> render_click()

    assert has_element?(view, "#province-form button", "Save")
    refute has_element?(view, "#continent-form")

    view
    |> element("a[href='#{~p"/worlds/#{world}/dashboard?hold_id=#{hold.id}"}']")
    |> render_click()

    assert has_element?(view, "#hold-form button", "Save")
    refute has_element?(view, "#province-form")

    view
    |> element(
      "a[href='#{~p"/worlds/#{world}/dashboard?hold_id=#{hold.id}&location_id=#{whiterun.id}"}']"
    )
    |> render_click()

    assert has_element?(view, "#location-edit-form button", "Save")
    refute has_element?(view, "#hold-form")
  end

  test "creates location types and capital locations", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{hold.id}")

    open_action(view, "location_type")

    view
    |> form("#location-type-form",
      location_type: %{
        parent_id: "",
        name: "City",
        description: "Major settlements"
      }
    )
    |> render_submit()

    [city] = Worlds.list_location_types(world)

    open_action(view, "location")

    view
    |> form("#location-form",
      location: %{
        hold_id: hold.id,
        location_type_id: city.id,
        parent_location_id: "",
        name: "Whiterun",
        description: "The hold capital",
        map_x: 6,
        map_y: 17,
        visibility: "known",
        capital: "true"
      }
    )
    |> render_submit()

    dashboard = Worlds.get_world_dashboard!(world.id)
    [continent] = dashboard.continents
    [province] = continent.provinces
    [hold] = province.holds

    assert hold.capital_location.name == "Whiterun"
    assert hold.capital_location.map_x == 6
    assert hold.capital_location.map_y == 17
    assert hold.capital_location.visibility == :known
  end

  test "does not create child location types under another world", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, other_world} = Worlds.create_world_from_template(:blank, %{name: "Other Realm"})
    {:ok, other_parent} = Worlds.create_location_type(other_world, %{name: "Foreign Type"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    render_submit(view, "create_location_type",
      location_type: %{
        parent_id: other_parent.id,
        name: "Cross World Child",
        description: "Should not be created"
      }
    )

    refute Repo.get_by(LocationType, name: "Cross World Child")
  end

  test "creates and deletes hold commerce entries", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{hold.id}")

    open_action(view, "commerce")

    view
    |> form("#commerce-form",
      commerce: %{
        name: "Market taxes",
        kind: "income",
        category: "trade",
        amount: 1200,
        currency: "Septims",
        frequency: "monthly",
        description: "Collected from local stalls"
      }
    )
    |> render_submit()

    commerce_entry = Repo.get_by!(HoldCommerceEntry, name: "Market taxes")

    assert has_element?(view, "#hold-commerce-details", "Market taxes")
    assert has_element?(view, "#hold-commerce-details", "1200 net Septims")

    view
    |> element("button[phx-click='delete_commerce'][phx-value-id='#{commerce_entry.id}']")
    |> render_click()

    refute Repo.get(HoldCommerceEntry, commerce_entry.id)
  end

  test "converts between continent currencies", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, north} = Worlds.create_continent(world, %{name: "North"})
    {:ok, marsh} = Worlds.create_continent(world, %{name: "Marsh"})

    {:ok, frostmarks} =
      Worlds.put_continent_currency(north, %{
        name: "Frostmarks",
        description: "Stamped silver rings",
        value_per_unit: "1.00",
        value_basis: "hearth-day"
      })

    {:ok, reedmarks} =
      Worlds.put_continent_currency(marsh, %{
        name: "Reedmarks",
        description: "Reed-bronze slivers",
        value_per_unit: "0.20",
        value_basis: "hearth-day"
      })

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?continent_id=#{north.id}")

    assert has_element?(view, "#currency-converter")
    assert has_element?(view, "#currency-converter-result", "1 Frostmarks")
    assert has_element?(view, "#currency-converter-result", "5 Reedmarks")

    view
    |> form("#currency-converter-form",
      currency_converter: %{
        amount: "2",
        from_currency_id: reedmarks.id,
        to_currency_id: frostmarks.id
      }
    )
    |> render_change()

    assert has_element?(view, "#currency-converter-result", "2 Reedmarks")
    assert has_element?(view, "#currency-converter-result", "0.4 Frostmarks")
    assert has_element?(view, "#currency-converter-result", "1 Reedmarks = 0.2 Frostmarks")
  end

  test "location actions follow the selected hold", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, whiterun} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, eastmarch} = Worlds.create_hold(province, %{name: "Eastmarch"})
    {:ok, tower} = Worlds.create_location_type(world, %{name: "Tower"})

    {:ok, western_watchtower} =
      Worlds.create_location(whiterun, tower, %{name: "Western Watchtower"})

    {:ok, windhelm_watchtower} =
      Worlds.create_location(eastmarch, tower, %{name: "Windhelm Watchtower"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{whiterun.id}")

    open_action(view, "location")

    assert has_element?(
             view,
             "#location_parent_location_id option[value='#{western_watchtower.id}']"
           )

    refute has_element?(
             view,
             "#location_parent_location_id option[value='#{windhelm_watchtower.id}']"
           )
  end

  test "edits a selected location and clears capital status", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    province = skyrim_province(dashboard)
    whiterun = Enum.find(province.holds, &(&1.name == "Whiterun"))
    capital = whiterun.capital_location

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{whiterun.id}&location_id=#{capital.id}")

    view
    |> form("#location-edit-form",
      location_edit: %{
        location_type_id: capital.location_type_id,
        name: "Whiterun",
        description: "Major trade city",
        map_x: 12,
        map_y: -3,
        visibility: "rumored",
        capital: "false"
      }
    )
    |> render_submit()

    hold = Repo.get!(Hold, whiterun.id)
    location = Repo.get!(Location, capital.id)

    refute hold.capital_location_id
    assert location.description == "Major trade city"
    assert location.map_x == 12
    assert location.map_y == -3
    assert location.visibility == :rumored
  end

  test "nested locations render once in the selected hold list", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, ruin} = Worlds.create_location_type(world, %{name: "Nordic Ruin"})
    {:ok, barrow} = Worlds.create_location(hold, ruin, %{name: "Bleak Falls Barrow"})
    {:ok, _sanctum} = Worlds.create_child_location(barrow, ruin, %{name: "Sanctum"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{hold.id}")

    location_names =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#location-list a")
      |> Enum.map(&LazyHTML.text/1)

    assert Enum.count(location_names, &String.contains?(&1, "Sanctum")) == 1
  end

  test "renders race details with powers and perks", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    nord = Enum.find(dashboard.races, &(&1.name == "Nord"))

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=races&race_id=#{nord.id}")

    assert has_element?(view, "#races-dashboard")
    assert has_element?(view, "#race-details", "Nord")
    assert has_element?(view, "#race-details", "Battle Cry")
    assert has_element?(view, "#race-details", "Resist Frost")
  end

  test "creates and deletes races from the races section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, civilization} = Worlds.create_civilization(world, %{name: "Atmorans"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=races")

    assert has_element?(view, "#race-form")
    assert has_element?(view, "#race_civilization_id")
    assert has_element?(view, "#add-race-trait")
    assert has_element?(view, "#race_traits_0_category option[value='perk']", "Perk")
    assert has_element?(view, "#race_traits_0_category option[value='power']", "Power")
    assert has_element?(view, "#race_traits_0_name")

    view
    |> element("#add-race-trait")
    |> render_click()

    view
    |> element("#add-race-trait")
    |> render_click()

    view
    |> element("#add-race-trait")
    |> render_click()

    assert has_element?(view, "#race-trait-row-1")
    assert has_element?(view, "#race-trait-row-2")
    assert has_element?(view, "#race-trait-row-3")

    view
    |> form("#race-form",
      race: %{
        civilization_id: civilization.id,
        name: "Snowborn",
        description: "People adapted to high mountain winters",
        traits: %{
          "0" => %{
            category: "power",
            name: "Whiteout",
            description: "Disappear into heavy snow"
          },
          "1" => %{
            category: "perk",
            name: "Resist Frost",
            description: "Shrug off bitter cold"
          },
          "2" => %{
            category: "power",
            name: "Blizzard Voice",
            description: "Drive enemies back with winter breath"
          },
          "3" => %{
            category: "perk",
            name: "Mountain Step",
            description: "Move confidently on steep rock and ice"
          }
        }
      }
    )
    |> render_submit()

    dashboard = Worlds.get_world_dashboard!(world.id)
    race = Enum.find(dashboard.races, &(&1.name == "Snowborn"))

    assert has_element?(view, "#race-list", "Snowborn")
    assert Enum.any?(race.civilization_races, &(&1.civilization.name == "Atmorans"))

    assert Enum.any?(
             race.traits,
             &(&1.name == "Whiteout" && &1.category == :power &&
                 &1.description == "Disappear into heavy snow")
           )

    assert Enum.any?(
             race.traits,
             &(&1.name == "Blizzard Voice" && &1.category == :power &&
                 &1.description == "Drive enemies back with winter breath")
           )

    assert Enum.any?(
             race.traits,
             &(&1.name == "Resist Frost" && &1.category == :perk &&
                 &1.description == "Shrug off bitter cold")
           )

    assert Enum.any?(
             race.traits,
             &(&1.name == "Mountain Step" && &1.category == :perk &&
                 &1.description == "Move confidently on steep rock and ice")
           )

    view
    |> element("button[phx-click='delete_race'][phx-value-id='#{race.id}']")
    |> render_click()

    refute Repo.get(Race, race.id)
  end

  test "links to civilizations when creating a race without civilization options", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=races")

    assert has_element?(view, "#race-form")

    assert has_element?(
             view,
             "#race-civilization-empty a[href='/worlds/#{world.id}/dashboard?section=civilizations']",
             "Add a civilization"
           )

    refute has_element?(view, "#race_civilization_id")
  end

  test "renders guild details from the guilds section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    companions = Enum.find(dashboard.guilds, &(&1.name == "Companions"))

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=guilds&guild_id=#{companions.id}")

    assert has_element?(view, "#guilds-dashboard")
    assert has_element?(view, "#guild-details", "Companions")
    assert has_element?(view, "#guild-details", "warrior fellowship")
  end

  test "creates and deletes guilds from the guilds section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=guilds")

    open_action(view, "guild")

    view
    |> form("#guild-form",
      guild: %{
        name: "Silver Circle",
        description: "A compact order of mercenary scholars"
      }
    )
    |> render_submit()

    guild = Repo.get_by!(Guild, name: "Silver Circle")

    assert has_element?(view, "#guild-list", "Silver Circle")

    view
    |> element("button[phx-click='delete_guild'][phx-value-id='#{guild.id}']")
    |> render_click()

    refute Repo.get(Guild, guild.id)
  end

  test "creates and deletes guild influences", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, guild} = Worlds.create_guild(world, %{name: "Silver Circle"})
    {:ok, god} = Worlds.create_god(world, %{name: "Kyne", pantheon: "Nordic Pantheon"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=guilds")

    open_action(view, "guild_influence")

    view
    |> form("#guild-influence-form",
      guild_influence: %{
        guild_id: guild.id,
        god_id: god.id,
        character_id: "",
        relationship: "serves",
        description: "Keeps storm rites"
      }
    )
    |> render_submit()

    influence = Repo.get_by!(GuildInfluence, relationship: "serves")

    assert has_element?(view, "#guild-details", "Kyne")

    view
    |> element("button[phx-click='delete_guild_influence'][phx-value-id='#{influence.id}']")
    |> render_click()

    refute Repo.get(GuildInfluence, influence.id)
  end

  test "creates gods from the gods section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=gods")

    view
    |> form("#god-form",
      god: %{
        name: "Jhunal",
        pantheon: "Nordic Pantheon",
        domain: "runes",
        description: "A god of runes and learning"
      }
    )
    |> render_submit()

    assert Repo.get_by!(God, name: "Jhunal").domain == "runes"
    assert has_element?(view, "#god-list", "Jhunal")
  end

  test "creates documents and connections from dashboard sections", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, character} = Worlds.create_character(world, %{name: "Maven Black-Briar"})
    {:ok, guild} = Worlds.create_guild(world, %{name: "Thieves Guild"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "The Rift"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})
    {:ok, riften} = Worlds.create_location(hold, city, %{name: "Riften"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=documents")

    assert has_element?(view, "#document_kind option[value='book']", "Book")
    assert has_element?(view, "#document_kind option[value='journal']", "Journal")
    assert has_element?(view, "#document_kind option[value='prophecy']", "Prophecy")

    view
    |> form("#document-form",
      document: %{
        title: "Black-Briar Correspondence",
        kind: "note",
        source: "Skyrim",
        author_character_id: character.id,
        location_id: riften.id,
        guild_id: guild.id,
        summary: "A note about Riften influence.",
        content: "Maven keeps her allies close."
      }
    )
    |> render_submit()

    document = Repo.get_by!(Document, title: "Black-Briar Correspondence")

    assert document.author_character_id == character.id
    assert document.guild_id == guild.id
    assert has_element?(view, "#document-reader", "Black-Briar Correspondence")
    assert has_element?(view, "#document-reader", "Maven keeps her allies close.")
    assert has_element?(view, "#folded-documents-note:not([open])")

    view
    |> element("#folded-documents-note summary")
    |> render_click()

    assert has_element?(view, "#folded-documents-note[open]")
    assert has_element?(view, "#document-list", "Black-Briar Correspondence")

    view
    |> form("#dashboard-search-form", search: %{query: "allies close"})
    |> render_change()

    assert has_element?(view, "#document-list", "Black-Briar Correspondence")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=documents&document_id=#{document.id}")

    assert has_element?(view, "#document-edit-form")

    edit_params = %{
      title: "Black-Briar Ledger",
      kind: "journal",
      source: "Riften Archive",
      author_character_id: character.id,
      location_id: riften.id,
      guild_id: guild.id,
      god_id: "",
      race_id: "",
      civilization_id: "",
      summary: "A ledger tracing Riften influence.",
      content: "The ledger names every quiet bargain."
    }

    view
    |> form("#document-edit-form", document_edit: edit_params)
    |> render_change()

    assert has_element?(view, "#document-reader", "Black-Briar Ledger")
    assert has_element?(view, "#document-reader", "The ledger names every quiet bargain.")
    assert Repo.get!(Document, document.id).title == "Black-Briar Correspondence"

    view
    |> form("#document-edit-form", document_edit: edit_params)
    |> render_submit()

    document = Repo.get!(Document, document.id)

    assert document.title == "Black-Briar Ledger"
    assert document.content == "The ledger names every quiet bargain."

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=connections")

    view
    |> form("#connection-form",
      lore_connection: %{
        name: "Black-Briar Patronage",
        source_entity: "character:#{character.id}",
        target_entity: "guild:#{guild.id}",
        connection_type: "patron",
        status: "active",
        description: "Maven protects and uses the Thieves Guild."
      }
    )
    |> render_submit()

    lore_connection =
      LoreConnection
      |> Repo.get_by!(name: "Black-Briar Patronage")
      |> Repo.preload([:source_character, :target_guild])

    assert lore_connection.source_character.name == "Maven Black-Briar"
    assert lore_connection.target_guild.name == "Thieves Guild"
    assert lore_connection.connection_type == "patron"

    view
    |> form("#connection-form",
      lore_connection: %{
        name: "Riften Protection",
        source_entity: "character:#{character.id}",
        target_entity: "location:#{riften.id}",
        connection_type: "patron",
        status: "active",
        description: "Maven's influence protects commerce throughout Riften."
      }
    )
    |> render_submit()

    assert has_element?(view, "#folded-connections-character:not([open])")

    assert has_element?(
             view,
             "#folded-connections-character summary",
             "2"
           )

    view
    |> element("#folded-connections-character summary")
    |> render_click()

    assert has_element?(view, "#folded-connections-character[open]")

    assert has_element?(
             view,
             "#connection-#{lore_connection.id}",
             "Character / Maven Black-Briar"
           )

    assert has_element?(view, "#connection-list", "Black-Briar Patronage")
    assert has_element?(view, "#connection-list", "Riften Protection")

    view
    |> element("#connection-#{lore_connection.id} a")
    |> render_click()

    assert has_element?(view, "#connection-edit-form")

    assert has_element?(
             view,
             "#connection-type-description",
             "provides protection, resources, status, or access"
           )

    view
    |> form("#connection-edit-form",
      lore_connection_edit: %{
        name: "Black-Briar Compact",
        source_entity: "character:#{character.id}",
        target_entity: "guild:#{guild.id}",
        connection_type: "patron",
        status: "tense",
        started_at: "4E 201",
        ended_at: "",
        description: "Maven's compact with the guild has become strained."
      }
    )
    |> render_submit()

    lore_connection = Repo.get!(LoreConnection, lore_connection.id)
    assert lore_connection.name == "Black-Briar Compact"
    assert lore_connection.status == "tense"
    assert has_element?(view, "#connection-details", "Black-Briar Compact")
  end

  test "creates characters from the characters section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, race} = Worlds.create_race(world, %{name: "Nord"})
    {:ok, guild} = Worlds.create_guild(world, %{name: "Stormcloaks"})
    {:ok, character_role} = Worlds.create_character_role(world, %{name: "Jarl"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Eastmarch"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})
    {:ok, windhelm} = Worlds.create_location(hold, city, %{name: "Windhelm"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=characters")

    open_action(view, "occupation")

    view
    |> form("#occupation-form",
      occupation: %{
        name: "Jarl",
        category: "governance",
        description: "Ruler of a hold"
      }
    )
    |> render_submit()

    open_action(view, "skill")

    view
    |> form("#skill-form",
      skill: %{
        name: "Speech",
        category: "social",
        description: "Persuasion and command"
      }
    )
    |> render_submit()

    occupation = Repo.get_by!(Occupation, name: "Jarl")
    skill = Repo.get_by!(Skill, name: "Speech")

    open_action(view, "character")

    assert has_element?(view, "#character_status option[value='alive']", "Alive")
    assert has_element?(view, "#character_status option[value='dead']", "Dead")
    assert has_element?(view, "#character_status option[value='unknown']", "Unknown")
    assert has_element?(view, "#character_gender option[value='female']", "Female")
    assert has_element?(view, "#character_gender option[value='male']", "Male")

    view
    |> form("#character-form",
      character: %{
        name: "Ulfric Stormcloak",
        gender: "male",
        title: "Jarl of Windhelm",
        character_role_id: character_role.id,
        politics: "Stormcloak",
        status: "alive",
        race_id: race.id,
        guild_id: guild.id,
        home_location_id: windhelm.id,
        occupation_id: occupation.id,
        skill_id: skill.id,
        description: "A rebel jarl"
      }
    )
    |> render_submit()

    character = Repo.get_by!(Character, name: "Ulfric Stormcloak")

    character =
      Repo.preload(character, [
        :home_location,
        character_occupations: [:occupation],
        character_skills: [:skill]
      ])

    assert character.home_location.name == "Windhelm"
    assert character.character_role_id == character_role.id
    assert character.role == "Jarl"
    assert character.gender == "male"
    assert Enum.any?(character.character_occupations, &(&1.occupation.name == "Jarl"))
    assert Enum.any?(character.character_skills, &(&1.skill.name == "Speech"))
    assert has_element?(view, "#character-list", "Ulfric Stormcloak")
  end

  test "saves selected characters from the character form", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, nord} = Worlds.create_race(world, %{name: "Nord"})
    {:ok, breton} = Worlds.create_race(world, %{name: "Breton"})
    {:ok, ruler} = Worlds.create_character_role(world, %{name: "Ruler"})
    {:ok, high_king} = Worlds.create_character_role(world, %{name: "High King"})
    {:ok, guild} = Worlds.create_guild(world, %{name: "Crown Moot"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tysttind"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Frostgard"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Nordhavn"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})
    {:ok, hall} = Worlds.create_location(hold, city, %{name: "High Hall"})

    {:ok, character} =
      Worlds.create_character(
        world,
        %{
          name: "Eirik Frost-Crowned",
          gender: "male",
          title: "High King",
          politics: "Crown Moot",
          status: "alive",
          description: "An oath-bound king"
        },
        %{race: nord, character_role: ruler}
      )

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=characters&character_id=#{character.id}")

    assert has_element?(view, "#character-form button", "Save")
    assert has_element?(view, "#character_name[value='Eirik Frost-Crowned']")

    view
    |> form("#character-form",
      character: %{
        name: "Eirik Ring-Keeper",
        gender: "male",
        title: "High King of Frostgard",
        character_role_id: high_king.id,
        politics: "Crown Moot",
        status: "alive",
        race_id: breton.id,
        guild_id: guild.id,
        home_location_id: hall.id,
        occupation_id: "",
        skill_id: "",
        description: "Bearer of the Frostmark oath"
      }
    )
    |> render_submit()

    character =
      Character
      |> Repo.get!(character.id)
      |> Repo.preload([:race, :guild, :home_location])

    assert character.name == "Eirik Ring-Keeper"
    assert character.gender == "male"
    assert character.title == "High King of Frostgard"
    assert character.character_role_id == high_king.id
    assert character.role == "High King"
    assert character.politics == "Crown Moot"
    assert character.description == "Bearer of the Frostmark oath"
    assert character.race.name == "Breton"
    assert character.guild.name == "Crown Moot"
    assert character.home_location.name == "High Hall"
  end

  test "creates character roles from the characters section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=characters")

    open_action(view, "character_role")

    view
    |> form("#character-role-form",
      character_role: %{
        name: "Housecarl",
        description: "Sworn shield of a jarl"
      }
    )
    |> render_submit()

    character_role = Repo.get_by!(CharacterRole, name: "Housecarl")

    open_action(view, "character")

    assert has_element?(view, "#character_character_role_id option[value='#{character_role.id}']")
  end

  test "groups characters without a race by their primary profession", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, character} = Worlds.create_character(world, %{name: "Nameless Wanderer"})
    {:ok, occupation} = Worlds.create_occupation(world, %{name: "Wayfarer"})

    {:ok, _character_occupation} =
      Worlds.create_character_occupation(character, occupation, %{primary: true})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=characters")

    assert has_element?(view, "#character-list summary", "Wayfarer")
    refute has_element?(view, "#character-list summary", "No Race")
    refute has_element?(view, "#character-list summary", "Nameless Wanderer")
  end

  test "groups characters by race and orders characters by role", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, alfar} = Worlds.create_race(world, %{name: "Alfar"})
    {:ok, fjordborn} = Worlds.create_race(world, %{name: "Fjordborn"})
    {:ok, jarl} = Worlds.create_character_role(world, %{name: "Jarl"})
    {:ok, lawspeaker} = Worlds.create_character_role(world, %{name: "Lawspeaker"})

    {:ok, _character} =
      Worlds.create_character(world, %{name: "Zara"}, %{race: fjordborn, character_role: jarl})

    {:ok, _character} =
      Worlds.create_character(world, %{name: "Asta"}, %{race: alfar, character_role: lawspeaker})

    {:ok, _character} =
      Worlds.create_character(world, %{name: "Bryn"}, %{race: alfar, character_role: jarl})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=characters")

    group_labels =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#character-list summary")
      |> Enum.map(&LazyHTML.text/1)

    assert group_labels == ["Alfar2", "Fjordborn1"]

    alfar_names =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#folded-characters-alfar a")
      |> Enum.map(&LazyHTML.text/1)
      |> Enum.map(&String.replace(&1, ~r/\s+/, ""))

    assert alfar_names == ["BrynJarl", "AstaLawspeaker"]
  end

  test "searches characters by name without hiding form options", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, alfar} = Worlds.create_race(world, %{name: "Alfar"})
    {:ok, fjordborn} = Worlds.create_race(world, %{name: "Fjordborn"})

    {:ok, _character} =
      Worlds.create_character(world, %{name: "Asta Ink-Reader"}, %{race: alfar})

    {:ok, _character} =
      Worlds.create_character(world, %{name: "Bryn Road-Warden"}, %{race: fjordborn})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=characters")

    view
    |> form("#dashboard-search-form", search: %{query: "Ink"})
    |> render_change()

    assert has_element?(view, "#character-list", "Asta Ink-Reader")
    assert has_element?(view, "#folded-characters-alfar[open]")
    refute has_element?(view, "#character-list", "Bryn Road-Warden")
    refute has_element?(view, "#folded-characters-fjordborn")
    assert has_element?(view, "#character_race_id option[value='#{alfar.id}']")
  end

  test "creates edits and deletes skills from the skills section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=skills")

    view
    |> form("#skill-form",
      skill: %{
        name: "Rune Craft",
        category: "magic",
        description: "Carving warded symbols into stone"
      }
    )
    |> render_submit()

    skill =
      Skill
      |> Repo.get_by!(name: "Rune Craft")
      |> Repo.preload(skill_tree: [:perks])

    assert has_element?(view, "#skill-list", "Rune Craft")
    assert skill.skill_tree.name == "Rune Craft"

    view
    |> element("a[href='/worlds/#{world.id}/dashboard?section=skills&skill_id=#{skill.id}']")
    |> render_click()

    open_action(view, "skill_level")

    view
    |> form("#skill-level-form",
      skill_level: %{
        name: "Apprentice",
        rank: 1,
        minimum_value: 25,
        description: "Early training"
      }
    )
    |> render_submit()

    skill_level = Repo.get_by!(SkillLevel, name: "Apprentice")

    assert has_element?(view, "#skill-details", "Apprentice")

    open_action(view, "skill_perk")

    view
    |> form("#skill-perk-form",
      skill_perk: %{
        name: "Rune Focus",
        required_level: 25,
        ranks: 1,
        position: 1,
        description: "Improves ward marks"
      }
    )
    |> render_submit()

    skill_perk = Repo.get_by!(SkillTreePerk, name: "Rune Focus")

    assert has_element?(view, "#skill-progression-tabs")
    assert has_element?(view, "#skill-details", "Rune Focus")
    assert has_element?(view, "#skill-perks-tab")

    view
    |> element("button[phx-click='set_skill_detail_tab'][phx-value-tab='levels']")
    |> render_click()

    assert has_element?(view, "#skill-levels-tab")

    view
    |> element("button[phx-click='delete_skill_level'][phx-value-id='#{skill_level.id}']")
    |> render_click()

    refute Repo.get(SkillLevel, skill_level.id)

    view
    |> element("button[phx-click='set_skill_detail_tab'][phx-value-tab='perks']")
    |> render_click()

    view
    |> element("button[phx-click='delete_skill_perk'][phx-value-id='#{skill_perk.id}']")
    |> render_click()

    refute Repo.get(SkillTreePerk, skill_perk.id)

    open_action(view, "skill_edit")

    view
    |> form("#skill-edit-form",
      skill_edit: %{
        name: "Runecraft",
        category: "craft",
        description: "Enchanting runes and ward marks"
      }
    )
    |> render_submit()

    skill = Repo.get!(Skill, skill.id)

    assert skill.name == "Runecraft"
    assert skill.category == "craft"

    view
    |> element("button[phx-click='delete_skill'][phx-value-id='#{skill.id}']")
    |> render_click()

    refute Repo.get(Skill, skill.id)
  end

  test "creates edits and deletes items from the items section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=items")

    assert has_element?(view, "#item_category option[value='weapon']", "Weapons")
    assert has_element?(view, "#item_category option[value='apparel']", "Apparel")
    assert has_element?(view, "#item_category option[value='food']", "Food")
    assert has_element?(view, "#item_category option[value='ingredient']", "Ingredients")

    view
    |> form("#item-form",
      item: %{
        name: "Iron Sword",
        category: "weapon",
        kind: "sword",
        material: "Iron",
        hands: "one-handed",
        damage: 7,
        critical_damage: 3,
        weight: "9.0",
        value: 25,
        source: "Skyrim",
        description: "A basic iron blade"
      }
    )
    |> render_submit()

    item = Repo.get_by!(Item, name: "Iron Sword")

    assert has_element?(view, "#item-list", "Iron Sword")
    assert has_element?(view, "#item-list", "Weapons")
    assert has_element?(view, "#item-details", "Weapons")
    assert has_element?(view, "#folded-items-weapon:not([open])")

    view
    |> element("#folded-items-weapon summary")
    |> render_click()

    assert has_element?(view, "#folded-items-weapon[open]")

    view
    |> element("a[href='/worlds/#{world.id}/dashboard?section=items&item_id=#{item.id}']")
    |> render_click()

    assert_patch(view, ~p"/worlds/#{world}/dashboard?section=items&item_id=#{item.id}")
    assert has_element?(view, "#folded-items-weapon[open]")

    open_action(view, "item_edit")

    view
    |> form("#item-edit-form",
      item_edit: %{
        name: "Tempered Iron Sword",
        category: "weapon",
        kind: "sword",
        material: "Iron",
        hands: "one-handed",
        damage: 8,
        critical_damage: 3,
        weight: "9.0",
        value: 35,
        source: "Skyrim",
        description: "A sharpened iron blade"
      }
    )
    |> render_submit()

    item = Repo.get!(Item, item.id)

    assert item.name == "Tempered Iron Sword"
    assert item.damage == 8

    open_action(view, "item")

    view
    |> form("#item-form",
      item: %{
        name: "Blue Mountain Flower",
        category: "ingredient",
        kind: "alchemy ingredient",
        weight: "0.1",
        value: 2,
        source: "Skyrim",
        description: "An alchemy ingredient"
      }
    )
    |> render_submit()

    ingredient = Repo.get_by!(Item, name: "Blue Mountain Flower")

    assert has_element?(view, "#item-list", "Ingredients")
    assert has_element?(view, "#item-list", "Blue Mountain Flower")

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=items&item_id=#{ingredient.id}")

    open_action(view, "effect")

    view
    |> form("#effect-form",
      effect: %{
        name: "Restore Health",
        category: "Alchemy",
        description: "Restores health."
      }
    )
    |> render_submit()

    effect = Repo.get_by!(Effect, name: "Restore Health")

    open_action(view, "item_effect")

    view
    |> form("#item-effect-form",
      item_effect: %{
        effect_id: effect.id,
        position: 1,
        notes: "First discovered effect"
      }
    )
    |> render_submit()

    item_effect = Repo.get_by!(ItemEffect, item_id: ingredient.id)

    assert has_element?(view, "#item-effects", "Restore Health")
    assert has_element?(view, "#item-effects", "First discovered effect")

    view
    |> element("button[phx-click='delete_item_effect'][phx-value-id='#{item_effect.id}']")
    |> render_click()

    refute Repo.get(ItemEffect, item_effect.id)

    view
    |> element("button[phx-click='delete_item'][phx-value-id='#{item.id}']")
    |> render_click()

    refute Repo.get(Item, item.id)
  end

  test "adds catalog items to a selected character inventory", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, character} = Worlds.create_character(world, %{name: "Aela"})
    {:ok, item} = Worlds.create_item(world, %{name: "Hunting Bow", category: "weapon"})

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=characters&character_id=#{character.id}")

    open_action(view, "inventory_category")

    view
    |> form("#inventory-category-form",
      inventory_category: %{
        name: "Weapons",
        position: 1,
        description: "Equipped and carried weapons"
      }
    )
    |> render_submit()

    category = Repo.get_by!(CharacterInventoryCategory, name: "Weapons")

    assert has_element?(view, "#character-details", "Weapons")

    open_action(view, "inventory_item")

    view
    |> form("#inventory-item-form",
      inventory_item: %{
        item_id: item.id,
        inventory_category_id: category.id,
        name: "",
        quantity: 1,
        equipped: "true",
        notes: "Primary bow"
      }
    )
    |> render_submit()

    inventory_item = Repo.get_by!(CharacterInventoryItem, item_id: item.id)

    assert has_element?(view, "#character-details", "Hunting Bow")
    assert has_element?(view, "#character-details", "equipped")

    view
    |> element("button[phx-click='delete_inventory_item'][phx-value-id='#{inventory_item.id}']")
    |> render_click()

    refute Repo.get(CharacterInventoryItem, inventory_item.id)

    view
    |> element("button[phx-click='delete_inventory_category'][phx-value-id='#{category.id}']")
    |> render_click()

    refute Repo.get(CharacterInventoryCategory, category.id)
  end

  test "creates and deletes bestiary records", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Winterhold"})
    {:ok, cave} = Worlds.create_location_type(world, %{name: "Cave"})
    {:ok, lair} = Worlds.create_location(hold, cave, %{name: "Frozen Lair"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=bestiary")

    open_action(view, "creature_type")

    view
    |> form("#creature-type-form",
      creature_type: %{
        name: "Beast",
        description: "Hostile wilderness creatures"
      }
    )
    |> render_submit()

    creature_type = Repo.get_by!(CreatureType, name: "Beast")

    open_action(view, "creature")

    view
    |> form("#creature-form",
      creature: %{
        creature_type_id: creature_type.id,
        name: "Ice Wraith",
        habitat: "snowfields",
        temperament: "hostile",
        danger_level: "high",
        description: "A dangerous frost spirit"
      }
    )
    |> render_submit()

    creature = Repo.get_by!(Creature, name: "Ice Wraith")

    assert has_element?(view, "#creature-list", "Ice Wraith")

    open_action(view, "creature_edit")

    view
    |> form("#creature-edit-form",
      creature_edit: %{
        creature_type_id: creature_type.id,
        name: "Ice Wraith",
        habitat: "frozen ruins",
        temperament: "hostile",
        danger_level: "severe",
        description: "A severe frost spirit"
      }
    )
    |> render_submit()

    creature = Repo.get!(Creature, creature.id)

    assert creature.habitat == "frozen ruins"
    assert creature.danger_level == "severe"

    open_action(view, "creature_location")

    view
    |> form("#creature-location-form",
      creature_location: %{
        creature_id: creature.id,
        location_id: lair.id,
        presence: "common",
        description: "Hunts around the entrance"
      }
    )
    |> render_submit()

    creature_location = Repo.get_by!(CreatureLocation, creature_id: creature.id)

    assert has_element?(view, "#creature-details", "Frozen Lair")

    view
    |> element(
      "button[phx-click='delete_creature_location'][phx-value-id='#{creature_location.id}']"
    )
    |> render_click()

    refute Repo.get(CreatureLocation, creature_location.id)

    view
    |> element("button[phx-click='delete_creature'][phx-value-id='#{creature.id}']")
    |> render_click()

    refute Repo.get(Creature, creature.id)

    assert {:ok, _creature_type} = Worlds.delete_creature_type(creature_type)
    refute Repo.get(CreatureType, creature_type.id)
  end

  test "creates edits and deletes spells from the spells section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=spells")

    view
    |> form("#spell-form",
      spell: %{
        name: "Frost Ward",
        school: "Restoration",
        level: "Apprentice",
        magicka_cost: 58,
        source: "custom",
        description: "Raises a ward against cold magic"
      }
    )
    |> render_submit()

    spell = Repo.get_by!(Spell, name: "Frost Ward")

    assert has_element?(view, "#spell-list", "Frost Ward")

    view
    |> element("a[href='/worlds/#{world.id}/dashboard?section=spells&spell_id=#{spell.id}']")
    |> render_click()

    open_action(view, "spell_edit")

    view
    |> form("#spell-edit-form",
      spell_edit: %{
        name: "Greater Frost Ward",
        school: "Restoration",
        level: "Adept",
        magicka_cost: 84,
        source: "custom",
        description: "Raises a stronger ward against cold magic"
      }
    )
    |> render_submit()

    spell = Repo.get!(Spell, spell.id)

    assert spell.name == "Greater Frost Ward"
    assert spell.magicka_cost == 84

    view
    |> element("button[phx-click='delete_spell'][phx-value-id='#{spell.id}']")
    |> render_click()

    refute Repo.get(Spell, spell.id)
  end

  test "creates calendars and months from the calendar section", %{conn: conn} do
    {:ok, world} =
      Worlds.create_world_from_template(:blank, %{
        name: "Eldoria",
        primary_star_name: "Solka",
        orbital_period_days: 31,
        axial_tilt_degrees: "23.5"
      })

    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=calendar")

    assert has_element?(view, "#calendar-weekday-fields")
    assert has_element?(view, "#calendar_weekday_names_0:not([placeholder])")
    assert has_element?(view, "#calendar_weekday_names_6")

    view
    |> element("#add-calendar-weekday")
    |> render_click()

    assert has_element?(view, "#calendar_weekday_names_7")

    view
    |> element("#remove-calendar-weekday-7")
    |> render_click()

    refute has_element?(view, "#calendar_weekday_names_7")

    view
    |> form("#calendar-form",
      calendar: %{
        continent_id: continent.id,
        name: "Nordic Reckoning",
        weekday_names: %{
          "0" => "Montak",
          "1" => "Dientak",
          "2" => "Midtak",
          "3" => "Dondertak",
          "4" => "Fretak",
          "5" => "Lortak",
          "6" => "Suntak"
        },
        era: "Fourth Era",
        year_start_angle: "270.0",
        perihelion_day: 12,
        intercalation_interval_years: 4,
        intercalary_days: 1,
        intercalation_rule: "One feast day closes every fourth year.",
        description: "A local calendar"
      }
    )
    |> render_submit()

    calendar = Repo.get_by!(Calendar, name: "Nordic Reckoning")
    assert Decimal.equal?(calendar.year_start_angle, Decimal.new("270.0"))
    assert calendar.perihelion_day == 12
    assert calendar.days_per_week == 7
    assert calendar.intercalation_interval_years == 4
    assert calendar.intercalary_days == 1
    assert calendar.intercalation_rule == "One feast day closes every fourth year."

    assert calendar.weekday_names == [
             "Montak",
             "Dientak",
             "Midtak",
             "Dondertak",
             "Fretak",
             "Lortak",
             "Suntak"
           ]

    open_action(view, "calendar_month")

    view
    |> form("#calendar-month-form",
      calendar_month: %{
        name: "Frostfall",
        days: 31,
        position: 1
      }
    )
    |> render_submit()

    calendar = Worlds.get_calendar!(calendar.id)
    continent = Repo.get!(AncientStones.Worlds.Continent, calendar.continent_id)
    [month] = calendar.months

    assert Enum.any?(calendar.months, &(&1.name == "Frostfall"))
    assert has_element?(view, "#calendar-list", "Nordic Reckoning")
    assert has_element?(view, "#calendar-details", "Solka")
    assert has_element?(view, "#calendar-details", "31 days")
    assert has_element?(view, "#calendar-details", "Aligned")
    assert has_element?(view, "#calendar-details", "270.0 deg")
    assert has_element?(view, "#calendar-continents")
    assert has_element?(view, "#calendar-continent-#{continent.id}", continent.name)
    assert has_element?(view, "#calendar-weekdays", "Montak")
    assert has_element?(view, "#calendar-weekdays", "Midtak")
    assert has_element?(view, "#calendar-weekdays", "Fretak")
    assert has_element?(view, "#calendar-month-grid")
    assert has_element?(view, "#calendar-month-#{month.id}", "Frostfall")
    assert has_element?(view, "#calendar-details", "+1 day every 4 years")
  end

  test "creates and deletes moons from the calendar section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=calendar")

    open_action(view, "moon")

    view
    |> form("#moon-form",
      moon: %{
        name: "Mani",
        orbital_period_days: "26.89",
        semi_major_axis_km: "392000",
        mean_radius_km: "1720",
        mass_lunar: "0.96",
        orbital_eccentricity: "0.045",
        inclination_degrees: "5.2",
        tidal_role: "Sets the principal coastal tide.",
        description: "A pale cratered moon."
      }
    )
    |> render_submit()

    moon = Repo.get_by!(Moon, world_id: world.id, name: "Mani")

    assert has_element?(view, "#moon-#{moon.id}", "Mani")
    assert has_element?(view, "#moon-#{moon.id}", "26.89000 days")

    view
    |> element("button[phx-click='delete_moon'][phx-value-id='#{moon.id}']")
    |> render_click()

    refute Repo.get(Moon, moon.id)
    assert has_element?(view, "#moon-list", "No moons recorded")
  end

  test "selects calendars and months for editing from the calendar section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})

    {:ok, calendar} =
      Worlds.create_calendar(continent, %{
        name: "Nordic Reckoning",
        days_per_week: 3,
        weekday_names: ["Montak", "Midtak", "Fretak"],
        era: "Fourth Era",
        year_start_angle: "270.0",
        perihelion_day: 12,
        description: "A local calendar"
      })

    {:ok, month} =
      Worlds.create_calendar_month(calendar, %{
        name: "Frostfall",
        days: 31,
        position: 1
      })

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=calendar&calendar_id=#{calendar.id}")

    assert has_element?(view, "#calendar-edit-form")
    assert has_element?(view, "#calendar_edit_name[value='Nordic Reckoning']")
    assert has_element?(view, "#calendar_edit_weekday_names_0[value='Montak']")
    assert has_element?(view, "#calendar_edit_weekday_names_2[value='Fretak']")
    refute has_element?(view, "#calendar-form input[name='calendar[name]']")

    view
    |> form("#calendar-edit-form",
      calendar_edit: %{
        name: "Nordic Reckoning",
        weekday_names: %{
          "0" => "Montak Prime",
          "1" => "Midtak Prime",
          "2" => "Fretak Prime"
        },
        era: "Fourth Era",
        year_start_angle: "270.0",
        perihelion_day: 12,
        description: "A local calendar"
      }
    )
    |> render_submit()

    calendar = Worlds.get_calendar!(calendar.id)

    assert calendar.weekday_names == ["Montak Prime", "Midtak Prime", "Fretak Prime"]
    assert has_element?(view, "#calendar-weekdays", "Montak Prime")

    view
    |> element("a[aria-label='Edit Frostfall']")
    |> render_click()

    assert has_element?(view, "#calendar-month-edit-form")
    assert has_element?(view, "#calendar_month_edit_name[value='Frostfall']")

    view
    |> form("#calendar-month-edit-form",
      calendar_month_edit: %{
        name: "Snowmelt",
        days: 30,
        position: 1
      }
    )
    |> render_submit()

    month = Repo.get!(CalendarMonth, month.id)

    assert month.name == "Snowmelt"
    assert month.days == 30
    assert has_element?(view, "#calendar-month-#{month.id}", "Snowmelt")
  end

  test "creates timelines, eras, and events from the timeline section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=timeline")

    view
    |> form("#timeline-form",
      timeline: %{
        name: "Nordic Reckoning",
        description: "Local historical eras"
      }
    )
    |> render_submit()

    timeline = Repo.get_by!(Timeline, name: "Nordic Reckoning")

    open_action(view, "timeline_era")

    view
    |> form("#timeline-era-form",
      timeline_era: %{
        timeline_id: timeline.id,
        name: "First Era",
        abbreviation: "1E",
        position: 1,
        starts_at_year: 1,
        ends_at_year: 2920,
        description: "Recorded history begins"
      }
    )
    |> render_submit()

    timeline = Worlds.get_timeline!(timeline.id)
    [era] = timeline.eras

    assert Enum.any?(timeline.eras, &(&1.name == "First Era"))
    assert has_element?(view, "#timeline-list", "Nordic Reckoning")

    open_action(view, "timeline_event")

    view
    |> form("#timeline-event-form",
      timeline_event: %{
        timeline_id: timeline.id,
        timeline_era_id: era.id,
        name: "Battle of Snow-Throat",
        year: 120,
        position: 1,
        description: "A decisive mountain campaign"
      }
    )
    |> render_submit()

    timeline_event = Repo.get_by!(TimelineEvent, name: "Battle of Snow-Throat")

    assert timeline_event.timeline_id == timeline.id
    assert timeline_event.timeline_era_id == era.id
    assert has_element?(view, "#timeline-details", "Battle of Snow-Throat")

    view
    |> element("button[phx-click='delete_timeline_event'][phx-value-id='#{timeline_event.id}']")
    |> render_click()

    refute Repo.get(TimelineEvent, timeline_event.id)
  end

  test "selects a hold and location from the dashboard columns", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    tamriel = Enum.find(dashboard.continents, &(&1.name == "Tamriel"))
    province = skyrim_province(dashboard)
    whiterun = Enum.find(province.holds, &(&1.name == "Whiterun"))
    riverwood = Enum.find(whiterun.locations, &(&1.name == "Riverwood"))
    character = hd(dashboard.characters)

    continent_office =
      Repo.insert!(%AncientStones.Worlds.PoliticalOffice{
        world_id: world.id,
        continent_id: tamriel.id,
        character_id: character.id,
        office: "High King",
        scope: "continent"
      })

    Repo.insert!(%AncientStones.Worlds.CharacterLocation{
      character_id: character.id,
      location_id: riverwood.id,
      relationship: "resident"
    })

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    assert has_element?(view, "#location-list")

    view
    |> element("a[href='/worlds/#{world.id}/dashboard?continent_id=#{tamriel.id}']")
    |> render_click()

    assert_patch(view, ~p"/worlds/#{world}/dashboard?continent_id=#{tamriel.id}")
    assert has_element?(view, "#continent-details")
    assert has_element?(view, "#continent-details", "Provinces")
    assert has_element?(view, "#continent-leadership")
    assert has_element?(view, "#continent-office-#{continent_office.id}", character.name)
    refute has_element?(view, "#province-details")
    refute has_element?(view, "#hold-details")
    refute has_element?(view, "#location-details")

    view
    |> element("a[href='/worlds/#{world.id}/dashboard?province_id=#{province.id}']")
    |> render_click()

    assert_patch(view, ~p"/worlds/#{world}/dashboard?province_id=#{province.id}")
    assert has_element?(view, "#province-details")
    assert has_element?(view, "#province-details", "Terrain")
    refute has_element?(view, "#continent-details")
    refute has_element?(view, "#hold-details")
    refute has_element?(view, "#location-details")

    view
    |> element("a[href='/worlds/#{world.id}/dashboard?hold_id=#{whiterun.id}']")
    |> render_click()

    assert_patch(view, ~p"/worlds/#{world}/dashboard?hold_id=#{whiterun.id}")
    assert has_element?(view, "#location-list a", "Riverwood")
    assert has_element?(view, "#hold-details")
    assert has_element?(view, "#hold-details", "Terrain")
    assert has_element?(view, "#political-office-details")
    assert has_element?(view, "#hold-commerce-details")
    refute has_element?(view, "#location-details")

    view
    |> element(
      "a[href='/worlds/#{world.id}/dashboard?hold_id=#{whiterun.id}&location_id=#{riverwood.id}']"
    )
    |> render_click()

    assert_patch(
      view,
      ~p"/worlds/#{world}/dashboard?hold_id=#{whiterun.id}&location_id=#{riverwood.id}"
    )

    assert has_element?(view, "#location-details")
    assert has_element?(view, "#location-details", "Region")
    assert has_element?(view, "#location-characters")

    assert has_element?(
             view,
             "#location-character-#{character.id}",
             character.name
           )

    assert has_element?(view, "#location-character-#{character.id}", "Resident")
    refute has_element?(view, "#hold-details")
    refute has_element?(view, "#political-office-details")
    refute has_element?(view, "#hold-commerce-details")
  end

  test "deletes a hold from the geography tree", %{conn: conn} do
    %{world: world, hold: whiterun} = geography_ui_fixture()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    view
    |> element("button[phx-click='delete_hold'][phx-value-id='#{whiterun.id}']")
    |> render_click()

    refute Repo.get(Hold, whiterun.id)
  end

  test "creates and searches households in the Society dashboard", %{conn: conn} do
    %{world: world, location: location, first_character: head} = society_ui_fixture()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=society")

    assert has_element?(view, "#society-dashboard")
    assert has_element?(view, "#society-households[phx-update='stream']")
    assert has_element?(view, "#society-household-form")

    view
    |> form("#society-household-form",
      household: %{
        name: "Ragna's household",
        household_type: "farmstead",
        status: "active",
        home_location_id: location.id,
        head_character_id: head.id,
        description: "A farm household of kin, dependents, and seasonal laborers."
      }
    )
    |> render_submit()

    [household] = Worlds.list_households(world)
    assert has_element?(view, "#society_households-#{household.id}", household.name)

    view
    |> form("#dashboard-search-form", search: %{query: "Ragna"})
    |> render_change()

    assert has_element?(view, "#society_households-#{household.id}")

    view
    |> element("#society_households-#{household.id}")
    |> render_click()

    assert_patch(
      view,
      ~p"/worlds/#{world}/dashboard?section=society&mode=household&household_id=#{household.id}"
    )

    view
    |> form("#society-household-form",
      household: %{
        name: "Ragna's riverside household",
        household_type: "farmstead",
        status: "active",
        home_location_id: location.id,
        description: "A working farm household near the river crossing."
      }
    )
    |> render_submit()

    assert Worlds.get_household!(world, household.id).name == "Ragna's riverside household"

    view
    |> element("#delete-society-household-#{household.id}")
    |> render_click()

    assert Worlds.list_households(world) == []
  end

  test "adds, edits, and removes household members", %{conn: conn} do
    %{
      world: world,
      first_character: head,
      second_character: household_member
    } = society_ui_fixture()

    {:ok, household} =
      Worlds.create_household(world, %{name: "Ragna's household"}, head_character: head)

    {:ok, view, _html} =
      live(
        conn,
        ~p"/worlds/#{world}/dashboard?section=society&mode=household&household_id=#{household.id}"
      )

    assert has_element?(view, "#household-membership-form")

    view
    |> form("#household-membership-form",
      household_membership: %{
        character_id: household_member.id,
        role: "child",
        status: "active",
        is_primary: "false",
        description: "Keeps a sleeping place in the hall."
      }
    )
    |> render_submit()

    membership =
      household
      |> Worlds.list_household_memberships()
      |> Enum.find(&(&1.character_id == household_member.id))

    assert has_element?(view, "#household-membership-#{membership.id}", household_member.name)

    view
    |> element("#edit-household-membership-#{membership.id}")
    |> render_click()

    assert_patch(
      view,
      ~p"/worlds/#{world}/dashboard?section=society&mode=household&household_id=#{household.id}&membership_id=#{membership.id}"
    )

    view
    |> form("#household-membership-form",
      household_membership: %{
        role: "other_kin",
        status: "active",
        is_primary: "false",
        description: "A younger kinsman who works the household fields."
      }
    )
    |> render_submit()

    assert Worlds.get_household_membership!(world, membership.id).role == :other_kin

    view
    |> element("#delete-household-membership-#{membership.id}")
    |> render_click()

    refute Repo.get(AncientStones.Worlds.HouseholdMembership, membership.id)
    refute has_element?(view, "#household-membership-#{membership.id}")
  end

  test "rejects forged Society references from another world", %{conn: conn} do
    %{world: world, first_character: local_character} = society_ui_fixture()

    %{
      hold: foreign_hold,
      location: foreign_location,
      first_character: foreign_character
    } = society_ui_fixture("Tyrven")

    {:ok, household} = Worlds.create_household(world, %{name: "Local household"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=society")

    render_submit(view, "save_household", %{
      "household" => %{
        "name" => "Foreign household",
        "household_type" => "farmstead",
        "status" => "active",
        "home_location_id" => foreign_location.id
      }
    })

    refute Enum.any?(Worlds.list_households(world), &(&1.name == "Foreign household"))

    render_submit(view, "save_character_relationship", %{
      "character_relationship" => %{
        "character_a_id" => local_character.id,
        "character_b_id" => foreign_character.id,
        "relationship_type" => "siblings",
        "status" => "active"
      }
    })

    assert Worlds.list_character_relationships(world) == []

    render_submit(view, "save_landholding", %{
      "landholding" => %{
        "household_id" => household.id,
        "name" => "Foreign meadow",
        "geographic_scope" => "hold:#{foreign_hold.id}",
        "tenure_type" => "customary",
        "primary_use" => "pasture",
        "status" => "active"
      }
    })

    assert Worlds.list_landholdings(world) == []
  end

  test "creates personal ties and tenure records in Society", %{conn: conn} do
    %{
      world: world,
      hold: hold,
      first_character: parent,
      second_character: child
    } = society_ui_fixture()

    {:ok, household} = Worlds.create_household(world, %{name: "Ketil's farm"})

    {:ok, relationship_view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=society&mode=relationship")

    relationship_view
    |> form("#society-relationship-form",
      character_relationship: %{
        character_a_id: parent.id,
        character_b_id: child.id,
        relationship_type: "parent_child",
        character_a_role: "father",
        character_b_role: "daughter",
        status: "active"
      }
    )
    |> render_submit()

    [relationship] = Worlds.list_character_relationships(world)

    assert has_element?(
             relationship_view,
             "#society_relationships-#{relationship.id}",
             parent.name
           )

    relationship_view
    |> element("#society_relationships-#{relationship.id}")
    |> render_click()

    relationship_view
    |> form("#society-relationship-form",
      character_relationship: %{
        status: "historical",
        description: "The tie was recognized before the spring assembly."
      }
    )
    |> render_submit()

    relationship = Worlds.get_character_relationship!(world, relationship.id)
    assert relationship.status == :historical

    relationship_view
    |> form("#dashboard-search-form", search: %{query: "spring assembly"})
    |> render_change()

    assert has_element?(relationship_view, "#society_relationships-#{relationship.id}")

    relationship_view
    |> element("#delete-society-relationship-#{relationship.id}")
    |> render_click()

    assert Worlds.list_character_relationships(world) == []

    {:ok, holding_view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=society&mode=holding")

    holding_view
    |> form("#society-landholding-form",
      landholding: %{
        household_id: household.id,
        name: "Common meadow share",
        geographic_scope: "hold:#{hold.id}",
        tenure_type: "communal_right",
        primary_use: "pasture",
        status: "active"
      }
    )
    |> render_submit()

    [holding] = Worlds.list_landholdings(world)
    assert has_element?(holding_view, "#society_landholdings-#{holding.id}", holding.name)

    holding_view
    |> element("#society_landholdings-#{holding.id}")
    |> render_click()

    holding_view
    |> form("#society-landholding-form",
      landholding: %{
        name: "Upper common meadow share",
        description: "Grazing opens after the hay fields are cleared."
      }
    )
    |> render_submit()

    holding = Worlds.get_landholding!(world, holding.id)
    assert holding.name == "Upper common meadow share"

    holding_view
    |> form("#dashboard-search-form", search: %{query: "hay fields"})
    |> render_change()

    assert has_element?(holding_view, "#society_landholdings-#{holding.id}")

    holding_view
    |> element("#delete-society-landholding-#{holding.id}")
    |> render_click()

    assert Worlds.list_landholdings(world) == []
  end

  test "shows social standing, households, ties, and tenure on character details", %{conn: conn} do
    %{
      world: world,
      hold: hold,
      first_character: character,
      second_character: sibling
    } = society_ui_fixture()

    {:ok, household} =
      Worlds.create_household(world, %{name: "Ragna's household"}, head_character: character)

    {:ok, _relationship} =
      Worlds.create_character_relationship(world, character, sibling, %{
        relationship_type: :siblings
      })

    {:ok, _holding} =
      Worlds.create_landholding(
        household,
        %{name: "East field", tenure_type: :allodial, primary_use: :farming},
        hold: hold
      )

    {:ok, view, _html} =
      live(
        conn,
        ~p"/worlds/#{world}/dashboard?section=characters&character_id=#{character.id}"
      )

    view
    |> form("#character-form",
      character: %{
        social_status: "freeholder",
        life_stage: "adult",
        wealth_band: "comfortable"
      }
    )
    |> render_submit()

    character = Worlds.get_character!(character.id)
    assert character.social_status == :freeholder
    assert character.life_stage == :adult
    assert character.wealth_band == :comfortable

    assert has_element?(view, "#character-details", "Freeholder")
    assert has_element?(view, "#character-households", household.name)
    assert has_element?(view, "#character-relationships", sibling.name)
    assert has_element?(view, "#character-landholdings", "East field")
  end

  test "deletes a selected location from the locations column", %{conn: conn} do
    %{world: world, hold: whiterun, location: riverwood} = geography_ui_fixture()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?hold_id=#{whiterun.id}")

    view
    |> element("button[phx-click='delete_location'][phx-value-id='#{riverwood.id}']")
    |> render_click()

    refute Repo.get(Location, riverwood.id)
  end

  test "deletes a location type from the actions column", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    location_type = world |> Worlds.list_location_types() |> Enum.find(&(&1.name == "Clearing"))

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    open_action(view, "delete_location_type")

    view
    |> form("#delete-location-type-form", location_type_delete: %{id: location_type.id})
    |> render_submit()

    refute Repo.get(LocationType, location_type.id)
  end

  test "deletes a continent and nested geography from the tree", %{conn: conn} do
    %{world: world, continent: continent} = geography_ui_fixture()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    view
    |> element("button[phx-click='delete_continent'][phx-value-id='#{continent.id}']")
    |> render_click()

    refute Repo.get(Continent, continent.id)
    assert Worlds.get_world!(world.id)
  end

  defp create_world! do
    {:ok, world} = Worlds.create_world(%{name: "Eldoria"})
    world
  end

  defp geography_ui_fixture do
    {:ok, world} = Worlds.create_world(%{name: "Northern Realm"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, location_type} = Worlds.create_location_type(world, %{name: "Town"})
    {:ok, location} = Worlds.create_location(hold, location_type, %{name: "Riverwood"})

    %{
      world: world,
      continent: continent,
      province: province,
      hold: hold,
      location: location,
      location_type: location_type
    }
  end

  defp society_ui_fixture(world_name \\ "Audrun") do
    {:ok, world} = Worlds.create_world(%{name: world_name})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Ancient Lands"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Frostgard"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Gronvale"})
    {:ok, location_type} = Worlds.create_location_type(world, %{name: "Farmstead"})
    {:ok, location} = Worlds.create_location(hold, location_type, %{name: "River Farm"})
    {:ok, first_character} = Worlds.create_character(world, %{name: "Ragna Torvaldsdottir"})
    {:ok, second_character} = Worlds.create_character(world, %{name: "Ingrid Torvaldsdottir"})

    %{
      world: world,
      hold: hold,
      location: location,
      first_character: first_character,
      second_character: second_character
    }
  end

  defp skyrim_province(world) do
    world.continents
    |> Enum.find(&(&1.name == "Tamriel"))
    |> Map.fetch!(:provinces)
    |> Enum.find(&(&1.name == "Skyrim"))
  end

  defp open_action(view, action) do
    view
    |> element("button[phx-click='show_action'][phx-value-action='#{action}']")
    |> render_click()
  end
end
