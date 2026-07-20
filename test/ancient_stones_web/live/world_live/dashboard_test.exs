defmodule AncientStonesWeb.WorldLive.DashboardTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.Calendar
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
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.HoldCommerceEntry
  alias AncientStones.Worlds.Item
  alias AncientStones.Worlds.ItemEffect
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.Occupation
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
    assert has_element?(view, "#action-list")
    assert has_element?(view, "#continent-form")
    refute has_element?(view, "#province-form")
    refute has_element?(view, "button[phx-value-action='province']")
    refute has_element?(view, "button[phx-value-action='hold']")
    refute has_element?(view, "button[phx-value-action='location']")

    open_action(view, "continent")

    refute has_element?(view, "#continent-form")
  end

  test "creates geography records from dashboard forms", %{conn: conn} do
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

    world = Worlds.get_world_dashboard!(world.id)
    [continent] = world.continents

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

    world = Worlds.get_world_dashboard!(world.id)
    [continent] = world.continents
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

    dashboard = Worlds.get_world_dashboard!(world.id)
    [continent] = dashboard.continents
    [province] = continent.provinces
    [hold] = province.holds

    assert hold.name == "Whiterun"
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
        capital: "true"
      }
    )
    |> render_submit()

    dashboard = Worlds.get_world_dashboard!(world.id)
    [continent] = dashboard.continents
    [province] = continent.provinces
    [hold] = province.holds

    assert hold.capital_location.name == "Whiterun"
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

    open_action(view, "location_edit")

    view
    |> form("#location-edit-form",
      location_edit: %{
        location_type_id: capital.location_type_id,
        name: "Whiterun",
        description: "Major trade city",
        capital: "false"
      }
    )
    |> render_submit()

    hold = Repo.get!(Hold, whiterun.id)
    location = Repo.get!(Location, capital.id)

    refute hold.capital_location_id
    assert location.description == "Major trade city"
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

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=races")

    assert has_element?(view, "#race-form")

    view
    |> form("#race-form",
      race: %{
        name: "Snowborn",
        description: "People adapted to high mountain winters"
      }
    )
    |> render_submit()

    race = Repo.get_by!(Race, name: "Snowborn")

    assert has_element?(view, "#race-list", "Snowborn")

    view
    |> element("button[phx-click='delete_race'][phx-value-id='#{race.id}']")
    |> render_click()

    refute Repo.get(Race, race.id)
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
    assert has_element?(view, "#folded-documents-note:not([open])")

    view
    |> element("#folded-documents-note summary")
    |> render_click()

    assert has_element?(view, "#folded-documents-note[open]")
    assert has_element?(view, "#document-list", "Black-Briar Correspondence")

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
    assert has_element?(view, "#folded-connections-character-maven-black-briar:not([open])")

    view
    |> element("#folded-connections-character-maven-black-briar summary")
    |> render_click()

    assert has_element?(view, "#folded-connections-character-maven-black-briar[open]")
    assert has_element?(view, "#connection-list", "Black-Briar Patronage")
  end

  test "creates characters from the characters section", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, race} = Worlds.create_race(world, %{name: "Nord"})
    {:ok, guild} = Worlds.create_guild(world, %{name: "Stormcloaks"})
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

    view
    |> form("#character-form",
      character: %{
        name: "Ulfric Stormcloak",
        title: "Jarl of Windhelm",
        role: "Jarl",
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
    assert Enum.any?(character.character_occupations, &(&1.occupation.name == "Jarl"))
    assert Enum.any?(character.character_skills, &(&1.skill.name == "Speech"))
    assert has_element?(view, "#character-list", "Ulfric Stormcloak")
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
    {:ok, world} = Worlds.create_world_from_template(:blank, %{name: "Eldoria"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=calendar")

    view
    |> form("#calendar-form",
      calendar: %{
        continent_id: continent.id,
        name: "Nordic Reckoning",
        days_per_week: 7,
        era: "Fourth Era",
        description: "A local calendar"
      }
    )
    |> render_submit()

    calendar = Repo.get_by!(Calendar, name: "Nordic Reckoning")

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
    [month] = calendar.months

    assert Enum.any?(calendar.months, &(&1.name == "Frostfall"))
    assert has_element?(view, "#calendar-list", "Nordic Reckoning")
    assert has_element?(view, "#calendar-month-grid")
    assert has_element?(view, "#calendar-month-#{month.id}", "Frostfall")
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

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    assert has_element?(view, "#location-list")

    view
    |> element("a[href='/worlds/#{world.id}/dashboard?continent_id=#{tamriel.id}']")
    |> render_click()

    assert_patch(view, ~p"/worlds/#{world}/dashboard?continent_id=#{tamriel.id}")
    assert has_element?(view, "#continent-details")
    assert has_element?(view, "#continent-details", "Provinces")
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
    refute has_element?(view, "#hold-details")
    refute has_element?(view, "#political-office-details")
    refute has_element?(view, "#hold-commerce-details")
  end

  test "deletes a hold from the geography tree", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    province = skyrim_province(dashboard)
    whiterun = Enum.find(province.holds, &(&1.name == "Whiterun"))

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard")

    view
    |> element("button[phx-click='delete_hold'][phx-value-id='#{whiterun.id}']")
    |> render_click()

    refute Repo.get(Hold, whiterun.id)
  end

  test "deletes a selected location from the locations column", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    province = skyrim_province(dashboard)
    whiterun = Enum.find(province.holds, &(&1.name == "Whiterun"))
    riverwood = Enum.find(whiterun.locations, &(&1.name == "Riverwood"))

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
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    continent = Enum.find(dashboard.continents, &(&1.name == "Tamriel"))

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
