defmodule AncientStonesWeb.WorldLive.IndexTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Galaxies
  alias AncientStones.Galaxies.Galaxy
  alias AncientStones.Maps
  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.Moon
  alias AncientStones.Worlds.Spell
  alias AncientStones.Worlds.World

  test "renders the world dashboard", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#worlds-dashboard.stone-theme-system")
    assert has_element?(view, "#worlds-dashboard[phx-hook='AncientStonesTheme']")
    assert has_element?(view, "#dashboard-galaxy-form")
    assert has_element?(view, "#dashboard-world-form")
    assert has_element?(view, "#theme-switcher")
    assert has_element?(view, "button[data-ancient-stones-theme='dark']")
    assert has_element?(view, "#world-library-tabs")
    assert has_element?(view, "#galaxies-tab.stone-selected")
    assert has_element?(view, "#unassigned-worlds-panel.hidden")

    assert has_element?(
             view,
             "#dashboard-world-form [title='Planet tilt in degrees. Earth is about 23.5 degrees.']"
           )

    assert has_element?(
             view,
             "#world-advanced-physical-data [title=\"Planetary mass relative to Earth; 1 equals Earth's mass.\"]"
           )

    assert has_element?(
             view,
             "#world-advanced-physical-data [title='Primary star effective surface temperature in kelvins; the Sun is about 5,772 K.']"
           )

    assert has_element?(
             view,
             "#world-advanced-physical-data > div[class*='sm:grid-cols-2']"
           )
  end

  test "switches the world library tabs", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> element("#unassigned-worlds-tab")
    |> render_click()

    assert has_element?(view, "#unassigned-worlds-tab.stone-selected")
    assert has_element?(view, "#galaxies-panel.hidden")
    refute has_element?(view, "#unassigned-worlds-panel.hidden")
  end

  test "shows top-level inventory in the workspace sidebar", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    {:ok, _map} = Maps.create_world_map(world, %{"name" => "Outer map", "kind" => "world"})

    {:ok, view, _html} = live(conn, ~p"/worlds")

    assert has_element?(view, ".stone-sidebar", "Worlds")
    assert has_element?(view, ".stone-sidebar", "Galaxies")
    assert has_element?(view, "#maps-navigation strong", "1")
    refute has_element?(view, ".stone-sidebar", "Holds")
    refute has_element?(view, ".stone-sidebar", "Location Types")
    refute has_element?(view, ".stone-sidebar", "Locations")
  end

  test "shows geography counts scoped to each world", %{conn: conn} do
    {:ok, _skyrim} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    {:ok, _blank} = Worlds.create_world_from_template(:blank, %{name: "Blank Realm"})

    {:ok, view, _html} = live(conn, ~p"/worlds")

    assert has_element?(view, "#galaxies", "Northern Realm")
    assert has_element?(view, "#galaxies", "94 holds")
    assert has_element?(view, "#worlds", "Blank Realm")
    assert has_element?(view, "#worlds", "0 holds")
  end

  test "switches theme from the dashboard toggle", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> element("button[aria-label='Use dark theme']")
    |> render_click()

    assert has_element?(view, ".stone-theme-dark")
  end

  test "creates a blank world", %{conn: conn} do
    {:ok, galaxy} = Galaxies.create_galaxy(%{name: "Mundus"})
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> form("#dashboard-world-form",
      world: %{
        name: "Eldoria",
        description: "A realm of ancient stone",
        template: "blank",
        galaxy_id: galaxy.id
      }
    )
    |> render_submit()

    world = Repo.get_by!(World, name: "Eldoria")
    world = Repo.preload(world, :galaxy)

    assert world.galaxy.name == "Mundus"
  end

  test "creates a blank world with a nested moon", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> element("#dashboard-world-form-add-moon")
    |> render_click()

    assert has_element?(view, "#dashboard-world-form-moon-0")
    assert has_element?(view, "#dashboard-world-form-moon-0 h5", "Moon 1")

    view
    |> form("#dashboard-world-form",
      world: %{
        name: "Pelagos",
        template: "blank",
        mass_earths: "1",
        mean_radius_km: "6371",
        moons: %{
          "0" => %{
            name: "Selene",
            semi_major_axis_km: "384400",
            mean_radius_km: "1737",
            mass_lunar: "1"
          }
        }
      }
    )
    |> render_submit()

    world = Repo.get_by!(World, name: "Pelagos")

    assert Repo.get_by!(Moon, world_id: world.id, name: "Selene")
  end

  test "creates a galaxy", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> form("#dashboard-galaxy-form",
      galaxy: %{
        name: "Mundus",
        description: "The mortal plane"
      }
    )
    |> render_submit()

    assert Repo.get_by!(Galaxy, name: "Mundus")
    assert has_element?(view, "#galaxies", "Mundus")
  end

  test "selects a world and updates all its attributes with the world form", %{conn: conn} do
    {:ok, original_galaxy} = Galaxies.create_galaxy(%{name: "Old Galaxy"})
    {:ok, new_galaxy} = Galaxies.create_galaxy(%{name: "New Galaxy"})

    {:ok, world} =
      Worlds.create_world(
        %{
          name: "Eldoria",
          description: "An old world",
          primary_star_name: "Old Sun",
          orbital_period_days: 300,
          axial_tilt_degrees: "12.5",
          day_length_hours: "20.5",
          mean_radius_km: 6_000,
          mass_earths: "1.1",
          surface_gravity_m_s2: "10.2",
          orbital_distance_au: "0.98",
          orbital_eccentricity: "0.02",
          atmospheric_pressure_atm: "1.05",
          bond_albedo: "0.31",
          ocean_fraction: "0.63",
          star_mass_solar: "1.03",
          star_luminosity_solar: "1.08",
          star_temperature_k: 5_900,
          map_projection: "Mercator"
        },
        galaxy: original_galaxy
      )

    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> element("#select-world-#{world.id}")
    |> render_click()

    assert has_element?(view, "#dashboard-world-form[phx-submit='update_world']")
    assert has_element?(view, "#world_name[value='Eldoria']")
    assert has_element?(view, "#world_description", "An old world")
    assert has_element?(view, "#world_primary_star_name[value='Old Sun']")
    assert has_element?(view, "#world_orbital_period_days[value='300']")
    assert has_element?(view, "#world_axial_tilt_degrees[value='12.5']")
    assert has_element?(view, "#world_day_length_hours[value='20.5']")
    assert has_element?(view, "#world_mean_radius_km[value='6000']")
    assert has_element?(view, "#world_map_projection[value='Mercator']")
    assert has_element?(view, "#world-advanced-physical-data:not([open])")

    assert has_element?(
             view,
             "#world-advanced-physical-data #world_star_mass_solar[value^='1.03']"
           )

    assert has_element?(
             view,
             "#world-advanced-physical-data #world_star_luminosity_solar[value^='1.08']"
           )

    assert has_element?(
             view,
             "#world-advanced-physical-data #world_star_temperature_k[value='5900']"
           )

    assert has_element?(
             view,
             "#world_galaxy_id option[selected][value='#{original_galaxy.id}']"
           )

    assert has_element?(view, "#dashboard-world-form button", "Save")
    assert has_element?(view, "#cancel-world-edit", "Cancel")

    view
    |> element("#cancel-world-edit")
    |> render_click()

    assert has_element?(view, "#dashboard-world-form[phx-submit='create_world']")
    refute has_element?(view, "#cancel-world-edit")

    view
    |> element("#select-world-#{world.id}")
    |> render_click()

    view
    |> form("#dashboard-world-form",
      world: %{
        name: "Eldoria Prime",
        description: "A renewed world",
        primary_star_name: "New Sun",
        orbital_period_days: "420",
        axial_tilt_degrees: "24.75",
        day_length_hours: "28.5",
        mean_radius_km: "7123",
        mass_earths: "1.2",
        surface_gravity_m_s2: "10.5",
        orbital_distance_au: "1.1",
        orbital_eccentricity: "0.03",
        atmospheric_pressure_atm: "1.08",
        bond_albedo: "0.29",
        ocean_fraction: "0.66",
        star_mass_solar: "1.04",
        star_luminosity_solar: "1.12",
        star_temperature_k: "6010",
        map_projection: "Equal Earth",
        galaxy_id: new_galaxy.id
      }
    )
    |> render_submit()

    updated_world = Repo.get!(World, world.id)

    assert updated_world.name == "Eldoria Prime"
    assert updated_world.description == "A renewed world"
    assert updated_world.primary_star_name == "New Sun"
    assert updated_world.orbital_period_days == 420
    assert Decimal.equal?(updated_world.axial_tilt_degrees, Decimal.new("24.75"))
    assert Decimal.equal?(updated_world.day_length_hours, Decimal.new("28.5"))
    assert updated_world.mean_radius_km == 7_123
    assert Decimal.equal?(updated_world.mass_earths, Decimal.new("1.2"))
    assert Decimal.equal?(updated_world.surface_gravity_m_s2, Decimal.new("10.5"))
    assert Decimal.equal?(updated_world.orbital_distance_au, Decimal.new("1.1"))
    assert Decimal.equal?(updated_world.orbital_eccentricity, Decimal.new("0.03"))
    assert Decimal.equal?(updated_world.atmospheric_pressure_atm, Decimal.new("1.08"))
    assert Decimal.equal?(updated_world.bond_albedo, Decimal.new("0.29"))
    assert Decimal.equal?(updated_world.ocean_fraction, Decimal.new("0.66"))
    assert Decimal.equal?(updated_world.star_mass_solar, Decimal.new("1.04"))
    assert Decimal.equal?(updated_world.star_luminosity_solar, Decimal.new("1.12"))
    assert updated_world.star_temperature_k == 6_010
    assert updated_world.map_projection == "Equal Earth"
    assert updated_world.galaxy_id == new_galaxy.id
    assert has_element?(view, "#galaxies", "Eldoria Prime")
    assert has_element?(view, "#dashboard-world-form[phx-submit='create_world']")
  end

  test "edits existing moons and stages moon additions and removals with the world", %{conn: conn} do
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

    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> element("#select-world-#{world.id}")
    |> render_click()

    assert has_element?(view, "#dashboard-world-form-moons[data-mode='edit']")
    assert has_element?(view, "#world_moons_0_id[value='#{selene.id}']")
    assert has_element?(view, "#world_moons_0_name[value='Selene']")
    assert has_element?(view, "#world_moons_1_name[value='Thalassa']")
    assert has_element?(view, "#dashboard-world-form-moon-0 h5", "Selene")
    assert has_element?(view, "#dashboard-world-form-moon-1 h5", "Thalassa")

    view
    |> form("#dashboard-world-form",
      world: %{
        name: "Pelagos Draft",
        mass_earths: "1",
        mean_radius_km: "6371",
        moons: %{
          "0" => %{
            id: selene.id,
            name: "Selene Major",
            orbital_period_days: "27.3",
            semi_major_axis_km: "384400",
            mean_radius_km: "1737",
            mass_lunar: "1"
          },
          "1" => %{
            id: thalassa.id,
            name: "Thalassa",
            orbital_period_days: "12",
            semi_major_axis_km: "180000",
            mean_radius_km: "500",
            mass_lunar: "0.1"
          }
        }
      }
    )
    |> render_change()

    assert has_element?(view, "#dashboard-world-form-moon-0 h5", "Selene Major")

    view
    |> element("#dashboard-world-form-remove-moon-1")
    |> render_click()

    assert Repo.get(Moon, thalassa.id)
    refute has_element?(view, "#dashboard-world-form-moon-1")

    view
    |> element("#dashboard-world-form-add-moon")
    |> render_click()

    assert has_element?(view, "#dashboard-world-form-moon-1")
    assert has_element?(view, "#world_name[value='Pelagos Draft']")

    view
    |> form("#dashboard-world-form",
      world: %{
        name: "Pelagos Prime",
        mass_earths: "1",
        mean_radius_km: "6371",
        moons: %{
          "0" => %{
            id: selene.id,
            name: "Selene Major",
            orbital_period_days: "27.3",
            semi_major_axis_km: "384400",
            mean_radius_km: "1737",
            mass_lunar: "1"
          },
          "1" => %{
            id: "",
            name: "Nereid",
            orbital_period_days: "",
            semi_major_axis_km: "250000",
            mean_radius_km: "800",
            mass_lunar: "0.2"
          }
        }
      }
    )
    |> render_submit()

    assert Repo.get!(World, world.id).name == "Pelagos Prime"
    assert Repo.get!(Moon, selene.id).name == "Selene Major"
    refute Repo.get(Moon, thalassa.id)
    assert Repo.get_by!(Moon, world_id: world.id, name: "Nereid")
  end

  test "selects a galaxy and updates all its attributes with the galaxy form", %{conn: conn} do
    {:ok, galaxy} =
      Galaxies.create_galaxy(%{name: "Mundus", description: "The mortal plane"})

    {:ok, world} = Worlds.create_world(%{name: "Nirn"}, galaxy: galaxy)
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> element("#select-galaxy-#{galaxy.id}")
    |> render_click()

    assert has_element?(view, "#dashboard-galaxy-form[phx-submit='update_galaxy']")
    assert has_element?(view, "#galaxy_name[value='Mundus']")
    assert has_element?(view, "#galaxy_description", "The mortal plane")
    assert has_element?(view, "#dashboard-galaxy-form button", "Save")
    assert has_element?(view, "#cancel-galaxy-edit", "Cancel")

    view
    |> element("#cancel-galaxy-edit")
    |> render_click()

    assert has_element?(view, "#dashboard-galaxy-form[phx-submit='create_galaxy']")
    refute has_element?(view, "#cancel-galaxy-edit")

    view
    |> element("#select-galaxy-#{galaxy.id}")
    |> render_click()

    view
    |> form("#dashboard-galaxy-form",
      galaxy: %{name: "Mundus Prime", description: "The renewed mortal plane"}
    )
    |> render_submit()

    updated_galaxy = Repo.get!(Galaxy, world.galaxy_id)

    assert updated_galaxy.name == "Mundus Prime"
    assert updated_galaxy.description == "The renewed mortal plane"
    assert has_element?(view, "#galaxies", "Mundus Prime")
    assert has_element?(view, "#dashboard-galaxy-form[phx-submit='create_galaxy']")
  end

  test "nests worlds under their galaxy and lists only unassigned worlds separately", %{
    conn: conn
  } do
    {:ok, galaxy} = Galaxies.create_galaxy(%{name: "Mundus"})
    {:ok, _assigned_world} = Worlds.create_world(%{name: "Nirn"}, galaxy: galaxy)
    {:ok, _unassigned_world} = Worlds.create_world(%{name: "Orphan Realm"})

    {:ok, view, _html} = live(conn, ~p"/worlds")

    assert has_element?(view, "#galaxies", "Mundus")
    assert has_element?(view, "#galaxies", "Nirn")
    assert has_element?(view, "#galaxies .stone-child-record", "Nirn")
    assert has_element?(view, "#worlds", "Orphan Realm")
    refute has_element?(view, "#worlds", "Nirn")
  end

  test "deletes a world", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Eldoria"})
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> element("button[aria-label='Delete Eldoria']")
    |> render_click()

    refute Repo.get(World, world.id)
  end

  test "deletes a templated world with geography", %{conn: conn} do
    {:ok, world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> element("button[aria-label='Delete Northern Realm']")
    |> render_click()

    refute Repo.get(World, world.id)
  end

  test "fills world fields from the selected template", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> form("#dashboard-world-form", world: %{template: "skyrim"})
    |> render_change()

    assert has_element?(view, "#world_name[value='Nirn']")

    assert has_element?(
             view,
             "#world_galaxy_id option[selected][value='__template_galaxy__']",
             "Mundus"
           )

    refute has_element?(view, "#dashboard-world-form", "Template galaxy:")
    assert render(view) =~ "The mortal world where myth, empire, wilderness, and old magic shape"
  end

  test "selects the template galaxy when it already exists", %{conn: conn} do
    {:ok, galaxy} = Galaxies.create_galaxy(%{name: "Mundus"})
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> form("#dashboard-world-form", world: %{template: "skyrim"})
    |> render_change()

    assert has_element?(view, "#world_galaxy_id option[selected][value='#{galaxy.id}']")
  end

  test "creates a world from the Skyrim template", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds")

    view
    |> form("#dashboard-world-form",
      world: %{
        name: "Northern Realm",
        description: "",
        template: "skyrim"
      }
    )
    |> render_submit()

    world =
      World
      |> Repo.get_by!(name: "Northern Realm")
      |> Repo.preload([:galaxy, continents: [provinces: [:holds]]])

    continent = Enum.find(world.continents, &(&1.name == "Tamriel"))
    province = Enum.find(continent.provinces, &(&1.name == "Skyrim"))

    assert world.galaxy.name == "Mundus"
    assert continent.name == "Tamriel"
    assert province.name == "Skyrim"
    assert length(province.holds) == 9
    assert Repo.get_by!(Spell, world_id: world.id, name: "Flames").school == "Destruction"
    assert Repo.get_by!(Spell, world_id: world.id, name: "Healing").school == "Restoration"
  end
end
