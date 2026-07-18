defmodule AncientStone.Worlds.Continents.ProvinceTest do
  use ExUnit.Case

  alias AncientStone.Worlds.Continents.Province

  test "changeset/2 builds a valid changeset" do
    struct = %Province{}

    attrs = %{
      name: "some name",
      description: "some description",
      continent_id: Ecto.UUID.generate()
    }

    changeset = Province.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 builds an invalid changeset" do
    struct = %Province{}
    attrs = %{name: nil, description: nil, continent_id: nil}

    changeset = Province.changeset(struct, attrs)

    refute changeset.valid?
  end
end
