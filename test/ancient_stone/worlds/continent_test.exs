defmodule AncientStone.Worlds.ContinentTest do
  use ExUnit.Case
  doctest AncientStone.Worlds.Continent

  alias AncientStone.Worlds.Continent

  test "changeset/2 builds a valid changeset" do
    struct = %Continent{}
    attrs = %{name: "some name", description: "some description", world_id: Ecto.UUID.generate()}

    changeset = Continent.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 builds an invalid changeset" do
    struct = %Continent{}
    attrs = %{name: nil, description: nil}

    changeset = Continent.changeset(struct, attrs)

    refute changeset.valid?
  end
end
