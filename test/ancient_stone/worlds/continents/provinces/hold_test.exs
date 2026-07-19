defmodule AncientStone.Worlds.Continents.Provinces.HoldTest do
  use ExUnit.Case

  alias AncientStone.Worlds.Continents.Provinces.Hold

  test "changeset/2 builds a valid changeset" do
    struct = %Hold{}

    attrs = %{
      name: "some name",
      description: "some description",
      province_id: Ecto.UUID.generate()
    }

    changeset = Hold.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 builds an invalid changeset" do
    struct = %Hold{}

    attrs = %{
      name: nil,
      description: nil,
      province_id: nil
    }

    changeset = Hold.changeset(struct, attrs)

    refute changeset.valid?
  end
end
