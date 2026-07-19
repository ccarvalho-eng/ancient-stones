defmodule AncientStones.Worlds.LocationTest do
  use ExUnit.Case

  alias AncientStones.Worlds.Location

  test "changeset/2 accepts a named location" do
    struct = %Location{hold_id: Ecto.UUID.generate(), location_type_id: Ecto.UUID.generate()}
    attrs = %{name: "Whiterun", description: "A central city"}

    changeset = Location.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 requires a name, hold, and location type" do
    struct = %Location{}
    attrs = %{name: nil, description: nil}

    changeset = Location.changeset(struct, attrs)

    refute changeset.valid?
  end

  test "changeset/2 keeps assigned hierarchy fields" do
    struct = %Location{
      hold_id: Ecto.UUID.generate(),
      location_type_id: Ecto.UUID.generate(),
      parent_location_id: Ecto.UUID.generate()
    }

    attrs = %{
      name: "Dragonsreach",
      hold_id: Ecto.UUID.generate(),
      location_type_id: Ecto.UUID.generate(),
      parent_location_id: Ecto.UUID.generate()
    }

    changeset = Location.changeset(struct, attrs)

    assert Ecto.Changeset.get_field(changeset, :hold_id) == struct.hold_id
    assert Ecto.Changeset.get_field(changeset, :location_type_id) == struct.location_type_id
    assert Ecto.Changeset.get_field(changeset, :parent_location_id) == struct.parent_location_id
  end
end
