defmodule AncientStones.GalaxiesTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.Galaxies
  alias AncientStones.Galaxies.Galaxy
  alias AncientStones.Worlds

  test "updates a galaxy name" do
    {:ok, galaxy} = Galaxies.create_galaxy(%{name: "Mundus"})
    {:ok, world} = Worlds.create_world(%{name: "Nirn"}, galaxy: galaxy)

    assert {:ok, updated_galaxy} = Galaxies.update_galaxy(galaxy, %{"name" => "Mundus Prime"})
    assert updated_galaxy.name == "Mundus Prime"
    assert Repo.get!(Galaxy, galaxy.id).name == "Mundus Prime"
    assert world.galaxy_id == updated_galaxy.id
  end

  test "does not update a galaxy with an invalid name" do
    {:ok, galaxy} = Galaxies.create_galaxy(%{name: "Mundus"})

    assert {:error, changeset} = Galaxies.update_galaxy(galaxy, %{"name" => nil})
    assert %{name: [_ | _]} = errors_on(changeset)
  end
end
