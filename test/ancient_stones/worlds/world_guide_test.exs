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
                 map_projection: "Equal Earth"
               },
               galaxy: galaxy
             )

    guide = WorldGuide.load!(world.id)
    pdf = WorldGuidePdf.render(guide)

    assert guide.world.name == "Aldrun"
    assert guide.world.id == world.id
    assert guide.world.galaxy_name == "Elvstjerne"
    assert guide.world.primary_star_name == "Eldsol"
    assert guide.world.orbital_period_days == 412
    assert guide.world.axial_tilt_degrees == Decimal.new("24.5")
    assert guide.world.day_length_hours == Decimal.new("26")
    assert guide.world.mean_radius_km == 7_112
    assert guide.world.map_projection == "Equal Earth"
    assert guide.continents == []
    assert guide.trade_routes == []
    assert guide.tax_policies == []
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
end
