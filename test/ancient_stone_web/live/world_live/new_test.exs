defmodule AncientStoneWeb.WorldLive.NewTest do
  use AncientStoneWeb.ConnCase, async: true
  doctest AncientStoneWeb.WorldLive.New

  import Phoenix.LiveViewTest

  alias AncientStone.Repo
  alias AncientStone.Worlds.World

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
