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
             "#maps-#{map.id}[href='/worlds/#{world.id}/dashboard?section=map&map_id=#{map.id}']"
           )
  end

  test "shows an empty state", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/maps")

    assert has_element?(view, "#maps-empty")
  end
end
