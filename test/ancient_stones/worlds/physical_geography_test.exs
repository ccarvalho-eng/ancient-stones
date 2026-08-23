defmodule AncientStones.Worlds.PhysicalGeographyTest do
  use ExUnit.Case, async: true

  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.World

  test "world changeset accepts planetary and map reference data" do
    changeset =
      World.changeset(%World{}, %{
        name: "Aldrun",
        day_length_hours: "24.6",
        mean_radius_km: 6480,
        map_projection: "Equirectangular normalized atlas"
      })

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :day_length_hours) == Decimal.new("24.6")
    assert Ecto.Changeset.get_field(changeset, :mean_radius_km) == 6480
  end

  test "continent changeset accepts bounded physical geography" do
    changeset =
      Continent.changeset(%Continent{world_id: Ecto.UUID.generate()}, %{
        name: "Thyrven",
        north_latitude: 83,
        south_latitude: 2,
        west_longitude: -65,
        east_longitude: 28,
        area_km2: 14_800_000,
        tectonic_setting: "Active continental arc"
      })

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :area_km2) == 14_800_000
  end

  test "continent changeset rejects coordinates outside geographic bounds" do
    changeset =
      Continent.changeset(%Continent{world_id: Ecto.UUID.generate()}, %{
        name: "Impossible",
        north_latitude: 91,
        west_longitude: -181
      })

    refute changeset.valid?
    assert "must be less than or equal to 90" in errors_on(changeset).north_latitude
    assert "must be greater than or equal to -180" in errors_on(changeset).west_longitude
  end

  test "province and hold changesets accept separated geographic attributes" do
    attrs = %{
      name: "Frostgard",
      climate_zone: "subarctic",
      moisture_regime: "humid west; dry rain shadow east",
      elevation_profile: "coastal lowlands beneath a glaciated mountain crown",
      geology: "metamorphic shield and young granitic intrusions",
      watershed: "upper Sael and Gullvatn basins"
    }

    province = Province.changeset(%Province{continent_id: Ecto.UUID.generate()}, attrs)
    hold = Hold.changeset(%Hold{province_id: Ecto.UUID.generate()}, attrs)

    assert province.valid?
    assert hold.valid?
    assert Ecto.Changeset.get_field(province, :climate_zone) == "subarctic"
    assert Ecto.Changeset.get_field(hold, :geology) =~ "metamorphic"
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        options
        |> Keyword.get(String.to_existing_atom(key), key)
        |> to_string()
      end)
    end)
  end
end
