defmodule AncientStonesWeb.WorldLive.IndexTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Galaxies
  alias AncientStones.Galaxies.Galaxy
  alias AncientStones.Repo
  alias AncientStones.Worlds
  alias AncientStones.Worlds.Spell
  alias AncientStones.Worlds.World

  test "renders the world dashboard", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#worlds-dashboard")
    assert has_element?(view, "#dashboard-galaxy-form")
    assert has_element?(view, "#dashboard-world-form")
    assert has_element?(view, "#theme-switcher")
  end

  test "shows top-level inventory in the workspace sidebar", %{conn: conn} do
    {:ok, _world} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})

    {:ok, view, _html} = live(conn, ~p"/worlds")

    assert has_element?(view, ".stone-sidebar", "Worlds")
    assert has_element?(view, ".stone-sidebar", "Galaxies")
    refute has_element?(view, ".stone-sidebar", "Holds")
    refute has_element?(view, ".stone-sidebar", "Location Types")
    refute has_element?(view, ".stone-sidebar", "Locations")
  end

  test "shows geography counts scoped to each world", %{conn: conn} do
    {:ok, _skyrim} = Worlds.create_world_from_template(:skyrim, %{name: "Northern Realm"})
    {:ok, _blank} = Worlds.create_world_from_template(:blank, %{name: "Blank Realm"})

    {:ok, view, _html} = live(conn, ~p"/worlds")

    assert has_element?(view, "#galaxies", "Northern Realm")
    assert has_element?(view, "#galaxies", "9 holds")
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

  test "nests worlds under their galaxy and lists only unassigned worlds separately", %{
    conn: conn
  } do
    {:ok, galaxy} = Galaxies.create_galaxy(%{name: "Mundus"})
    {:ok, _assigned_world} = Worlds.create_world(%{name: "Nirn"}, galaxy: galaxy)
    {:ok, _unassigned_world} = Worlds.create_world(%{name: "Orphan Realm"})

    {:ok, view, _html} = live(conn, ~p"/worlds")

    assert has_element?(view, "#galaxies", "Mundus")
    assert has_element?(view, "#galaxies", "Nirn")
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
    assert has_element?(view, "#dashboard-world-form", "Template galaxy:")
    assert has_element?(view, "#dashboard-world-form", "Mundus")
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
