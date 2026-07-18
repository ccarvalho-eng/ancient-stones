defmodule AncientStone.WorldTest do
  use ExUnit.Case
  doctest AncientStone.World

  alias AncientStone.World

  test "changeset/2 builds a valid changeset" do
    struct = %World{}
    attrs = %{name: "some name", description: "some description"}

    changeset = World.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 builds an invalid changeset" do
    struct = %World{}
    attrs = %{name: nil, description: nil}

    changeset = World.changeset(struct, attrs) |> dbg()

    refute changeset.valid?
  end
end
