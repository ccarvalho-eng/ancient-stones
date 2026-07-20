defmodule AncientStones.WorldsTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.Worlds
  alias AncientStones.Repo
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.Effect
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.ItemEffect
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.World

  test "creates a world map hierarchy" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    assert {:ok, %Continent{} = continent} =
             Worlds.create_continent(world, %{
               name: "Tamriel",
               world_id: Ecto.UUID.generate()
             })

    assert continent.world_id == world.id

    assert {:ok, %Province{} = province} =
             Worlds.create_province(continent, %{
               name: "Skyrim",
               continent_id: Ecto.UUID.generate()
             })

    assert province.continent_id == continent.id

    assert {:ok, %Hold{} = hold} =
             Worlds.create_hold(province, %{
               name: "Whiterun Hold",
               province_id: Ecto.UUID.generate()
             })

    assert hold.province_id == province.id
  end

  test "lists map regions in name order" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})

    {:ok, _rift} = Worlds.create_hold(province, %{name: "The Rift"})
    {:ok, _whiterun} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, _eastmarch} = Worlds.create_hold(province, %{name: "Eastmarch"})

    assert Enum.map(Worlds.list_continents(world), & &1.name) == ["Tamriel"]
    assert Enum.map(Worlds.list_provinces(continent), & &1.name) == ["Skyrim"]

    assert Enum.map(Worlds.list_holds(province), & &1.name) == [
             "Eastmarch",
             "The Rift",
             "Whiterun"
           ]
  end

  test "requires region names to be unique within their parent" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})

    assert {:error, continent_changeset} = Worlds.create_continent(world, %{name: "Tamriel"})
    assert %{name: [_]} = errors_on(continent_changeset)

    assert {:error, province_changeset} = Worlds.create_province(continent, %{name: "Skyrim"})
    assert %{name: [_]} = errors_on(province_changeset)

    assert {:ok, _hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    assert {:error, hold_changeset} = Worlds.create_hold(province, %{name: "Whiterun"})
    assert %{name: [_]} = errors_on(hold_changeset)
  end

  test "creates a Skyrim-style world from a template" do
    assert {:ok, %World{} = world} =
             Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})

    dashboard = Worlds.get_world_dashboard!(world.id)

    assert dashboard.name == "Northern Realm"

    assert dashboard.continents |> Enum.map(& &1.name) |> Enum.sort() == [
             "Akavir",
             "Aldmeris",
             "Atmora",
             "Pyandonea",
             "Tamriel",
             "Thras",
             "Yokuda"
           ]

    continent = continent_named(dashboard, "Tamriel")
    province = province_named(continent, "Skyrim")
    akavir = continent_named(dashboard, "Akavir")
    yokuda = continent_named(dashboard, "Yokuda")

    assert province.name == "Skyrim"
    assert province.terrain == :mountain
    assert province.climate == :cold

    assert continent.provinces |> Enum.map(& &1.name) |> Enum.sort() == [
             "Black Marsh",
             "Cyrodiil",
             "Elsweyr",
             "Hammerfell",
             "High Rock",
             "Morrowind",
             "Skyrim",
             "Summerset Isles",
             "Valenwood"
           ]

    assert akavir.provinces |> Enum.map(& &1.name) |> Enum.sort() == [
             "Ka Po' Tun",
             "Kamal",
             "Tang Mo",
             "Tsaesci"
           ]

    assert province_named(akavir, "Tsaesci").description =~ "largest known kingdom"

    assert yokuda.provinces |> Enum.map(& &1.name) |> Enum.sort() == [
             "Akos Kasaz",
             "Kanesh",
             "Samara",
             "Yath"
           ]

    hold_names =
      province.holds
      |> Enum.map(& &1.name)
      |> Enum.sort()

    assert hold_names == [
             "Eastmarch",
             "Falkreath",
             "Haafingar",
             "Hjaalmarch",
             "The Pale",
             "The Reach",
             "The Rift",
             "Whiterun",
             "Winterhold"
           ]

    assert location_count(province) == 121

    eastmarch = hold_named(province, "Eastmarch")
    falkreath = hold_named(province, "Falkreath")
    pale = hold_named(province, "The Pale")
    reach = hold_named(province, "The Reach")
    rift = hold_named(province, "The Rift")
    whiterun = hold_named(province, "Whiterun")

    assert whiterun.terrain == :plains
    assert whiterun.climate == :temperate
    assert whiterun.capital_location.name == "Whiterun"
    assert Enum.any?(whiterun.locations, &(&1.name == "Riverwood"))
    assert Enum.any?(whiterun.locations, &(&1.name == "Bleak Falls Barrow"))
    assert cave_location?(eastmarch, "Lost Knife Hideout")
    assert cave_location?(falkreath, "Haemar's Shame")
    assert cave_location?(pale, "Forsaken Cave")
    assert cave_location?(reach, "Liar's Retreat")
    assert cave_location?(rift, "Redwater Den")
    assert cave_location?(whiterun, "Graywinter Watch")
    assert Enum.any?(whiterun.commerce_entries, &(&1.name == "Plains farm tithe"))
    assert Enum.any?(whiterun.commerce_entries, &(&1.kind == "expense"))

    assert Enum.any?(dashboard.guilds, &(&1.name == "Companions"))
    assert Enum.any?(dashboard.guilds, &(&1.name == "Thieves Guild"))
    assert Enum.any?(dashboard.gods, &(&1.name == "Sithis"))
    assert Enum.any?(dashboard.characters, &(&1.name == "Ulfric Stormcloak"))
    assert Enum.any?(dashboard.characters, &(&1.name == "Torygg" && &1.status == "dead"))
    assert Enum.any?(dashboard.occupations, &(&1.name == "Jarl"))
    assert Enum.any?(dashboard.creature_types, &(&1.name == "Dragon"))
    assert Enum.any?(dashboard.creatures, &(&1.name == "Frost Troll"))
    assert dashboard.galaxy.name == "Mundus"
    assert Enum.any?(dashboard.civilizations, &(&1.name == "Dwemer"))
    assert Enum.any?(dashboard.documents, &(&1.title == "The Book of the Dragonborn"))
    assert Enum.any?(dashboard.political_offices, &(&1.office == "High King"))
    assert Enum.any?(dashboard.lore_connections, &(&1.name == "Black-Briar Patronage"))
    assert Enum.any?(dashboard.timelines, &(&1.name == "Tamrielic Timeline"))
    assert Enum.map(dashboard.skills, & &1.name) |> Enum.sort() == skyrim_skill_names()
    assert Enum.any?(dashboard.skill_trees, &(&1.name == "Smithing"))
    assert Enum.all?(dashboard.skill_trees, &(&1.perks != []))
    assert dashboard.skill_trees |> Enum.flat_map(& &1.perks) |> length() == 180

    assert dashboard.skill_trees
           |> Enum.flat_map(& &1.perks)
           |> Enum.map(&(&1.ranks || 1))
           |> Enum.sum() == 251

    assert Enum.any?(dashboard.items, &(&1.name == "Iron Sword" && &1.category == "weapon"))
    assert Enum.any?(dashboard.items, &(&1.name == "Daedric Armor" && &1.category == "apparel"))
    assert Enum.any?(dashboard.items, &(&1.name == "Sweet Roll" && &1.category == "food"))
    assert Enum.any?(dashboard.effects, &(&1.name == "Restore Health"))
    assert dashboard.items |> Enum.filter(&(&1.category == "ingredient")) |> length() == 91

    blue_mountain_flower = Enum.find(dashboard.items, &(&1.name == "Blue Mountain Flower"))

    assert blue_mountain_flower.category == "ingredient"

    assert blue_mountain_flower.item_effects
           |> Enum.sort_by(& &1.position)
           |> Enum.map(& &1.effect.name) == [
             "Restore Health",
             "Fortify Conjuration",
             "Fortify Health",
             "Damage Magicka Regen"
           ]

    ulfric = Enum.find(dashboard.characters, &(&1.name == "Ulfric Stormcloak"))

    assert Enum.any?(ulfric.inventory_categories, &(&1.name == "Weapons"))

    assert Enum.any?(ulfric.inventory_items, fn inventory_item ->
             inventory_item.item.name == "Steel Sword" && inventory_item.equipped
           end)

    patronage = Enum.find(dashboard.lore_connections, &(&1.name == "Black-Briar Patronage"))

    assert patronage.source_character.name == "Maven Black-Briar"
    assert patronage.target_guild.name == "Thieves Guild"
    assert patronage.connection_type == "patron"

    document = Enum.find(dashboard.documents, &(&1.title == "Black-Briar Correspondence"))

    assert document.author_character.name == "Maven Black-Briar"
    assert document.guild.name == "Thieves Guild"

    timeline = Enum.find(dashboard.timelines, &(&1.name == "Tamrielic Timeline"))

    era_names =
      timeline.eras
      |> Enum.sort_by(& &1.position)
      |> Enum.map(& &1.name)

    assert era_names == [
             "Dawn Era",
             "Merethic Era",
             "First Era",
             "Second Era",
             "Third Era",
             "Fourth Era"
           ]

    event_names =
      timeline.events
      |> Enum.sort_by(& &1.position)
      |> Enum.map(& &1.name)

    assert "Dragon War" in event_names
    assert "Alduin Returns" in event_names

    fourth_era = Enum.find(timeline.eras, &(&1.name == "Fourth Era"))

    assert Enum.any?(
             fourth_era.events,
             &(&1.name == "Alduin Returns" && &1.year == 201)
           )

    ulfric = Enum.find(dashboard.characters, &(&1.name == "Ulfric Stormcloak"))

    assert Enum.any?(
             ulfric.character_occupations,
             &(&1.primary && &1.occupation.name == "Jarl")
           )

    dark_brotherhood = Enum.find(dashboard.guilds, &(&1.name == "Dark Brotherhood"))

    assert Enum.any?(
             dark_brotherhood.guild_influences,
             &(&1.relationship == "serves" && &1.god.name == "Sithis")
           )

    calendar =
      dashboard.continents
      |> continent_named("Tamriel")
      |> Map.fetch!(:calendars)
      |> Enum.find(&(&1.name == "Tamrielic Calendar"))

    assert calendar.days_per_week == 7
    assert Enum.any?(calendar.months, &(&1.name == "Frostfall" && &1.position == 10))

    smithing = Enum.find(dashboard.skills, &(&1.name == "Smithing"))

    assert smithing.skill_tree.name == "Smithing"
    assert Enum.any?(smithing.skill_tree.perks, &(&1.name == "Dragon Armor"))

    nord = Enum.find(dashboard.races, &(&1.name == "Nord"))
    altmer = Enum.find(dashboard.races, &(&1.name == "Altmer"))

    assert nord.description =~ "Northern humans"
    assert Enum.any?(nord.traits, &(&1.name == "Battle Cry" && &1.category == "power"))
    assert Enum.any?(nord.traits, &(&1.name == "Resist Frost" && &1.category == "perk"))
    assert Enum.any?(altmer.traits, &(&1.name == "Highborn" && &1.category == "power"))
  end

  test "creates reusable effects and attaches them to items" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    {:ok, item} =
      Worlds.create_item(world, %{name: "Blue Mountain Flower", category: "ingredient"})

    assert {:ok, %Effect{} = effect} =
             Worlds.create_effect(world, %{name: "Restore Health", category: "Alchemy"})

    assert {:ok, %ItemEffect{} = item_effect} =
             Worlds.create_item_effect(item, effect, %{position: 1})

    item = Worlds.get_item!(item.id)

    assert [%{effect: %{name: "Restore Health"}, position: 1}] = item.item_effects

    assert {:ok, _item_effect} = Worlds.delete_item_effect(item_effect)
  end

  test "creates location type hierarchies and locations" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})

    assert {:ok, %LocationType{} = ruin} =
             Worlds.create_location_type(world, %{name: "Ruin"})

    assert {:ok, %LocationType{} = nordic_ruin} =
             Worlds.create_location_type(ruin, %{name: "Nordic Ruin"})

    assert {:ok, %Location{} = barrow} =
             Worlds.create_location(hold, nordic_ruin, %{name: "Bleak Falls Barrow"})

    assert {:ok, %Location{} = chamber} =
             Worlds.create_child_location(barrow, nordic_ruin, %{name: "Sanctum"})

    assert barrow.hold_id == hold.id
    assert chamber.parent_location_id == barrow.id
  end

  test "creates characters with selected occupation and skill relationships" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, occupation} = Worlds.create_occupation(world, %{name: "Blacksmith"})
    {:ok, skill} = Worlds.create_skill(world, %{name: "Smithing"})

    assert {:ok, character} =
             Worlds.create_character(world, %{name: "Eorlund Gray-Mane"},
               occupation: occupation,
               skill: skill
             )

    character = Repo.get!(Character, character.id)

    character =
      Repo.preload(character,
        character_occupations: [:occupation],
        character_skills: [:skill]
      )

    assert Enum.any?(character.character_occupations, &(&1.occupation.name == "Blacksmith"))
    assert Enum.any?(character.character_skills, &(&1.skill.name == "Smithing"))
  end

  test "rejects locations using types from another world" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, local_type} = Worlds.create_location_type(world, %{name: "City"})
    {:ok, barrow} = Worlds.create_location(hold, local_type, %{name: "Bleak Falls Barrow"})

    {:ok, other_world} = Worlds.create_world(%{name: "Aldmeris"})
    {:ok, foreign_type} = Worlds.create_location_type(other_world, %{name: "Sanctuary"})

    assert Worlds.create_location(hold, foreign_type, %{name: "Foreign Shrine"}) ==
             {:error, :location_type_outside_world}

    assert Worlds.create_child_location(barrow, foreign_type, %{name: "Foreign Sanctum"}) ==
             {:error, :location_type_outside_world}

    refute Repo.get_by(Location, name: "Foreign Shrine")
    refute Repo.get_by(Location, name: "Foreign Sanctum")
  end

  test "creates capital locations atomically" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})

    {:ok, _capital} =
      Worlds.create_location_in_hold(hold, city, %{name: "Whiterun"}, capital: true)

    assert Worlds.create_location_in_hold(hold, city, %{name: "Riverwood"}, capital: true) ==
             {:error, :capital_already_set}

    refute Repo.get_by(Location, name: "Riverwood")
  end

  test "updates a location and clears it as capital" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})

    {:ok, location} =
      Worlds.create_location_in_hold(hold, city, %{name: "Whiterun"}, capital: true)

    assert {:ok, updated_location} =
             Worlds.update_location_in_hold(
               location,
               city,
               %{name: "Whiterun", description: "A former capital marker"},
               capital: false
             )

    hold = Repo.get!(Hold, hold.id)

    refute hold.capital_location_id
    assert updated_location.description == "A former capital marker"
    assert Repo.get(Location, location.id)
  end

  test "rejects nested locations outside the selected hold" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, whiterun} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, eastmarch} = Worlds.create_hold(province, %{name: "Eastmarch"})
    {:ok, tower} = Worlds.create_location_type(world, %{name: "Tower"})
    {:ok, windhelm} = Worlds.create_location(eastmarch, tower, %{name: "Windhelm Watchtower"})

    assert Worlds.create_location_in_hold(whiterun, tower, %{name: "Western Watchtower"},
             parent_location: windhelm
           ) == {:error, :parent_location_outside_hold}

    refute Repo.get_by(Location, name: "Western Watchtower")
  end

  test "sets a hold capital from one of its locations" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})
    {:ok, location} = Worlds.create_location(hold, city, %{name: "Whiterun"})

    assert {:ok, updated_hold} = Worlds.set_hold_capital(hold, location)

    assert updated_hold.capital_location_id == location.id
  end

  test "rejects replacing a hold capital" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})
    {:ok, whiterun} = Worlds.create_location(hold, city, %{name: "Whiterun"})
    {:ok, riverwood} = Worlds.create_location(hold, city, %{name: "Riverwood"})
    {:ok, hold} = Worlds.set_hold_capital(hold, whiterun)

    assert Worlds.set_hold_capital(hold, riverwood) == {:error, :capital_already_set}
  end

  test "deletes a world with its geography" do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})

    assert {:ok, _world} = Worlds.delete_world(world)

    assert_raise Ecto.NoResultsError, fn ->
      Worlds.get_world!(world.id)
    end
  end

  test "deletes a province with nested holds and locations" do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    continent = continent_named(dashboard, "Tamriel")
    province = province_named(continent, "Skyrim")
    whiterun = Enum.find(province.holds, &(&1.name == "Whiterun"))
    riverwood = Enum.find(whiterun.locations, &(&1.name == "Riverwood"))

    assert {:ok, _province} = Worlds.delete_province(province)

    refute Repo.get(Province, province.id)
    refute Repo.get(Hold, whiterun.id)
    refute Repo.get(Location, riverwood.id)
    assert Repo.get(World, world.id)
  end

  test "deletes a location and clears it as capital" do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    dashboard = Worlds.get_world_dashboard!(world.id)
    continent = continent_named(dashboard, "Tamriel")
    province = province_named(continent, "Skyrim")
    whiterun = Enum.find(province.holds, &(&1.name == "Whiterun"))

    assert {:ok, _location} = Worlds.delete_location(whiterun.capital_location)

    dashboard = Worlds.get_world_dashboard!(world.id)
    continent = continent_named(dashboard, "Tamriel")
    province = province_named(continent, "Skyrim")
    whiterun = Enum.find(province.holds, &(&1.name == "Whiterun"))

    refute whiterun.capital_location
    refute Enum.any?(whiterun.locations, &(&1.name == "Whiterun"))
  end

  test "deletes a location type with child types and assigned locations" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, ruin} = Worlds.create_location_type(world, %{name: "Ruin"})
    {:ok, nordic_ruin} = Worlds.create_location_type(ruin, %{name: "Nordic Ruin"})
    {:ok, barrow} = Worlds.create_location(hold, nordic_ruin, %{name: "Bleak Falls Barrow"})

    assert {:ok, _location_type} = Worlds.delete_location_type(ruin)

    refute Repo.get(LocationType, ruin.id)
    refute Repo.get(LocationType, nordic_ruin.id)
    refute Repo.get(Location, barrow.id)
  end

  test "links creatures to locations" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, cave_type} = Worlds.create_location_type(world, %{name: "Cave"})
    {:ok, cave} = Worlds.create_location(hold, cave_type, %{name: "Graywinter Watch"})
    {:ok, creature_type} = Worlds.create_creature_type(world, %{name: "Beast"})

    {:ok, troll} =
      Worlds.create_creature(world, %{name: "Frost Troll"}, creature_type: creature_type)

    assert {:ok, _encounter} =
             Worlds.create_creature_location(troll, cave, %{
               presence: "lair",
               description: "A known troll den"
             })

    troll = Repo.get!(Creature, troll.id)
    troll = Repo.preload(troll, :locations)

    assert Enum.any?(troll.locations, &(&1.name == "Graywinter Watch"))
  end

  defp continent_named(continents, name) when is_list(continents) do
    Enum.find(continents, &(&1.name == name))
  end

  defp continent_named(world, name) do
    Enum.find(world.continents, &(&1.name == name))
  end

  defp province_named(continent, name) do
    Enum.find(continent.provinces, &(&1.name == name))
  end

  defp hold_named(province, name) do
    Enum.find(province.holds, &(&1.name == name))
  end

  defp cave_location?(hold, name) do
    Enum.any?(hold.locations, fn location ->
      location.name == name && location.location_type.name == "Cave"
    end)
  end

  defp location_count(province) do
    province.holds
    |> Enum.flat_map(& &1.locations)
    |> length()
  end

  defp skyrim_skill_names do
    [
      "Alchemy",
      "Alteration",
      "Archery",
      "Block",
      "Conjuration",
      "Destruction",
      "Enchanting",
      "Heavy Armor",
      "Illusion",
      "Light Armor",
      "Lockpicking",
      "One-handed",
      "Pickpocket",
      "Restoration",
      "Smithing",
      "Sneak",
      "Speech",
      "Two-handed"
    ]
  end
end
