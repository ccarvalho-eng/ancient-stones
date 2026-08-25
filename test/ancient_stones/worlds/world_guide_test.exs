defmodule AncientStones.Worlds.WorldGuideTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.WorldExports.{WorldGuideEpub, WorldGuidePdf, WorldManual}
  alias AncientStones.Galaxies
  alias AncientStones.Maps
  alias AncientStones.Worlds
  alias AncientStones.Worlds.WorldGuide

  test "loads a world snapshot and renders a PDF document" do
    assert {:ok, galaxy} =
             Galaxies.create_galaxy(%{
               name: "Elvstjerne",
               description: "The old star river."
             })

    assert {:ok, world} =
             Worlds.create_world(
               %{
                 name: "Aldrun",
                 description: "An ancient world of northern seas and many climates.",
                 primary_star_name: "Eldsol",
                 orbital_period_days: 412,
                 axial_tilt_degrees: 24.5,
                 day_length_hours: 26,
                 mean_radius_km: 7_112,
                 mass_earths: 1.04,
                 surface_gravity_m_s2: 9.86,
                 orbital_distance_au: 1.02,
                 orbital_eccentricity: 0.018,
                 atmospheric_pressure_atm: 1.02,
                 bond_albedo: 0.30,
                 ocean_fraction: 0.68,
                 star_mass_solar: 1.01,
                 star_luminosity_solar: 1.02,
                 star_temperature_k: 5_785,
                 map_projection: "Equal Earth"
               },
               galaxy: galaxy
             )

    assert {:ok, _moon} =
             Worlds.create_moon(world, %{
               name: "Mani",
               orbital_period_days: 26.89,
               semi_major_axis_km: 392_000,
               mean_radius_km: 1_720,
               mass_lunar: 0.96,
               orbital_eccentricity: 0.045,
               inclination_degrees: 5.2,
               tidal_role: "Sets the principal coastal tide."
             })

    guide = WorldGuide.load!(world.id)
    manual = WorldManual.build(guide)
    pdf = WorldGuidePdf.render(guide)

    assert guide.world.name == "Aldrun"
    assert guide.world.id == world.id
    assert guide.world.galaxy_name == "Elvstjerne"
    assert guide.world.primary_star_name == "Eldsol"
    assert guide.world.orbital_period_days == 412
    assert guide.world.axial_tilt_degrees == Decimal.new("24.5")
    assert guide.world.day_length_hours == Decimal.new("26")
    assert guide.world.mean_radius_km == 7_112
    assert Decimal.equal?(guide.world.mass_earths, Decimal.new("1.04"))
    assert Decimal.equal?(guide.world.surface_gravity_m_s2, Decimal.new("9.86"))
    assert Decimal.equal?(guide.world.orbital_distance_au, Decimal.new("1.02"))
    assert Decimal.equal?(guide.world.orbital_eccentricity, Decimal.new("0.018"))
    assert Decimal.equal?(guide.world.atmospheric_pressure_atm, Decimal.new("1.02"))
    assert Decimal.equal?(guide.world.bond_albedo, Decimal.new("0.3"))
    assert Decimal.equal?(guide.world.ocean_fraction, Decimal.new("0.68"))
    assert Decimal.equal?(guide.world.star_mass_solar, Decimal.new("1.01"))
    assert Decimal.equal?(guide.world.star_luminosity_solar, Decimal.new("1.02"))
    assert guide.world.star_temperature_k == 5_785
    assert guide.world.map_projection == "Equal Earth"
    assert guide.continents == []
    assert guide.trade_routes == []
    assert guide.tax_policies == []

    assert Enum.find(manual.chapters, &(&1.id == "overview")).facts
           |> Enum.member?({"Surface gravity", "9.86 m/s²"})

    assert [%{title: "Mani"}] = Enum.find(manual.chapters, &(&1.id == "moons")).records
    assert pdf =~ "%PDF-"
    assert byte_size(pdf) > 1_000
  end

  test "renders linked PDF contents and includes persisted maps in the manual" do
    {:ok, world} = Worlds.create_world(%{name: "Aldrun"})

    {:ok, map_document} =
      Maps.create_world_map(world, %{
        "name" => "Aldrun World Map",
        "description" => "Continents and northern seas.",
        "kind" => "world"
      })

    guide = WorldGuide.load!(world.id)
    manual = WorldManual.build(guide)
    maps_chapter = Enum.find(manual.chapters, &(&1.id == "maps"))

    assert Enum.map(maps_chapter.records, & &1.title) == [map_document.name]
    assert [%{map_canvas: %{document: %{"objects" => []}}}] = maps_chapter.records

    pdf = WorldGuidePdf.render(guide)

    assert pdf =~ "/Subtype /Link"
    assert pdf =~ "/S /GoTo"
    assert pdf =~ "/D ["
  end

  test "renders nested economic records" do
    guide = %{
      world: %{name: "Aldrun", description: "A world joined by old roads."},
      continents: [],
      characters: [],
      guilds: [],
      trade_routes: [
        %{
          name: "Crown Road",
          detail: "Gronvale to Stormoy - Road - Active",
          description: "A guarded realm road.",
          flows: [
            %{
              name: "Grain",
              detail: "Agriculture - 120 sacks - 240 Frostmark - Monthly",
              description: "Winter stores for the coast."
            }
          ]
        }
      ],
      tax_policies: [
        %{
          name: "Thing Road Levy",
          detail: "Road toll - 1.5% percentage - Thyrven - Active",
          description: "Funds bridges and winter shelters.",
          exemptions: [
            %{
              name: "Winter Relief",
              detail: "Hearthward Fellowship: 100% relief",
              description: "Applies to famine stores."
            }
          ],
          revenue_shares: [
            %{
              name: "High King",
              detail: "70% of collected revenue",
              description: nil
            }
          ]
        }
      ]
    }

    pdf = WorldGuidePdf.render(guide)

    assert pdf =~ "%PDF-"
    assert byte_size(pdf) > 1_000
  end

  test "exports aggregate capacity, resilience, coverage, and tax assessments" do
    {:ok, world} = Worlds.create_world(%{name: "Audrun"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tyrven"})
    {:ok, currency} = Worlds.put_continent_currency(continent, %{name: "Coin"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Frostgard"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Gronvale"})
    {:ok, coast} = Worlds.create_hold(province, %{name: "Hrafnvik"})

    {:ok, _profile} =
      Worlds.create_hold_economic_profile(hold, %{
        population_estimate: 24_000,
        household_estimate: 4_900,
        urban_population_estimate: 3_200,
        staple_reserve_months: "3.5",
        assessment_label: "Late harvest estimate",
        confidence: :medium
      })

    {:ok, _balance} =
      Worlds.create_commodity_balance(hold, %{
        commodity: "Rye equivalent",
        category: "staple food",
        unit: "tonne",
        annual_output: 5_100,
        annual_local_need: 4_600,
        stored_reserve: 900,
        bad_year_output_percentage: 62,
        storage_loss_percentage: 8
      })

    {:ok, route} =
      Worlds.create_trade_route(
        world,
        %{name: "North Road", transport_mode: :road},
        %{origin_hold: hold, destination_hold: coast}
      )

    {:ok, _flow} =
      Worlds.create_trade_flow(
        route,
        %{
          commodity: "Rye",
          quantity: 12,
          unit: "cart-load",
          declared_value: 240,
          coverage_scope: :representative_consignment,
          quantity_basis: "Ordinary fair-week convoy"
        },
        %{currency: currency}
      )

    {:ok, _commerce} =
      Worlds.create_hold_commerce_entry(hold, %{
        name: "Market dues",
        kind: "income",
        amount: 320,
        accounting_scope: :treasury_revenue,
        coverage_scope: :estimated_total
      })

    {:ok, policy} =
      Worlds.create_tax_policy(
        world,
        %{name: "Harvest Levy", tax_type: :land_levy, rate_basis: :percentage, rate: 6},
        %{hold: hold, currency: currency}
      )

    {:ok, _assessment} =
      Worlds.create_tax_assessment(
        policy,
        %{
          assessment_period_label: "Common year 312",
          cash_yield: 8_400,
          in_kind_value: 11_600,
          customary_labor_days: 2_900
        },
        %{currency: currency}
      )

    guide = WorldGuide.load!(world.id)
    manual = WorldManual.build(guide)
    economy = Enum.find(manual.chapters, &(&1.id == "economy"))
    atlas = Enum.find(manual.chapters, &(&1.id == "atlas"))

    assert [%{population_estimate: 24_000}] = guide.economic_profiles
    assert [%{name: "Rye equivalent"}] = guide.commodity_balances
    assert [%{name: "Harvest Levy"}] = guide.tax_assessments
    assert inspect(economy) =~ "Ordinary fair-week convoy"
    assert inspect(economy) =~ "Common year 312"
    assert inspect(atlas) =~ "Staple reserve months"
    assert inspect(atlas) =~ "Treasury revenue"

    epub = WorldGuideEpub.render(guide)
    assert {:ok, files} = :zip.unzip(epub, [:memory])

    assert {~c"EPUB/economy.xhtml", economy_xhtml} =
             List.keyfind(files, ~c"EPUB/economy.xhtml", 0)

    assert economy_xhtml =~ "Rye equivalent"
    assert economy_xhtml =~ "Common year 312"

    pdf = WorldGuidePdf.render(guide)
    assert pdf =~ "%PDF-"
    assert byte_size(pdf) > 1_000
  end

  test "exports named waters and ordered route itineraries" do
    {:ok, world} = Worlds.create_world(%{name: "Audrun"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tyrven"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Eirholm"})
    {:ok, origin_hold} = Worlds.create_hold(province, %{name: "Eirsund"})
    {:ok, destination_hold} = Worlds.create_hold(province, %{name: "Vardborg"})
    {:ok, location_type} = Worlds.create_location_type(world, %{name: "Landing"})

    {:ok, origin} =
      Worlds.create_location(origin_hold, location_type, %{name: "Great Flash Weir"})

    {:ok, destination} =
      Worlds.create_location(destination_hold, location_type, %{name: "Varda Quay"})

    {:ok, river} =
      Worlds.create_water_body(world, %{
        name: "Eirwater",
        kind: :river,
        salinity: :fresh,
        navigability: :shallow_draft,
        freeze_pattern: :seasonal,
        status: :seasonal,
        prevailing_conditions: "Spring freshets give way to steady summer reaches.",
        hazards: "Flash weirs, shoals, and autumn fog."
      })

    {:ok, estuary} =
      Worlds.create_water_body(world, %{
        name: "Varda Estuary",
        kind: :estuary,
        salinity: :brackish,
        navigability: :coastal,
        freeze_pattern: :rare,
        status: :active
      })

    {:ok, _connection} =
      Worlds.create_water_body_connection(
        world,
        %{
          connection_type: :flows_into,
          directionality: :one_way,
          navigability: :shallow_draft,
          seasonality: :spring_to_autumn,
          distance_km: 180
        },
        %{origin_water_body: river, destination_water_body: estuary}
      )

    {:ok, _province_link} =
      Worlds.create_province_water_body(province, river, %{relationship: :contains})

    {:ok, _province_link} =
      Worlds.create_province_water_body(province, estuary, %{relationship: :contains})

    {:ok, _origin} = Worlds.set_location_water_body(world, origin, river)
    {:ok, _destination} = Worlds.set_location_water_body(world, destination, estuary)

    {:ok, route} =
      Worlds.create_trade_route(
        world,
        %{name: "Eirwater Passage", transport_mode: :river, distance_km: 180},
        %{origin_hold: origin_hold, destination_hold: destination_hold}
      )

    {:ok, origin_stop} =
      Worlds.create_trade_route_stop(route, origin, %{
        position: 1,
        handling_notes: "Tow above the weir"
      })

    {:ok, destination_stop} =
      Worlds.create_trade_route_stop(route, destination, %{position: 2})

    {:ok, _leg} =
      Worlds.create_trade_route_leg(
        route,
        %{
          position: 1,
          transport_mode: :river,
          distance_km: 180,
          typical_travel_days: 5,
          seasonality: :spring_to_autumn,
          risk: :moderate
        },
        %{origin_stop: origin_stop, destination_stop: destination_stop, water_body: river}
      )

    guide = WorldGuide.load!(world.id)
    manual = WorldManual.build(guide)
    atlas = Enum.find(manual.chapters, &(&1.id == "atlas"))
    economy = Enum.find(manual.chapters, &(&1.id == "economy"))

    assert [%{name: "Eirwater"}, %{name: "Varda Estuary"}] = guide.water_bodies
    assert [%{name: "Eirwater to Varda Estuary"}] = guide.water_connections
    assert inspect(atlas) =~ "Spring freshets"
    assert inspect(atlas) =~ "Flash weirs"
    assert inspect(economy) =~ "Great Flash Weir"
    assert inspect(economy) =~ "5 days"
    assert inspect(economy) =~ "Eirwater to Varda Estuary"

    epub = WorldGuideEpub.render(guide)
    assert {:ok, files} = :zip.unzip(epub, [:memory])
    assert {~c"EPUB/atlas.xhtml", atlas_xhtml} = List.keyfind(files, ~c"EPUB/atlas.xhtml", 0)

    assert {~c"EPUB/economy.xhtml", economy_xhtml} =
             List.keyfind(files, ~c"EPUB/economy.xhtml", 0)

    assert atlas_xhtml =~ "Eirwater"
    assert economy_xhtml =~ "Great Flash Weir"
    assert economy_xhtml =~ "Eirwater to Varda Estuary"

    pdf = WorldGuidePdf.render(guide)
    assert pdf =~ "%PDF-"
    assert byte_size(pdf) > 1_000
  end

  test "renders a navigable EPUB with continent chapters" do
    guide = %{
      world: %{
        id: 1,
        name: "Aldrun",
        description: "An old world beneath Eldsol.",
        axial_tilt_degrees: Decimal.new("24.5")
      },
      continents: [
        %{
          name: "Thyrven",
          description: "A northern continent of fjords and broad inland plains."
        }
      ],
      characters: [],
      guilds: [],
      trade_routes: [],
      tax_policies: []
    }

    epub = WorldGuideEpub.render(guide)

    assert <<"PK", _rest::binary>> = epub
    assert {:ok, files} = :zip.unzip(epub, [:memory])
    assert {~c"mimetype", "application/epub+zip"} in files

    assert {~c"EPUB/package.opf", package} =
             List.keyfind(files, ~c"EPUB/package.opf", 0)

    assert package =~ guide.world.name

    assert {~c"EPUB/overview.xhtml", overview} =
             List.keyfind(files, ~c"EPUB/overview.xhtml", 0)

    assert overview =~ "24.5"

    assert {~c"EPUB/atlas.xhtml", chapter} =
             List.keyfind(files, ~c"EPUB/atlas.xhtml", 0)

    assert chapter =~ "Thyrven"
  end

  test "builds a deterministic manual from authored entities and relationships" do
    guide = %{
      world: %{name: "Aldrun", description: "An old world beneath Eldsol."},
      continents: [],
      characters: [],
      guilds: [],
      trade_routes: [],
      tax_policies: [],
      details: %{
        locations: [],
        characters: [
          %{
            name: "Alva Halfdansdottir",
            description: "A smith trusted by the valley steadings.",
            title: nil,
            role: nil,
            status: "alive",
            race: "Thyrveni",
            home_location: "The Mossbound Forge",
            occupations: [%{name: "Blacksmith", detail: "Master", description: nil}],
            locations: [%{name: "The Mossbound Forge", detail: "owner", description: nil}],
            guilds: [],
            skills: [],
            spells: [],
            inventory: []
          }
        ],
        guilds: [
          %{
            name: "Hearthward Fellowship",
            description: "Keeps roads and winter shelters.",
            leader: "Yrsa Ketilsdottir",
            headquarters: "Wayfarer's Hall",
            alignment: "Civic",
            members: [%{name: "Alva Halfdansdottir", detail: "artisan", description: nil}],
            influences: []
          }
        ],
        civilizations: [
          %{
            name: "Thyrveni",
            description: "The northern peoples.",
            era: "Crown Age",
            status: "active",
            races: [],
            locations: [%{name: "Svanedal", detail: "heartland", description: nil}]
          }
        ],
        maps: [
          %{
            name: "Northern Roads",
            kind: :region,
            description: "A survey of the winter roads.",
            width: 1600,
            height: 1000,
            parent: nil,
            items: []
          }
        ],
        documents: [
          %{
            name: "Road Warden's Ledger",
            kind: "ledger",
            source: "Wayfarer's Hall",
            summary: "Accounts of winter stores.",
            content: "Three sledges of rye reached the eastern shelter.",
            author: "Yrsa Ketilsdottir",
            location: "Wayfarer's Hall",
            guild: "Hearthward Fellowship",
            god: nil,
            race: nil,
            civilization: "Thyrveni"
          }
        ],
        connections: [
          %{
            name: "Winter patronage",
            type: "patron",
            status: "active",
            description: "The fellowship commissions tools for its shelters.",
            source: %{type: "Guild", name: "Hearthward Fellowship"},
            target: %{type: "Character", name: "Alva Halfdansdottir"}
          }
        ],
        races: [],
        gods: [],
        skill_trees: [],
        spells: [],
        items: [],
        creatures: [],
        calendars: [],
        timelines: []
      }
    }

    manual = WorldManual.build(guide)

    assert Enum.map(manual.chapters, & &1.id) == [
             "overview",
             "atlas",
             "maps",
             "civilizations",
             "guilds",
             "people",
             "documents",
             "connections"
           ]

    epub = WorldGuideEpub.render(guide)
    assert {:ok, files} = :zip.unzip(epub, [:memory])

    assert {~c"EPUB/people.xhtml", people} = List.keyfind(files, ~c"EPUB/people.xhtml", 0)
    assert people =~ "The Mossbound Forge"
    assert people =~ "Blacksmith"

    assert {~c"EPUB/guilds.xhtml", guilds} = List.keyfind(files, ~c"EPUB/guilds.xhtml", 0)
    assert guilds =~ "Yrsa Ketilsdottir"

    assert {~c"EPUB/documents.xhtml", documents} =
             List.keyfind(files, ~c"EPUB/documents.xhtml", 0)

    assert documents =~ "Three sledges of rye"

    assert {~c"EPUB/connections.xhtml", connections} =
             List.keyfind(files, ~c"EPUB/connections.xhtml", 0)

    assert connections =~ "The fellowship commissions tools"
  end

  test "exports historical Society records and character social observations" do
    {:ok, world} = Worlds.create_world(%{name: "Audrun"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tyrven"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Frostgard"})
    {:ok, hold} = Worlds.create_hold(province, %{name: "Gronvale"})
    {:ok, location_type} = Worlds.create_location_type(world, %{name: "Hall"})
    {:ok, hall} = Worlds.create_location(hold, location_type, %{name: "River Hall"})

    {:ok, first_character} =
      Worlds.create_character(world, %{
        name: "Ragna Torvaldsdottir",
        social_status: :freeholder,
        life_stage: :adult,
        wealth_band: :comfortable
      })

    {:ok, second_character} = Worlds.create_character(world, %{name: "Arne Ragnasson"})

    {:ok, household} =
      Worlds.create_household(
        world,
        %{name: "Ragna's household", household_type: :farmstead},
        home_location: hall,
        head_character: first_character
      )

    {:ok, _membership} =
      Worlds.create_household_membership(household, second_character, %{
        role: :child,
        is_primary: true,
        description: "Keeps a place at the hall while working the river fields."
      })

    {:ok, _holding} =
      Worlds.create_landholding(
        household,
        %{
          name: "River meadow rights",
          tenure_type: :customary,
          primary_use: :pasture
        },
        location: hall
      )

    {:ok, _relationship} =
      Worlds.create_character_relationship(world, first_character, second_character, %{
        relationship_type: :parent_child,
        character_a_role: "mother",
        character_b_role: "son"
      })

    guide = WorldGuide.load!(world.id)
    manual = WorldManual.build(guide)

    society = Enum.find(manual.chapters, &(&1.id == "society"))
    assert inspect(society) =~ "Ragna's household"
    assert inspect(society) =~ "River meadow rights"
    assert inspect(society) =~ "mother"
    assert inspect(society) =~ "Arne Ragnasson"

    people = Enum.find(manual.chapters, &(&1.id == "people"))
    ragna = Enum.find(people.records, &(&1.title == "Ragna Torvaldsdottir"))
    assert {"Social status", "freeholder"} in ragna.facts
    assert {"Life stage", "adult"} in ragna.facts
    assert {"Means", "comfortable"} in ragna.facts

    epub = WorldGuideEpub.render(guide)
    assert {:ok, files} = :zip.unzip(epub, [:memory])

    assert {~c"EPUB/society.xhtml", society_xhtml} =
             List.keyfind(files, ~c"EPUB/society.xhtml", 0)

    assert society_xhtml =~ "Ragna&#39;s household"
    assert society_xhtml =~ "River meadow rights"

    pdf = WorldGuidePdf.render(guide)
    assert pdf =~ "%PDF-"
    assert byte_size(pdf) > 1_000
  end

  test "exports merchant houses and partnerships with members and route work" do
    {:ok, world} = Worlds.create_world(%{name: "Audrun"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tyrven"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skeldvik"})
    {:ok, origin_hold} = Worlds.create_hold(province, %{name: "Kaldhavn"})
    {:ok, destination_hold} = Worlds.create_hold(province, %{name: "Vesthavn"})
    {:ok, location_type} = Worlds.create_location_type(world, %{name: "Quay"})
    {:ok, quay} = Worlds.create_location(origin_hold, location_type, %{name: "Raven Quay"})
    {:ok, character} = Worlds.create_character(world, %{name: "Ragna Torvaldsdottir"})

    {:ok, route} =
      Worlds.create_trade_route(
        world,
        %{name: "Western Sea Lane", transport_mode: :sea},
        %{origin_hold: origin_hold, destination_hold: destination_hold}
      )

    {:ok, venture} =
      Worlds.create_commercial_venture(
        world,
        %{
          name: "Raven Quay Partnership",
          venture_type: :felag,
          purpose: "Fit out and operate one seasonal cargo boat",
          capital_basis: "Hull shares, sailcloth, and working silver",
          formation_label: "Spring compact"
        },
        %{home_location: quay}
      )

    {:ok, _membership} =
      Worlds.create_venture_membership(
        venture,
        %{
          role: "sailing partner",
          contribution: "Navigation and one-sixth of the hull",
          share_percentage: 40
        },
        %{character: character}
      )

    {:ok, _route_link} =
      Worlds.create_venture_trade_route(venture, route, %{
        role: :carrier,
        description: "Operates spring and autumn sailings."
      })

    guide = WorldGuide.load!(world.id)
    manual = WorldManual.build(guide)
    economy = Enum.find(manual.chapters, &(&1.id == "economy"))

    assert [%{name: "Raven Quay Partnership"} = venture_card] = guide.commercial_ventures
    assert venture_card.detail =~ "Partnership (felag)"
    assert inspect(economy) =~ "Ragna Torvaldsdottir"
    assert inspect(economy) =~ "Western Sea Lane"
    assert inspect(economy) =~ "Hull shares, sailcloth, and working silver"
  end
end
