defmodule AncientStonesWeb.WorldLive.ShowTest do
  use AncientStonesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AncientStones.Repo
  alias AncientStones.Worlds.World

  test "renders world details", %{conn: conn} do
    world = create_world()

    {:ok, view, _html} = live(conn, ~p"/worlds/#{world}")

    assert has_element?(view, "#world-show")
    assert has_element?(view, "#world-name")
    assert has_element?(view, "#world-description")

    assert render(view) =~ "Eldoria"
    assert render(view) =~ "A realm of ancient stone"
  end

  test "raises for a missing world", %{conn: conn} do
    missing_id = Ecto.UUID.generate()

    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/worlds/#{missing_id}")
    end
  end

  defp create_world(attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          name: "Eldoria",
          description: "A realm of ancient stone"
        },
        attrs
      )

    %World{}
    |> World.changeset(attrs)
    |> Repo.insert!()
  end
end
