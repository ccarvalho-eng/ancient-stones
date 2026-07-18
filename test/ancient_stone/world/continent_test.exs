defmodule AncientStone.World.ContinentTest do
  use ExUnit.Case
  doctest AncientStone.World.Continent

  alias AncientStone.World.Continent

  test "changeset/2 builds a valid changeset" do
    struct = %Continent{}
    attrs = %{name: "some name", description: "some description"}

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
