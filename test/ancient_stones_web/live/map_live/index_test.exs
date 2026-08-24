defmodule AncientStonesWeb.MapLive.IndexTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Maps
  alias AncientStones.Worlds

  test "lists maps and opens the selected map editor", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map} = Maps.create_world_map(world, %{"name" => "Tamriel", "kind" => "region"})

    {:ok, view, _html} = live(conn, ~p"/maps")

    assert has_element?(view, "#maps-index")

    assert has_element?(
             view,
             "#map-open-#{map.id}[href='/worlds/#{world.id}/dashboard?section=map&map_id=#{map.id}']"
           )

    assert has_element?(
             view,
             "#map-delete-#{map.id}.stone-button[data-confirm]"
           )
  end

  test "shows an empty state", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/maps")

    assert has_element?(view, "#maps-empty")
  end

  test "shows all maps by default and filters when a world is selected", %{conn: conn} do
    {:ok, nirn} = Worlds.create_world(%{name: "Nirn"})
    {:ok, tamriel} = Maps.create_world_map(nirn, %{"name" => "Tamriel"})
    {:ok, mundus} = Worlds.create_world(%{name: "Mundus"})
    {:ok, oblivion} = Maps.create_world_map(mundus, %{"name" => "Oblivion"})

    {:ok, view, _html} = live(conn, ~p"/maps")

    assert has_element?(view, "#maps-#{tamriel.id}")
    assert has_element?(view, "#maps-#{oblivion.id}")
    assert has_element?(view, "#world_filter_world_id option[selected][value='']")

    view
    |> form("#map-world-filter", world_filter: %{world_id: nirn.id})
    |> render_change()

    assert_patch(view, ~p"/maps?world_id=#{nirn.id}")
    assert has_element?(view, "#maps-#{tamriel.id}")
    refute has_element?(view, "#maps-#{oblivion.id}")

    refute has_element?(view, "#maps-breadcrumb")
    assert has_element?(view, "#maps-world-context", nirn.name)
    assert has_element?(view, "#maps-clear-world-filter[href='/maps']")
  end

  test "deletes a map from the library and refreshes the count", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, view, _html} = live(conn, ~p"/maps")

    view
    |> element("#map-delete-#{map.id}")
    |> render_click()

    refute Maps.get_world_map(world, map.id)
    refute has_element?(view, "#maps-#{map.id}")
    assert has_element?(view, "#maps-navigation strong", "0")
  end

  test "edits a map name from the library", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, view, _html} = live(conn, ~p"/maps")

    view
    |> element("#map-name-edit-#{map.id}")
    |> render_click()

    assert has_element?(view, "#map-name-form-#{map.id}")

    view
    |> form("#map-name-form-#{map.id}", map_name: %{"name" => "Skyrim"})
    |> render_submit()

    assert Maps.get_world_map(world, map.id).name == "Skyrim"
    assert has_element?(view, "#map-name-#{map.id}", "Skyrim")
    refute has_element?(view, "#map-name-form-#{map.id}")
  end
end
