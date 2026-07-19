# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AncientStone.Repo.insert!(%AncientStone.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AncientStone.Repo
alias AncientStone.Worlds
alias AncientStone.Worlds.Continent
alias AncientStone.Worlds.Hold
alias AncientStone.Worlds.Province
alias AncientStone.Worlds.World

world_data = %{
  name: "Nirn",
  description:
    "The mortal world where myth, empire, wilderness, and old magic shape the lives of its peoples.",
  continents: [
    %{
      name: "Tamriel",
      description:
        "A vast continent of competing provinces, ancient ruins, trade roads, and uneasy alliances.",
      provinces: [
        %{
          name: "Skyrim",
          description:
            "A cold northern province of mountains, old kingdoms, clan politics, barrows, and hard-won roads.",
          holds: [
            %{
              name: "Eastmarch",
              description:
                "Volcanic eastern lands marked by hot springs, old Nordic power, and hard stone roads."
            },
            %{
              name: "Falkreath",
              previous_name: "Falkreath Hold",
              description:
                "Forested southern lands of hunting roads, graveyards, border passes, and old watchtowers."
            },
            %{
              name: "Haafingar",
              description:
                "A coastal domain of imperial influence, sea trade, steep cliffs, and fortified roads."
            },
            %{
              name: "Hjaalmarch",
              description:
                "Marshland country of fog, fishing villages, old burial grounds, and uneasy waterways."
            },
            %{
              name: "The Pale",
              description: "Northern snowfields, mines, shipwreck coasts, and isolated roads."
            },
            %{
              name: "The Reach",
              description:
                "Rugged western cliffs, silver mines, river canyons, and contested highlands."
            },
            %{
              name: "The Rift",
              description:
                "Southeastern autumn forests, lake trade, farms, and shadowed crossings."
            },
            %{
              name: "Whiterun",
              previous_name: "Whiterun Hold",
              description: "Central open tundra, farms, trade roads, and watchful barrows."
            },
            %{
              name: "Winterhold",
              description:
                "Ruined northern ice, storms, old learning, and a coastline shaped by disaster."
            }
          ]
        }
      ]
    }
  ]
}

unwrap_seed! = fn result, label ->
  case result do
    {:ok, record} -> record
    {:error, changeset} -> raise "failed to seed #{label}: #{inspect(changeset.errors)}"
  end
end

upsert_world = fn attrs ->
  seed_attrs = Map.take(attrs, [:name, :description])

  case Repo.get_by(World, name: seed_attrs.name) do
    nil ->
      unwrap_seed!.(Worlds.create_world(seed_attrs), seed_attrs.name)

    world ->
      world
      |> World.changeset(seed_attrs)
      |> Repo.update!()
  end
end

upsert_continent = fn world, attrs ->
  seed_attrs = Map.take(attrs, [:name, :description])

  case Repo.get_by(Continent, world_id: world.id, name: seed_attrs.name) do
    nil ->
      unwrap_seed!.(Worlds.create_continent(world, seed_attrs), seed_attrs.name)

    continent ->
      continent
      |> Continent.changeset(seed_attrs)
      |> Repo.update!()
  end
end

upsert_province = fn continent, attrs ->
  seed_attrs = Map.take(attrs, [:name, :description])

  case Repo.get_by(Province, continent_id: continent.id, name: seed_attrs.name) do
    nil ->
      unwrap_seed!.(Worlds.create_province(continent, seed_attrs), seed_attrs.name)

    province ->
      province
      |> Province.changeset(seed_attrs)
      |> Repo.update!()
  end
end

upsert_hold = fn province, attrs ->
  seed_attrs = Map.take(attrs, [:name, :description])

  hold =
    Repo.get_by(Hold, province_id: province.id, name: seed_attrs.name) ||
      Repo.get_by(Hold, province_id: province.id, name: attrs[:previous_name])

  case hold do
    nil ->
      unwrap_seed!.(Worlds.create_hold(province, seed_attrs), seed_attrs.name)

    hold ->
      hold
      |> Hold.changeset(seed_attrs)
      |> Repo.update!()
  end
end

world = upsert_world.(world_data)

for continent_data <- world_data.continents do
  continent = upsert_continent.(world, continent_data)

  for province_data <- continent_data.provinces do
    province = upsert_province.(continent, province_data)

    for hold_data <- province_data.holds do
      upsert_hold.(province, hold_data)
    end
  end
end
