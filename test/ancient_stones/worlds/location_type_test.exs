defmodule AncientStones.Worlds.LocationTypeTest do
  use ExUnit.Case

  alias AncientStones.Worlds.LocationType

  test "changeset/2 accepts a named location type" do
    struct = %LocationType{world_id: Ecto.UUID.generate()}
    attrs = %{name: "Ruin", description: "Old or abandoned structures"}

    changeset = LocationType.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 requires a name and world" do
    struct = %LocationType{}
    attrs = %{name: nil, description: nil}

    changeset = LocationType.changeset(struct, attrs)

    refute changeset.valid?
  end

  test "changeset/2 keeps the assigned world and parent" do
    struct = %LocationType{world_id: Ecto.UUID.generate(), parent_id: Ecto.UUID.generate()}

    attrs = %{
      name: "Nordic Ruin",
      world_id: Ecto.UUID.generate(),
      parent_id: Ecto.UUID.generate()
    }

    changeset = LocationType.changeset(struct, attrs)

    assert Ecto.Changeset.get_field(changeset, :world_id) == struct.world_id
    assert Ecto.Changeset.get_field(changeset, :parent_id) == struct.parent_id
  end
end
