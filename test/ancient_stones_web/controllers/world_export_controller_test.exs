defmodule AncientStonesWeb.WorldExportControllerTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Worlds

  setup do
    {:ok, world} = Worlds.create_world(%{name: "Aldrun"})
    %{world: world}
  end

  test "downloads a world guide PDF", %{conn: conn, world: world} do
    conn = get(conn, ~p"/worlds/#{world.id}/export.pdf")

    assert response_content_type(conn, :pdf) == "application/pdf"

    assert get_resp_header(conn, "content-disposition") == [
             ~s(attachment; filename="aldrun-world-guide.pdf")
           ]

    assert response(conn, 200) =~ "%PDF-"
  end

  test "downloads a world guide EPUB", %{conn: conn, world: world} do
    conn = get(conn, ~p"/worlds/#{world.id}/export.epub")

    assert get_resp_header(conn, "content-type") == ["application/epub+zip"]

    assert get_resp_header(conn, "content-disposition") == [
             ~s(attachment; filename="aldrun-world-guide.epub")
           ]

    assert <<"PK", _rest::binary>> = response(conn, 200)
  end

  test "shows the export action on the world dashboard", %{conn: conn, world: world} do
    {:ok, view, _html} = live(conn, ~p"/worlds/#{world.id}/dashboard")

    assert has_element?(view, "#world-export-menu[phx-click-away]")
    assert has_element?(view, "#geography-dashboard > #world-export-menu")
    assert has_element?(view, "#world-export-toggle.stone-button")

    assert has_element?(
             view,
             "#world-pdf-export.stone-text[href='/worlds/#{world.id}/export.pdf'] .stone-muted"
           )

    assert has_element?(
             view,
             "#world-epub-export.stone-text[href='/worlds/#{world.id}/export.epub'] .stone-muted"
           )

    assert has_element?(view, "#world-export-menu > .stone-menu")
  end
end
