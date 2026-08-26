defmodule AncientStones.WorldsTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.Worlds
  alias AncientStones.Repo
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.Effect
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Household
  alias AncientStones.Worlds.HouseholdMembership
  alias AncientStones.Worlds.ItemEffect
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.CharacterRelationship
  alias AncientStones.Worlds.Landholding
  alias AncientStones.Worlds.Moon
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

  test "creates moons atomically with a world and derives their orbital periods" do
    assert {:ok, %World{} = world} =
             Worlds.create_world(%{
               name: "Pelagos",
               mass_earths: "1",
               mean_radius_km: 6_371,
               moons: [
                 %{
                   name: "Selene",
                   semi_major_axis_km: 384_400,
                   mean_radius_km: 1_737,
                   mass_lunar: "1",
                   orbital_eccentricity: "0.0549"
                 }
               ]
             })

    moon = Repo.get_by!(Moon, world_id: world.id, name: "Selene")

    assert Decimal.compare(moon.orbital_period_days, Decimal.new("27.28")) in [:eq, :gt]
    assert Decimal.compare(moon.orbital_period_days, Decimal.new("27.29")) == :lt
  end

  test "rolls back world creation when a nested moon is invalid" do
    assert {:error, changeset} =
             Worlds.create_world(%{
               name: "Unstable World",
               mean_radius_km: 6_000,
               moons: [
                 %{
                   name: "Buried Moon",
                   semi_major_axis_km: 5_000,
                   mean_radius_km: 500
                 }
               ]
             })

    assert %{moons: [_]} = errors_on(changeset)
    refute Repo.get_by(World, name: "Unstable World")
  end

  test "rejects orbital derivation inputs outside storage bounds" do
    changeset =
      Worlds.change_new_world(%{
        name: "Impossible World",
        mass_earths: "1e100",
        moons: [
          %{
            name: "Distant Moon",
            semi_major_axis_km: "1e100",
            mass_lunar: "1e100"
          }
        ]
      })

    refute changeset.valid?
    assert %{mass_earths: [_], moons: [_]} = errors_on(changeset)
  end

  test "updates, adds, and removes moons atomically with their world" do
    {:ok, world} =
      Worlds.create_world(%{
        name: "Pelagos",
        mass_earths: "1",
        mean_radius_km: 6_371,
        moons: [
          %{
            name: "Selene",
            orbital_period_days: "27.3",
            semi_major_axis_km: 384_400,
            mean_radius_km: 1_737,
            mass_lunar: "1"
          },
          %{
            name: "Thalassa",
            orbital_period_days: "12",
            semi_major_axis_km: 180_000,
            mean_radius_km: 500,
            mass_lunar: "0.1"
          }
        ]
      })

    selene = Repo.get_by!(Moon, world_id: world.id, name: "Selene")
    thalassa = Repo.get_by!(Moon, world_id: world.id, name: "Thalassa")

    assert {:ok, updated_world} =
             Worlds.update_world_with_moons(world, %{
               "name" => "Pelagos Prime",
               "mass_earths" => "1",
               "mean_radius_km" => "6371",
               "moons" => %{
                 "0" => %{
                   "id" => selene.id,
                   "name" => "Selene Major",
                   "orbital_period_days" => "27.3",
                   "semi_major_axis_km" => "384400",
                   "mean_radius_km" => "1737",
                   "mass_lunar" => "1"
                 },
                 "1" => %{
                   "id" => "",
                   "name" => "Nereid",
                   "orbital_period_days" => "",
                   "semi_major_axis_km" => "250000",
                   "mean_radius_km" => "800",
                   "mass_lunar" => "0.2"
                 }
               }
             })

    assert updated_world.name == "Pelagos Prime"
    assert Repo.get!(Moon, selene.id).name == "Selene Major"
    refute Repo.get(Moon, thalassa.id)

    nereid = Repo.get_by!(Moon, world_id: world.id, name: "Nereid")
    assert nereid.orbital_period_days
  end

  test "rejects moon ids belonging to another world and rolls back the update" do
    {:ok, world} = Worlds.create_world(%{name: "Pelagos", mean_radius_km: 6_371})

    {:ok, other_world} =
      Worlds.create_world(%{
        name: "Oceanus",
        mean_radius_km: 5_000,
        moons: [
          %{
            name: "Foreign Moon",
            orbital_period_days: "20",
            semi_major_axis_km: 200_000,
            mean_radius_km: 500
          }
        ]
      })

    foreign_moon = Repo.get_by!(Moon, world_id: other_world.id, name: "Foreign Moon")

    assert {:error, changeset} =
             Worlds.update_world_with_moons(world, %{
               "name" => "Compromised Name",
               "mean_radius_km" => "6371",
               "moons" => %{
                 "0" => %{
                   "id" => foreign_moon.id,
                   "name" => "Stolen Moon",
                   "orbital_period_days" => "20",
                   "semi_major_axis_km" => "200000",
                   "mean_radius_km" => "500"
                 }
               }
             })

    assert %{moons: [_]} = errors_on(changeset)
    assert Repo.get!(World, world.id).name == "Pelagos"
    assert Repo.get!(Moon, foreign_moon.id).name == "Foreign Moon"
  end

  test "rolls back the world and moon removals when a nested moon is invalid" do
    {:ok, world} =
      Worlds.create_world(%{
        name: "Pelagos",
        mean_radius_km: 6_371,
        moons: [
          %{
            name: "Selene",
            orbital_period_days: "27.3",
            semi_major_axis_km: 384_400,
            mean_radius_km: 1_737
          }
        ]
      })

    selene = Repo.get_by!(Moon, world_id: world.id, name: "Selene")

    assert {:error, changeset} =
             Worlds.update_world_with_moons(world, %{
               "name" => "Pelagos Prime",
               "mean_radius_km" => "6371",
               "moons" => %{
                 "0" => %{
                   "name" => "Falling Moon",
                   "orbital_period_days" => "1",
                   "semi_major_axis_km" => "6000",
                   "mean_radius_km" => "500"
                 }
               }
             })

    assert %{moons: moon_errors} = errors_on(changeset)
    assert Enum.any?(moon_errors, &Map.has_key?(&1, :semi_major_axis_km))
    assert Repo.get!(World, world.id).name == "Pelagos"
    assert Repo.get!(Moon, selene.id).name == "Selene"
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

    assert continent.currency.name == "Septims"
    assert Decimal.equal?(continent.currency.value_per_unit, Decimal.new("1.00"))
    assert continent.currency.value_basis == "hearth-day"
    assert akavir.currency.name == "Akaviri Taels"
    assert Decimal.equal?(akavir.currency.value_per_unit, Decimal.new("0.80"))

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

    all_provinces = Enum.flat_map(dashboard.continents, & &1.provinces)
    all_holds = Enum.flat_map(all_provinces, & &1.holds)
    all_locations = Enum.flat_map(all_holds, & &1.locations)

    assert length(all_provinces) == 28
    assert length(all_holds) == 94
    assert length(all_locations) == 248
    assert Enum.all?(all_provinces, &(&1.holds != []))
    assert location_count(province) == 163
    assert Enum.count(all_provinces, & &1.capital_hold_id) == 6
    assert Enum.count(all_locations, & &1.water_body_id) == 16

    assert province_named(continent_named(dashboard, "Atmora"), "Frozen Heartland")
           |> hold_named("Long Winter Interior")

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
    assert Enum.sum(Enum.map(dashboard.guilds, &length(&1.guild_memberships))) == 13
    assert Enum.any?(dashboard.gods, &(&1.name == "Sithis"))
    assert Enum.any?(dashboard.characters, &(&1.name == "Ulfric Stormcloak"))
    assert Enum.any?(dashboard.characters, &(&1.name == "Torygg" && &1.status == "dead"))
    assert Enum.any?(dashboard.occupations, &(&1.name == "Jarl"))
    assert Enum.any?(dashboard.creature_types, &(&1.name == "Dragon"))
    assert Enum.any?(dashboard.creatures, &(&1.name == "Frost Troll"))
    assert dashboard.galaxy.name == "Mundus"
    assert dashboard.primary_star_name == "Magnus"
    assert dashboard.orbital_period_days == 365
    assert Decimal.equal?(dashboard.axial_tilt_degrees, Decimal.new("23.5"))
    assert Decimal.equal?(dashboard.mass_earths, Decimal.new("1.0"))
    assert Decimal.equal?(dashboard.surface_gravity_m_s2, Decimal.new("9.81"))
    assert Decimal.equal?(dashboard.orbital_distance_au, Decimal.new("1.0"))
    assert Decimal.equal?(dashboard.ocean_fraction, Decimal.new("0.71"))
    assert dashboard.star_temperature_k == 5_772
    assert Enum.map(dashboard.moons, & &1.name) |> Enum.sort() == ["Masser", "Secunda"]

    assert Enum.all?(all_provinces, fn province ->
             province.area_km2 && province.latitude && province.longitude &&
               province.mean_winter_temperature_c && province.mean_summer_temperature_c &&
               province.annual_precipitation_mm && province.frost_free_days
           end)

    assert Enum.all?(all_holds, fn hold ->
             hold.area_km2 && hold.latitude && hold.longitude &&
               hold.mean_winter_temperature_c && hold.mean_summer_temperature_c &&
               hold.annual_precipitation_mm && hold.frost_free_days
           end)

    assert Enum.all?(all_locations, &(&1.latitude && &1.longitude))

    assert Enum.all?(continent.calendars, fn calendar ->
             calendar.intercalation_interval_years && calendar.intercalary_days &&
               calendar.intercalation_rule
           end)

    assert Enum.any?(dashboard.civilizations, &(&1.name == "Dwemer"))
    assert length(dashboard.characters) == 50
    assert Enum.any?(dashboard.documents, &(&1.title == "The Book of the Dragonborn"))
    assert Enum.any?(dashboard.political_offices, &(&1.office == "High King"))
    assert length(dashboard.political_offices) == 34
    assert length(dashboard.location_types) == 59
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

    assert length(Worlds.list_hold_economic_profiles(world)) == 9
    assert length(Worlds.list_commodity_balances(world)) == 27
    assert length(Worlds.list_water_bodies(world)) == 12
    assert length(Worlds.list_water_body_connections(world)) == 11
    assert length(Worlds.list_province_water_bodies(world)) == 12

    routes = Worlds.list_trade_routes(world)
    assert length(routes) == 8
    assert length(Worlds.list_trade_flows(world)) == 16
    assert Enum.sum(Enum.map(routes, &length(Worlds.list_trade_route_stops(&1)))) == 22
    assert Enum.sum(Enum.map(routes, &length(Worlds.list_trade_route_legs(&1)))) == 14

    assert routes
           |> Enum.flat_map(&Worlds.list_trade_route_legs/1)
           |> Enum.flat_map(& &1.water_traversals)
           |> length() == 2

    tax_policies = Worlds.list_tax_policies(world)
    assert length(tax_policies) == 7
    assert length(Worlds.list_tax_assessments(world)) == 7
    assert length(Worlds.list_tax_exemptions(world)) == 2

    assert Enum.sum(Enum.map(tax_policies, &length(Worlds.list_tax_revenue_shares(&1)))) ==
             14

    households = Worlds.list_households(world)
    assert length(households) == 6
    assert Enum.sum(Enum.map(households, &length(&1.memberships))) == 6
    assert Enum.all?(households, &(&1.resident_count && &1.dependent_count && &1.servant_count))
    assert length(Worlds.list_landholdings(world)) == 6

    assert Enum.all?(dashboard.political_offices, fn office ->
             office.selection_method && office.succession_rule && office.term_started_year
           end)

    assert Enum.all?(dashboard.creatures, fn creature ->
             creature.population_status && creature.diet && creature.ecological_role &&
               creature.economic_uses && creature.seasonal_pattern
           end)

    ventures = Worlds.list_commercial_ventures(world)
    assert length(ventures) == 5
    assert Enum.sum(Enum.map(ventures, &length(&1.memberships))) == 7
    assert Enum.sum(Enum.map(ventures, &length(&1.trade_route_links))) == 6

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

    assert ulfric.role == "Jarl"
    assert ulfric.character_role.name == "Jarl"
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
    assert document.content =~ "Riften plots"

    template_document_titles = Enum.map(dashboard.documents, & &1.title)

    assert "The Aetherium Wars" in template_document_titles
    assert "Shadowmarks" in template_document_titles
    assert "Gallus's Encoded Journal" in template_document_titles
    assert "Esbern's Dragon Research" in template_document_titles

    aetherium_wars = Enum.find(dashboard.documents, &(&1.title == "The Aetherium Wars"))

    assert aetherium_wars.civilization.name == "Dwemer"
    assert aetherium_wars.location.name == "Alftand"

    shadowmarks = Enum.find(dashboard.documents, &(&1.title == "Shadowmarks"))

    assert shadowmarks.guild.name == "Thieves Guild"
    assert shadowmarks.god.name == "Nocturnal"

    esbern_notes = Enum.find(dashboard.documents, &(&1.title == "Esbern's Dragon Research"))

    assert esbern_notes.kind == "journal"
    assert esbern_notes.author_character.name == "Esbern"
    assert esbern_notes.guild.name == "Blades"

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
    assert is_nil(calendar.year_start_angle)
    assert is_nil(calendar.perihelion_day)
    assert calendar.months |> Enum.map(& &1.days) |> Enum.sum() == 365
    assert Enum.any?(calendar.months, &(&1.name == "Frostfall" && &1.position == 10))

    smithing = Enum.find(dashboard.skills, &(&1.name == "Smithing"))

    assert smithing.skill_tree.name == "Smithing"
    assert Enum.any?(smithing.skill_tree.perks, &(&1.name == "Dragon Armor"))

    nord = Enum.find(dashboard.races, &(&1.name == "Nord"))
    altmer = Enum.find(dashboard.races, &(&1.name == "Altmer"))

    assert nord.description =~ "Northern humans"
    assert Enum.any?(nord.traits, &(&1.name == "Battle Cry" && &1.category == :power))
    assert Enum.any?(nord.traits, &(&1.name == "Resist Frost" && &1.category == :perk))
    assert Enum.any?(altmer.traits, &(&1.name == "Highborn" && &1.category == :power))
  end

  test "stores ordered weekday names on calendars" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    weekday_names = ["Montak", "Midtak", "Fretak"]

    assert {:ok, calendar} =
             Worlds.create_calendar(continent, %{
               name: "Tamrielic Calendar",
               days_per_week: 3,
               weekday_names: weekday_names
             })

    assert calendar.weekday_names == weekday_names

    assert {:error, changeset} =
             Worlds.update_calendar(calendar, %{
               days_per_week: 2,
               weekday_names: weekday_names
             })

    assert %{weekday_names: [_ | _]} = errors_on(changeset)
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

  test "rejects overlapping location map coordinates within a hold" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, whiterun} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, eastmarch} = Worlds.create_hold(province, %{name: "Eastmarch"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})

    assert {:ok, _location} =
             Worlds.create_location(whiterun, city, %{
               name: "Whiterun",
               map_x: 4,
               map_y: 12
             })

    assert {:error, changeset} =
             Worlds.create_location(whiterun, city, %{
               name: "Riverwood",
               map_x: 4,
               map_y: 12
             })

    assert %{map_x: ["coordinates already used by another location in this hold"]} =
             errors_on(changeset)

    assert {:ok, _location} =
             Worlds.create_location(eastmarch, city, %{
               name: "Windhelm",
               map_x: 4,
               map_y: 12
             })
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
    {:ok, world} = Worlds.create_world(%{name: "Northern Realm"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, whiterun} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, town} = Worlds.create_location_type(world, %{name: "Town"})
    {:ok, riverwood} = Worlds.create_location(whiterun, town, %{name: "Riverwood"})

    assert {:ok, _province} = Worlds.delete_province(province)

    refute Repo.get(Province, province.id)
    refute Repo.get(Hold, whiterun.id)
    refute Repo.get(Location, riverwood.id)
    assert Repo.get(World, world.id)
  end

  test "deletes a location and clears it as capital" do
    {:ok, world} = Worlds.create_world(%{name: "Northern Realm"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})
    {:ok, whiterun} = Worlds.create_hold(province, %{name: "Whiterun"})
    {:ok, city} = Worlds.create_location_type(world, %{name: "City"})
    {:ok, capital} = Worlds.create_location(whiterun, city, %{name: "Whiterun"})
    {:ok, _whiterun} = Worlds.set_hold_capital(whiterun, capital)

    assert {:ok, _location} = Worlds.delete_location(capital)

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

  test "updates a world name" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    assert {:ok, updated_world} = Worlds.update_world(world, %{"name" => "Nirn Prime"})
    assert updated_world.name == "Nirn Prime"
    assert Repo.get!(World, world.id).name == "Nirn Prime"
  end

  test "does not update a world with an invalid name" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    assert {:error, changeset} = Worlds.update_world(world, %{"name" => nil})
    assert %{name: [_ | _]} = errors_on(changeset)
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

  describe "historical society records" do
    test "creates a household with an optional head in one transaction" do
      %{world: world, location: location} = society_geography_fixture("Audrun")
      {:ok, head} = Worlds.create_character(world, %{name: "Ragna Torvaldsdottir"})

      assert {:ok, %Household{} = household} =
               Worlds.create_household(
                 world,
                 %{
                   name: "Ragna's household",
                   household_type: :farmstead,
                   description: "A working farmstead household of kin, dependents, and laborers."
                 },
                 home_location: location,
                 head_character: head
               )

      household = Worlds.get_household!(world, household.id)

      assert household.home_location.id == location.id
      assert [%HouseholdMembership{role: :head, is_primary: true}] = household.memberships
      assert hd(household.memberships).character.id == head.id
    end

    test "rejects household references from another world without partial writes" do
      %{world: world} = society_geography_fixture("Audrun")
      %{location: foreign_location} = society_geography_fixture("Tyrven")

      assert Worlds.create_household(world, %{name: "Foreign hall"},
               home_location: foreign_location
             ) == {:error, :home_location_outside_world}

      refute Repo.get_by(Household, name: "Foreign hall")
    end

    test "allows only one active primary household per character" do
      %{world: world} = society_geography_fixture("Audrun")
      {:ok, character} = Worlds.create_character(world, %{name: "Leif Ketilsson"})
      {:ok, first_household} = Worlds.create_household(world, %{name: "Ketil's farm"})
      {:ok, second_household} = Worlds.create_household(world, %{name: "Leif's winter lodging"})

      assert {:ok, _membership} =
               Worlds.create_household_membership(first_household, character, %{
                 role: :child,
                 is_primary: true
               })

      assert {:error, changeset} =
               Worlds.create_household_membership(second_household, character, %{
                 role: :guest,
                 is_primary: true
               })

      assert %{character_id: [_]} = errors_on(changeset)
    end

    test "rolls back household creation when the initial head membership fails" do
      %{world: world} = society_geography_fixture("Audrun")
      {:ok, character} = Worlds.create_character(world, %{name: "Leif Ketilsson"})

      {:ok, first_household} =
        Worlds.create_household(world, %{name: "Ketil's farm"}, head_character: character)

      assert {:error, changeset} =
               Worlds.create_household(
                 world,
                 %{name: "Uncommitted winter lodging"},
                 head_character: character
               )

      assert %{character_id: [_]} = errors_on(changeset)
      assert Worlds.get_household!(world, first_household.id)
      refute Repo.get_by(Household, name: "Uncommitted winter lodging")
    end

    test "rejects a household member from another world" do
      %{world: world} = society_geography_fixture("Audrun")
      %{world: foreign_world} = society_geography_fixture("Tyrven")
      {:ok, household} = Worlds.create_household(world, %{name: "Ketil's farm"})
      {:ok, foreign_character} = Worlds.create_character(foreign_world, %{name: "Yrsa"})

      assert Worlds.create_household_membership(household, foreign_character, %{
               role: :guest
             }) == {:error, :character_outside_world}
    end

    test "canonicalizes relationships and rejects self-links and reciprocal duplicates" do
      %{world: world} = society_geography_fixture("Audrun")
      {:ok, mother} = Worlds.create_character(world, %{name: "Sigrid Ketilsdottir"})
      {:ok, son} = Worlds.create_character(world, %{name: "Arne Sigurdsson"})

      assert {:ok, %CharacterRelationship{} = relationship} =
               Worlds.create_character_relationship(world, mother, son, %{
                 relationship_type: :parent_child,
                 character_a_role: "mother",
                 character_b_role: "son"
               })

      assert relationship.character_a_id < relationship.character_b_id

      assert {:error, duplicate_changeset} =
               Worlds.create_character_relationship(world, son, mother, %{
                 relationship_type: :parent_child,
                 character_a_role: "son",
                 character_b_role: "mother"
               })

      assert %{character_a_id: [_]} = errors_on(duplicate_changeset)

      assert Worlds.create_character_relationship(world, mother, mother, %{
               relationship_type: :siblings
             }) == {:error, :relationship_requires_two_characters}
    end

    test "keeps relationship roles with their people when canonical order swaps" do
      %{world: world} = society_geography_fixture("Audrun")
      {:ok, first_character} = Worlds.create_character(world, %{name: "Sigrid"})
      {:ok, second_character} = Worlds.create_character(world, %{name: "Arne"})

      [canonical_first, canonical_second] =
        Enum.sort_by([first_character, second_character], & &1.id)

      assert {:ok, relationship} =
               Worlds.create_character_relationship(
                 world,
                 canonical_second,
                 canonical_first,
                 %{
                   relationship_type: :guardian_ward,
                   character_a_role: "guardian",
                   character_b_role: "ward"
                 }
               )

      assert relationship.character_a_id == canonical_first.id
      assert relationship.character_a_role == "ward"
      assert relationship.character_b_id == canonical_second.id
      assert relationship.character_b_role == "guardian"

      {:ok, third_character} = Worlds.create_character(world, %{name: "Bolli"})

      assert {:ok, inferred} =
               Worlds.create_character_relationship(
                 world,
                 canonical_first,
                 third_character,
                 %{relationship_type: :foster_parent_child}
               )

      roles_by_character = %{
        inferred.character_a_id => inferred.character_a_role,
        inferred.character_b_id => inferred.character_b_role
      }

      assert roles_by_character[canonical_first.id] == "foster parent"
      assert roles_by_character[third_character.id] == "foster child"
    end

    test "rejects relationships that cross worlds" do
      %{world: world} = society_geography_fixture("Audrun")
      %{world: other_world} = society_geography_fixture("Tyrven")
      {:ok, local} = Worlds.create_character(world, %{name: "Astrid"})
      {:ok, foreign} = Worlds.create_character(other_world, %{name: "Yrsa"})

      assert Worlds.create_character_relationship(world, local, foreign, %{
               relationship_type: :siblings
             }) == {:error, :character_outside_world}
    end

    test "records land tenure at exactly one world-scoped geographic level" do
      %{world: world, hold: hold, location: location} = society_geography_fixture("Audrun")
      {:ok, household} = Worlds.create_household(world, %{name: "Sten's household"})

      assert {:ok, %Landholding{} = holding} =
               Worlds.create_landholding(
                 household,
                 %{
                   name: "South meadow rights",
                   tenure_type: :communal_right,
                   primary_use: :pasture
                 },
                 hold: hold
               )

      assert holding.hold_id == hold.id
      assert is_nil(holding.location_id)

      assert Worlds.create_landholding(
               household,
               %{name: "Ambiguous holding", tenure_type: :customary},
               hold: hold,
               location: location
             ) == {:error, :landholding_requires_one_geographic_scope}
    end

    test "rejects foreign geographic scopes when creating or updating tenure" do
      %{world: world, hold: hold} = society_geography_fixture("Audrun")
      %{hold: foreign_hold, location: foreign_location} = society_geography_fixture("Tyrven")
      {:ok, household} = Worlds.create_household(world, %{name: "Sten's household"})

      assert Worlds.create_landholding(
               household,
               %{name: "Foreign meadow", tenure_type: :customary},
               hold: foreign_hold
             ) == {:error, :hold_outside_world}

      {:ok, holding} =
        Worlds.create_landholding(
          household,
          %{name: "Home meadow", tenure_type: :customary},
          hold: hold
        )

      assert Worlds.update_landholding(
               holding,
               %{name: "Foreign workshop", tenure_type: :customary},
               location: foreign_location
             ) == {:error, :location_outside_world}

      assert Repo.get!(Landholding, holding.id).hold_id == hold.id
    end

    test "preserves landholding history when a household deletion is attempted" do
      %{world: world, hold: hold} = society_geography_fixture("Audrun")
      {:ok, household} = Worlds.create_household(world, %{name: "Ingrid's household"})

      {:ok, _holding} =
        Worlds.create_landholding(
          household,
          %{name: "North field", tenure_type: :allodial, primary_use: :farming},
          hold: hold
        )

      assert Worlds.delete_household(household) == {:error, :household_has_landholdings}
      assert Repo.get(Household, household.id)
    end

    test "refuses geographic deletion while tenure records still refer to it" do
      %{
        world: world,
        continent: continent,
        province: province,
        hold: hold,
        location_type: location_type,
        location: location
      } = society_geography_fixture("Audrun")

      {:ok, household} = Worlds.create_household(world, %{name: "Ingrid's household"})

      {:ok, _holding} =
        Worlds.create_landholding(
          household,
          %{name: "Workshop right", tenure_type: :customary, primary_use: :workshop},
          location: location
        )

      assert Worlds.delete_location(location) == {:error, :geography_has_landholdings}
      assert Worlds.delete_hold(hold) == {:error, :geography_has_landholdings}
      assert Worlds.delete_province(province) == {:error, :geography_has_landholdings}
      assert Worlds.delete_continent(continent) == {:error, :geography_has_landholdings}

      assert Worlds.delete_location_type(location_type) ==
               {:error, :geography_has_landholdings}

      assert Repo.get(Location, location.id)
      assert Repo.get(Hold, hold.id)
    end

    test "refuses character deletion while household history refers to the person" do
      %{world: world} = society_geography_fixture("Audrun")
      {:ok, character} = Worlds.create_character(world, %{name: "Ingrid"})

      {:ok, household} =
        Worlds.create_household(world, %{name: "Ingrid's household"}, head_character: character)

      assert Worlds.delete_character(character) == {:error, :character_has_society_history}
      assert Repo.get(Character, character.id)
      assert Worlds.get_household!(world, household.id).memberships != []
    end

    test "refuses character deletion while a personal relationship refers to the person" do
      %{world: world} = society_geography_fixture("Audrun")
      {:ok, first_character} = Worlds.create_character(world, %{name: "Ingrid"})
      {:ok, second_character} = Worlds.create_character(world, %{name: "Ragna"})

      {:ok, relationship} =
        Worlds.create_character_relationship(world, first_character, second_character, %{
          relationship_type: :siblings
        })

      assert Worlds.delete_character(first_character) ==
               {:error, :character_has_society_history}

      assert Repo.get(Character, first_character.id)
      assert Repo.get(CharacterRelationship, relationship.id)
    end

    test "deletes the Society graph in dependency order with its world" do
      %{world: world, hold: hold} = society_geography_fixture("Audrun")
      {:ok, character} = Worlds.create_character(world, %{name: "Ingrid"})
      {:ok, relative} = Worlds.create_character(world, %{name: "Ragna"})

      {:ok, household} =
        Worlds.create_household(world, %{name: "Ingrid's household"}, head_character: character)

      [membership] = Worlds.list_household_memberships(household)

      {:ok, relationship} =
        Worlds.create_character_relationship(world, character, relative, %{
          relationship_type: :siblings
        })

      {:ok, holding} =
        Worlds.create_landholding(
          household,
          %{name: "North field", tenure_type: :customary, primary_use: :farming},
          hold: hold
        )

      assert {:ok, _world} = Worlds.delete_world(world)
      refute Repo.get(World, world.id)
      refute Repo.get(Household, household.id)
      refute Repo.get(HouseholdMembership, membership.id)
      refute Repo.get(CharacterRelationship, relationship.id)
      refute Repo.get(Landholding, holding.id)
    end

    test "stores broad social observations without requiring them for unknown people" do
      %{world: world} = society_geography_fixture("Audrun")

      assert {:ok, known} =
               Worlds.create_character(world, %{
                 name: "Bolli Arnfinnsson",
                 social_status: :freeholder,
                 life_stage: :adult,
                 wealth_band: :comfortable
               })

      assert known.social_status == :freeholder
      assert known.life_stage == :adult
      assert known.wealth_band == :comfortable

      assert {:ok, unknown} = Worlds.create_character(world, %{name: "Unnamed traveler"})
      assert is_nil(unknown.social_status)
    end
  end

  defp continent_named(continents, name) when is_list(continents) do
    Enum.find(continents, &(&1.name == name))
  end

  defp continent_named(world, name) do
    Enum.find(world.continents, &(&1.name == name))
  end

  defp society_geography_fixture(world_name) do
    {:ok, world} = Worlds.create_world(%{name: world_name})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Known Lands"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Frostgard"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Gronvale"})
    {:ok, type} = Worlds.create_location_type(world, %{name: "Farmstead"})
    {:ok, location} = Worlds.create_location(hold, type, %{name: "River Farm"})

    %{
      world: world,
      continent: continent,
      province: province,
      hold: hold,
      location_type: type,
      location: location
    }
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
