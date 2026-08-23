defmodule AncientStones.Worlds.CharacterLocationTest do
  use ExUnit.Case, async: true

  alias AncientStones.Worlds.CharacterLocation

  test "accepts an explicit character relationship to a location" do
    relation = %CharacterLocation{
      character_id: Ecto.UUID.generate(),
      location_id: Ecto.UUID.generate()
    }

    changeset =
      CharacterLocation.changeset(relation, %{
        relationship: "keeper",
        description: "Maintains the seasonal path to the falls."
      })

    assert changeset.valid?
  end

  test "rejects an unsupported relationship" do
    relation = %CharacterLocation{
      character_id: Ecto.UUID.generate(),
      location_id: Ecto.UUID.generate()
    }

    changeset = CharacterLocation.changeset(relation, %{relationship: "spawned"})

    refute changeset.valid?
  end
end
