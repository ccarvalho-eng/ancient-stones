defmodule AncientStones.Worlds.PoliticalOfficeTest do
  use ExUnit.Case, async: true

  alias AncientStones.Worlds.PoliticalOffice

  test "accepts a continent-scoped High King" do
    office = %PoliticalOffice{
      world_id: Ecto.UUID.generate(),
      continent_id: Ecto.UUID.generate()
    }

    changeset =
      PoliticalOffice.changeset(office, %{
        office: "High King",
        scope: "continent"
      })

    assert changeset.valid?
  end

  test "rejects a hold-scoped High King" do
    office = %PoliticalOffice{
      world_id: Ecto.UUID.generate(),
      hold_id: Ecto.UUID.generate()
    }

    changeset =
      PoliticalOffice.changeset(office, %{
        office: "High King",
        scope: "hold"
      })

    refute changeset.valid?

    assert "must be scoped to a continent or province" in errors_on(changeset).office
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        options
        |> Keyword.get(String.to_existing_atom(key), key)
        |> to_string()
      end)
    end)
  end
end
