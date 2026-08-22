defmodule AncientStonesWeb.WorldLive.MapDashboardTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Maps
  alias AncientStones.Worlds

  test "renders the map editor inside the world dashboard", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=map")

    assert has_element?(view, "#map-dashboard")
    assert has_element?(view, "[data-map-editor][phx-hook='InkMap']")
    refute has_element?(view, "#map-manager")
    refute has_element?(view, "#world-map-list")
    assert has_element?(view, "#map-new")
    assert has_element?(view, "details#map-tools-panel[open]")
    assert has_element?(view, "details#map-symbols-panel:not([open])")
    assert has_element?(view, "details#map-coordinates-properties:not([open])")
    assert has_element?(view, "details#map-geography-properties:not([open])")
    assert has_element?(view, "details#map-object-properties:not([open])")
    assert has_element?(view, "details#map-layer-properties:not([open])")
    assert has_element?(view, "details#map-controls-properties:not([open])")
    assert has_element?(view, "#map-select-tool")
    assert has_element?(view, "#map-ink-tool")
    assert has_element?(view, "#map-pan-tool[data-map-tool='pan']")
    assert has_element?(view, "#map-select-tool[aria-label='Select']")
    assert has_element?(view, "#map-ink-tool[aria-label='Ink']")
    assert has_element?(view, "#map-pan-tool[aria-label='Pan']")
    assert has_element?(view, "#map-landmass-tool[data-map-tool='landmass']")
    assert has_element?(view, "#map-land-color[data-map-land-color]")
    assert has_element?(view, "#map-water-color[data-map-water-color]")
    assert has_element?(view, "#map-coast-roughness[min='0'][max='5']")
    assert has_element?(view, "#map-texture-forest[data-map-tool='texture-forest']")
    assert has_element?(view, "#map-texture-mountains[data-map-tool='texture-mountains']")
    assert has_element?(view, "#map-texture-road[data-map-tool='texture-road']")
    assert has_element?(view, "#map-brush-density[min='1'][max='5']")
    assert has_element?(view, "#map-icon-search[data-map-icon-search]")
    assert has_element?(view, "#map-icon-category[data-map-icon-category]")
    assert has_element?(view, "#map-icon-category option[value='terrain']")
    assert has_element?(view, "#map-icon-category option[value='nordic']")
    assert has_element?(view, "#map-icon-category option[value='medieval']")
    assert has_element?(view, "#map-icon-grid[data-map-icon-grid]")
    assert has_element?(view, "#map-add-label[data-map-action='add-text']")
    assert has_element?(view, "#map-duplicate-selection[data-map-action='duplicate']")
    assert has_element?(view, "#map-icon-credit a[href='https://game-icons.net']")
    assert has_element?(view, "#map-zoom[min='5'][max='400']")
    assert has_element?(view, "#map-canvas-workspace > #map-zoom-controls")
    assert has_element?(view, "#map-canvas-scroller")
    assert has_element?(view, "#map-zoom-in")
    assert has_element?(view, "#map-zoom-out")
    assert has_element?(view, "#map-fullscreen[data-map-action='fullscreen']")
    assert has_element?(view, "#map-toggle-snap[data-map-action='toggle-snap']")
    assert has_element?(view, "#map-toggle-guides[data-map-action='toggle-guides']")
    assert has_element?(view, "#map-zoom-fit[data-map-action='zoom-fit']")
    assert has_element?(view, "#map-center-guide-vertical[data-map-center-guide]")
    assert has_element?(view, "#map-center-guide-horizontal[data-map-center-guide]")
    assert has_element?(view, "#map-coordinate-readout")
    assert has_element?(view, "#map-object-x[data-map-property='x']")
    assert has_element?(view, "#map-object-opacity[data-map-property='opacity']")
    assert has_element?(view, "#map-object-lock[data-map-action='toggle-lock']")
    assert has_element?(view, "#map-center-object[data-map-action='center-object']")
    assert has_element?(view, "#map-bring-forward[data-map-action='bring-forward']")
    assert has_element?(view, "#map-entity-link[data-map-entity-link]")

    assert has_element?(
             view,
             "#map-entity-link option[value='continent:#{continent.id}']"
           )

    assert has_element?(view, "#map-save")
  end

  test "persists a valid canvas document for the current world", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map_document} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=map&map_id=#{map_document.id}")

    label_item_id = Ecto.UUID.generate()

    document = %{
      "version" => "7.4.0",
      "objects" => [
        %{
          "type" => "Path",
          "path" => [],
          "mapKind" => "mountain",
          "mapLayer" => "terrain",
          "mapItemId" => Ecto.UUID.generate(),
          "mapX" => 320.5,
          "mapY" => 210.25
        },
        %{
          "type" => "IText",
          "text" => "Whiterun",
          "mapLayer" => "labels",
          "mapItemId" => label_item_id
        }
      ]
    }

    view
    |> element("[data-map-editor]")
    |> render_hook("save_map", %{
      "document" => document,
      "width" => 1600,
      "height" => 1000
    })

    assert Maps.get_world_map(world, map_document.id).document == document

    assert [%{kind: "mountain", x: 320.5, y: 210.25}, %{object_type: "IText"}] =
             Maps.list_world_map_items(world)
  end

  test "does not fall back to another map for an invalid map id", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, first_map} = Maps.create_world_map(world, %{"name" => "Tamriel"})
    {:ok, second_map} = Maps.create_world_map(world, %{"name" => "Whiterun"})

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=map&map_id=#{Ecto.UUID.generate()}")

    refute has_element?(view, "#map-properties")

    view
    |> element("[data-map-editor]")
    |> render_hook("save_map", %{
      "document" => %{"objects" => []},
      "width" => 1200,
      "height" => 800
    })

    assert Maps.get_world_map(world, first_map.id).width == 1600
    assert Maps.get_world_map(world, second_map.id).width == 1600
  end

  test "shows map metadata validation failures outside the ignored editor", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, first_map} = Maps.create_world_map(world, %{"name" => "Tamriel"})
    {:ok, second_map} = Maps.create_world_map(world, %{"name" => "Whiterun"})

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=map&map_id=#{second_map.id}")

    view
    |> form("#map-edit-form", map_edit: %{"name" => first_map.name, "kind" => "world"})
    |> render_submit()

    assert has_element?(view, "#flash-error")
    assert Maps.get_world_map(world, second_map.id).name == "Whiterun"
  end

  test "creates and updates a selected map from the dashboard", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=map")

    view |> element("#map-new") |> render_click()
    assert has_element?(view, "#map-create-dialog")

    view
    |> form("#map-create-form",
      map: %{"name" => "Tamriel", "kind" => "region", "parent_map_id" => ""}
    )
    |> render_submit()

    [map] = Maps.list_world_maps(world)
    assert_patch(view, ~p"/worlds/#{world}/dashboard?section=map&map_id=#{map.id}")
    refute has_element?(view, "#world-map-list")
    assert has_element?(view, "#map-properties")
    assert has_element?(view, "details#map-properties:not([open])")
    assert has_element?(view, "#map-edit-form")
    assert has_element?(view, "#map_edit_width[min='640'][max='8192']")
    assert has_element?(view, "#map_edit_height[min='480'][max='8192']")

    view
    |> form("#map-edit-form",
      map_edit: %{
        "name" => "Inner Tamriel",
        "kind" => "region",
        "width" => "3200",
        "height" => "1800"
      }
    )
    |> render_submit()

    updated_map = Maps.get_world_map(world, map.id)
    assert updated_map.name == "Inner Tamriel"
    assert updated_map.width == 3200
    assert updated_map.height == 1800
  end
end
