defmodule AncientStone.Worlds.WorldTest do
  use ExUnit.Case
  doctest AncientStone.Worlds.World

  alias AncientStone.Worlds.World

  test "changeset/2 builds a valid changeset" do
    struct = %World{}
    attrs = %{name: "some name", description: "some description"}

    changeset = World.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 builds an invalid changeset" do
    struct = %World{}
    attrs = %{name: nil, description: nil}

    changeset = World.changeset(struct, attrs)

    refute changeset.valid?
  end
end
