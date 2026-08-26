defmodule AncientStonesWeb.WorldLive.NewTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds.Moon
  alias AncientStones.Worlds.World

  test "renders the new world form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds/new")

    assert has_element?(view, "#world-form")
    assert has_element?(view, "#world-form input[name='world[name]']")
    assert has_element?(view, "#world-form textarea[name='world[description]']")

    assert has_element?(
             view,
             "#world-form [title='Planet tilt in degrees. Earth is about 23.5 degrees.']"
           )

    assert has_element?(view, "#new-world-advanced-physical-data:not([open])")

    assert has_element?(
             view,
             "#new-world-advanced-physical-data #world_star_mass_solar"
           )

    assert has_element?(
             view,
             "#new-world-advanced-physical-data #world_star_luminosity_solar"
           )

    assert has_element?(view, "#new-world-advanced-physical-data #world_star_temperature_k")

    assert has_element?(
             view,
             "#new-world-advanced-physical-data [title=\"Planetary mass relative to Earth; 1 equals Earth's mass.\"]"
           )

    assert has_element?(
             view,
             "#new-world-advanced-physical-data [title='Primary star effective surface temperature in kelvins; the Sun is about 5,772 K.']"
           )

    assert has_element?(view, "#create-world-button")
  end

  test "creates a world", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds/new")

    view
    |> form("#world-form",
      world: %{
        name: "Eldoria",
        description: "A realm of ancient stone"
      }
    )
    |> render_submit()

    assert Repo.get_by(World, name: "Eldoria")
  end

  test "adds, removes, and creates nested moons", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds/new")

    view
    |> element("#world-form-add-moon")
    |> render_click()

    assert has_element?(view, "#world-form-moon-0")
    assert has_element?(view, "#world_moons_0_name")

    view
    |> element("#world-form-add-moon")
    |> render_click()

    assert has_element?(view, "#world-form-moon-1")

    view
    |> element("#world-form-remove-moon-1")
    |> render_click()

    refute has_element?(view, "#world-form-moon-1")

    view
    |> form("#world-form",
      world: %{
        name: "Pelagos",
        mass_earths: "1",
        mean_radius_km: "6371",
        moons: %{
          "0" => %{
            name: "Selene",
            semi_major_axis_km: "384400",
            mean_radius_km: "1737",
            mass_lunar: "1",
            orbital_eccentricity: "0.0549",
            inclination_degrees: "5.145"
          }
        }
      }
    )
    |> render_submit()

    world = Repo.get_by!(World, name: "Pelagos")
    moon = Repo.get_by!(Moon, world_id: world.id, name: "Selene")

    assert Decimal.compare(moon.orbital_period_days, Decimal.new("27.28")) in [:eq, :gt]
  end
end
