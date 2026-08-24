defmodule AncientStones.Worlds.WorldGuideTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.WorldExports.WorldGuidePdf
  alias AncientStones.Galaxies
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
end
