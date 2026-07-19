defmodule AncientStone.Worlds.ContinentTest do
  use ExUnit.Case

  alias AncientStone.Worlds.Continent

  test "changeset/2 accepts a named continent" do
    struct = %Continent{world_id: Ecto.UUID.generate()}
    attrs = %{name: "some name", description: "some description"}

    changeset = Continent.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 requires a name and world" do
    struct = %Continent{}
    attrs = %{name: nil, description: nil}

    changeset = Continent.changeset(struct, attrs)

    refute changeset.valid?
  end

  test "changeset/2 keeps the assigned world" do
    struct = %Continent{world_id: Ecto.UUID.generate()}
    attrs = %{name: "some name", world_id: Ecto.UUID.generate()}

    changeset = Continent.changeset(struct, attrs)

    assert Ecto.Changeset.get_field(changeset, :world_id) == struct.world_id
  end
end
