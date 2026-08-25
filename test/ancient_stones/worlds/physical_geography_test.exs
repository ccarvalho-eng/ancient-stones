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
        mass_earths: "1.04",
        surface_gravity_m_s2: "9.91",
        orbital_distance_au: "1.01",
        orbital_eccentricity: "0.018",
        atmospheric_pressure_atm: "1.03",
        bond_albedo: "0.31",
        ocean_fraction: "0.67",
        star_mass_solar: "1.01",
        star_luminosity_solar: "1.02",
        star_temperature_k: 5_810,
        map_projection: "Equirectangular normalized atlas"
      })

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :day_length_hours) == Decimal.new("24.6")
    assert Ecto.Changeset.get_field(changeset, :mean_radius_km) == 6480
    assert Ecto.Changeset.get_field(changeset, :mass_earths) == Decimal.new("1.04")
    assert Ecto.Changeset.get_field(changeset, :ocean_fraction) == Decimal.new("0.67")
  end

  test "world changeset rejects impossible physical fractions and eccentricity" do
    changeset =
      World.changeset(%World{}, %{
        name: "Impossible",
        orbital_eccentricity: "1.2",
        bond_albedo: "-0.1",
        ocean_fraction: "1.1"
      })

    refute changeset.valid?
    assert "must be less than 1" in errors_on(changeset).orbital_eccentricity
    assert "must be greater than or equal to 0" in errors_on(changeset).bond_albedo
    assert "must be less than or equal to 1" in errors_on(changeset).ocean_fraction
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
      watershed: "upper Sael and Gullvatn basins",
      area_km2: 120_000,
      latitude: "63.4",
      longitude: "4.2",
      mean_winter_temperature_c: "-8.5",
      mean_summer_temperature_c: "13.5",
      annual_precipitation_mm: 780,
      frost_free_days: 112
    }

    province = Province.changeset(%Province{continent_id: Ecto.UUID.generate()}, attrs)
    hold = Hold.changeset(%Hold{province_id: Ecto.UUID.generate()}, attrs)

    assert province.valid?
    assert hold.valid?
    assert Ecto.Changeset.get_field(province, :climate_zone) == "subarctic"
    assert Ecto.Changeset.get_field(hold, :geology) =~ "metamorphic"
    assert Ecto.Changeset.get_field(province, :area_km2) == 120_000
    assert Ecto.Changeset.get_field(hold, :frost_free_days) == 112
  end

  test "province and hold changesets reject a winter mean above the summer mean" do
    attrs = %{
      name: "Impossible seasons",
      mean_winter_temperature_c: "18",
      mean_summer_temperature_c: "6"
    }

    province = Province.changeset(%Province{continent_id: Ecto.UUID.generate()}, attrs)
    hold = Hold.changeset(%Hold{province_id: Ecto.UUID.generate()}, attrs)

    refute province.valid?
    refute hold.valid?

    assert "cannot exceed the summer mean" in errors_on(province).mean_winter_temperature_c
    assert "cannot exceed the summer mean" in errors_on(hold).mean_winter_temperature_c
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
