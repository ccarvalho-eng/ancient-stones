defmodule AncientStone.Worlds.ProvinceTest do
  use ExUnit.Case

  alias AncientStone.Worlds.Province

  test "changeset/2 accepts a named province" do
    struct = %Province{continent_id: Ecto.UUID.generate()}

    attrs = %{
      name: "some name",
      description: "some description"
    }

    changeset = Province.changeset(struct, attrs)

    assert changeset.valid?
  end

  test "changeset/2 requires a name and continent" do
    struct = %Province{}
    attrs = %{name: nil, description: nil}

    changeset = Province.changeset(struct, attrs)

    refute changeset.valid?
  end

  test "changeset/2 keeps the assigned continent" do
    struct = %Province{continent_id: Ecto.UUID.generate()}
    attrs = %{name: "some name", continent_id: Ecto.UUID.generate()}

    changeset = Province.changeset(struct, attrs)

    assert Ecto.Changeset.get_field(changeset, :continent_id) == struct.continent_id
  end
end
