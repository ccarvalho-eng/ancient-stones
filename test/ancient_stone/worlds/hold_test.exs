defmodule AncientStone.Worlds.HoldTest do
  use ExUnit.Case

  alias AncientStone.Worlds.Hold

  test "changeset/2 accepts a named hold" do
    struct = %Hold{province_id: Ecto.UUID.generate()}

    attrs = %{
      name: "some name",
      description: "some description"
    }

    changeset = Hold.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 requires a name and province" do
    struct = %Hold{}

    attrs = %{
      name: nil,
      description: nil
    }

    changeset = Hold.changeset(struct, attrs)

    refute changeset.valid?
  end

  test "changeset/2 keeps the assigned province" do
    struct = %Hold{province_id: Ecto.UUID.generate()}
    attrs = %{name: "some name", province_id: Ecto.UUID.generate()}

    changeset = Hold.changeset(struct, attrs)

    assert Ecto.Changeset.get_field(changeset, :province_id) == struct.province_id
  end
end
