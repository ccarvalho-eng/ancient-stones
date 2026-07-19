defmodule AncientStonesWeb.WorldLive.NewTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds.World

  test "renders the new world form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/worlds/new")

    assert has_element?(view, "#world-form")
    assert has_element?(view, "#world-form input[name='world[name]']")
    assert has_element?(view, "#world-form textarea[name='world[description]']")
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
end
