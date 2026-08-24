defmodule AncientStonesWeb.WorldLive.MapDashboardTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Maps
  alias AncientStones.Worlds

  test "lists only the current world's maps inside the dashboard", %{conn: conn} do
    {:ok, nirn} = Worlds.create_world(%{name: "Nirn"})
    {:ok, tamriel} = Maps.create_world_map(nirn, %{"name" => "Tamriel"})
    {:ok, mundus} = Worlds.create_world(%{name: "Mundus"})
    {:ok, oblivion} = Maps.create_world_map(mundus, %{"name" => "Oblivion"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{nirn}/dashboard?section=maps")

    assert has_element?(view, "#world-map-library")
    assert has_element?(view, "#world-map-#{tamriel.id}")
    refute has_element?(view, "#world-map-#{oblivion.id}")

    assert has_element?(
             view,
             "#world-map-#{tamriel.id}[href='/worlds/#{nirn.id}/dashboard?section=map&map_id=#{tamriel.id}']"
           )

    assert has_element?(
             view,
             "#map-library-new[href='/worlds/#{nirn.id}/dashboard?section=map&new_map=true']"
           )
  end

  test "renders the map editor inside the world dashboard", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=map")

    assert has_element?(view, "#map-dashboard.stone-map-dashboard")
    refute has_element?(view, "#dashboard-search-form")
    refute has_element?(view, "#dashboard-search-form-mobile")
    assert has_element?(view, "[data-map-editor][phx-hook='InkMap']")
    assert has_element?(view, "[data-map-editor][data-map-revision='1']")
    refute has_element?(view, "#map-manager")
    refute has_element?(view, "#world-map-list")
    assert has_element?(view, "#map-new")
    assert has_element?(view, "details#map-tools-panel[open]")
    assert has_element?(view, "#map-symbols-panel #map-open-icon-library")
    assert has_element?(view, "#map-symbols-panel #map-icon-credit")
    assert has_element?(view, "dialog#map-icon-dialog:not([open])")
    assert has_element?(view, "#map-clear-icon-filters[data-map-action='clear-icon-filters']")
    refute has_element?(view, "#map-coordinates-properties")
    assert has_element?(view, "details#map-geography-properties:not([open])")
    assert has_element?(view, "details#map-object-properties[open]")
    assert has_element?(view, "details#map-layer-properties:not([open])")
    assert has_element?(view, "#map-layer-list[data-map-layer-list][phx-update='ignore']")
    assert has_element?(view, "template#map-layer-row-template")
    assert has_element?(view, "#map-add-layer[data-map-action='add-layer']")
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

    assert has_element?(
             view,
             "#map-delete-selection.stone-button[title='Delete selected object']"
           )

    assert has_element?(view, "#map-icon-credit a[href='https://game-icons.net']")
    assert has_element?(view, "#map-zoom[min='5'][max='400']")
    assert has_element?(view, "#map-canvas-workspace.stone-panel > #map-zoom-controls")
    assert has_element?(view, "#map-canvas-scroller.stone-map-workspace")
    assert has_element?(view, "#ink-map-stage.stone-map-stage")
    assert has_element?(view, "#map-zoom-in")
    assert has_element?(view, "#map-zoom-out")
    assert has_element?(view, "#map-fullscreen[data-map-action='fullscreen']")
    assert has_element?(view, "#map-toggle-snap[data-map-action='toggle-snap']")
    assert has_element?(view, "#map-toggle-guides[data-map-action='toggle-guides']")
    assert has_element?(view, "#map-zoom-fit[data-map-action='zoom-fit']")
    assert has_element?(view, "#map-center-guide-vertical[data-map-center-guide]")
    assert has_element?(view, "#map-center-guide-horizontal[data-map-center-guide]")
    refute has_element?(view, "#map-coordinate-readout")
    assert has_element?(view, "#map-object-x[data-map-property='x']")
    assert has_element?(view, "#map-object-opacity[data-map-property='opacity']")
    assert has_element?(view, "#map-selected-layer[data-map-selected-layer]")
    assert has_element?(view, "#map-copy-layer[data-map-copy-layer]")
    assert has_element?(view, "#map-group-selection[data-map-action='group-selection']")
    assert has_element?(view, "#map-ungroup-selection[data-map-action='ungroup-selection']")
    assert has_element?(view, "#map-object-lock[data-map-action='toggle-lock']")
    assert has_element?(view, "#map-center-object[data-map-action='center-object']")
    assert has_element?(view, "#map-bring-forward[data-map-action='bring-forward']")
    assert has_element?(view, "#map-entity-link[data-map-entity-link]")

    assert has_element?(
             view,
             "#map-entity-link option[value='continent:#{continent.id}']"
           )

    assert has_element?(view, "#map-save.stone-button[title='Map saved'][aria-label='Map saved']")
    assert has_element?(view, "#map-save [data-map-save-icon='saved']:not(.hidden)")
    assert has_element?(view, "#map-save [data-map-save-icon='warning'].hidden")
    assert has_element?(view, "#map-save [data-map-save-icon='saving'].hidden")
    assert has_element?(view, "#map-save-state[data-map-save-state][data-state='saved']")
    assert has_element?(view, "#map-export[data-map-action='export']")

    assert has_element?(
             view,
             "#map-export-background[data-map-export-background][type='color']"
           )
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

    initial_revision = map_document.lock_version

    view
    |> element("[data-map-editor]")
    |> render_hook("save_map", %{
      "document" => document,
      "width" => 1600,
      "height" => 1000
    })

    saved_map = Maps.get_world_map(world, map_document.id)
    assert saved_map.document == document
    assert saved_map.lock_version == initial_revision + 1

    assert [%{kind: "mountain", x: 320.5, y: 210.25}, %{object_type: "IText"}] =
             Maps.list_world_map_items(world)
  end

  test "rejects an autosave from a stale editor session", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map_document} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, first_view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=map&map_id=#{map_document.id}")

    {:ok, second_view, _html} =
      live(recycle(conn), ~p"/worlds/#{world}/dashboard?section=map&map_id=#{map_document.id}")

    first_document = %{"objects" => [], "mapBackground" => "#f2ead3"}
    stale_document = %{"objects" => [], "mapBackground" => "#111827"}

    first_view
    |> element("[data-map-editor]")
    |> render_hook("save_map", %{
      "document" => first_document,
      "width" => 1600,
      "height" => 1000
    })

    second_view
    |> element("[data-map-editor]")
    |> render_hook("save_map", %{
      "document" => stale_document,
      "width" => 1600,
      "height" => 1000
    })

    assert Maps.get_world_map(world, map_document.id).document == first_document
  end

  test "uploads a local reference image and pushes it to the editor", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map_document} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=map&map_id=#{map_document.id}")

    view |> element("#map-add-reference") |> render_click()
    assert has_element?(view, "#map-reference-dialog")
    assert has_element?(view, "#map-reference-upload-form")

    content =
      Base.decode64!(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
      )

    upload =
      file_input(view, "#map-reference-upload-form", :map_reference, [
        %{
          last_modified: 1_710_000_000_000,
          name: "reference.png",
          content: content,
          size: byte_size(content),
          type: "image/png"
        }
      ])

    render_upload(upload, "reference.png")

    view
    |> form("#map-reference-upload-form", reference: %{"opacity" => "40"})
    |> render_submit()

    assert_push_event(view, "map_reference_uploaded", %{url: url, opacity: 0.4})
    assert url =~ ~r{\A/uploads/map-references/[0-9a-f-]+\.png\z}
    refute has_element?(view, "#map-reference-dialog")

    stored = Application.app_dir(:ancient_stones, "priv/static#{url}")
    on_exit(fn -> File.rm(stored) end)
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

    redirect =
      view
      |> form("#map-create-form",
        map: %{"name" => "Tamriel", "kind" => "region", "parent_map_id" => ""}
      )
      |> render_submit()

    [map] = Maps.list_world_maps(world)
    path = ~p"/worlds/#{world}/dashboard?section=map&map_id=#{map.id}"
    assert {:ok, view, _html} = follow_redirect(redirect, conn, path)

    assert has_element?(view, "#ink-map-editor-#{map.id}[phx-hook='InkMap']")
    refute has_element?(view, "#world-map-list")
    assert has_element?(view, "#map-properties")
    assert has_element?(view, "details#map-properties:not([open])")
    assert has_element?(view, "#map-edit-form")
    assert has_element?(view, "#map-delete.stone-button")
    assert has_element?(view, "#map_edit_width[min='640'][max='8192'][step='20']")
    assert has_element?(view, "#map_edit_height[min='480'][max='8192'][step='20']")

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

  test "deletes a map directly from the world map library", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=maps")

    assert has_element?(
             view,
             "#world-map-delete-#{map.id}.stone-button[data-confirm]"
           )

    redirect =
      view
      |> element("#world-map-delete-#{map.id}")
      |> render_click()

    path = ~p"/worlds/#{world}/dashboard?section=maps"
    assert {:ok, view, _html} = follow_redirect(redirect, conn, path)

    refute Maps.get_world_map(world, map.id)
    refute has_element?(view, "#world-map-card-#{map.id}")
  end

  test "edits a map name directly from the world map library", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}/dashboard?section=maps")

    view
    |> element("#world-map-name-edit-#{map.id}")
    |> render_click()

    assert has_element?(view, "#world-map-name-form-#{map.id}")

    view
    |> form("#world-map-name-form-#{map.id}", map_name: %{"name" => "Skyrim"})
    |> render_submit()

    assert Maps.get_world_map(world, map.id).name == "Skyrim"
    assert has_element?(view, "#world-map-name-#{map.id}", "Skyrim")
    refute has_element?(view, "#world-map-name-form-#{map.id}")
  end

  test "deletes the selected map and remounts the map library", %{conn: conn} do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, map} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, view, _html} =
      live(conn, ~p"/worlds/#{world}/dashboard?section=map&map_id=#{map.id}")

    redirect =
      view
      |> element("#map-delete")
      |> render_click()

    path = ~p"/worlds/#{world}/dashboard?section=maps"
    assert {:ok, view, _html} = follow_redirect(redirect, conn, path)

    refute Maps.get_world_map(world, map.id)
    assert has_element?(view, "#world-map-list")
    refute has_element?(view, "#ink-map-editor-#{map.id}")
  end
end
