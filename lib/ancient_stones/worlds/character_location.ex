defmodule AncientStones.Worlds.CharacterLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Location

  @relationship_options [
    {"Resident", "resident"},
    {"Owner", "owner"},
    {"Worker", "worker"},
    {"Keeper", "keeper"},
    {"Guide", "guide"},
    {"Visitor", "visitor"},
    {"Missing", "missing"},
    {"Historical", "historical"}
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "character_locations" do
    field :relationship, :string
    field :description, :string

    belongs_to(:character, Character)
    belongs_to(:location, Location)

    timestamps(type: :utc_datetime)
  end

  def changeset(character_location, attrs) do
    character_location
    |> cast(attrs, [:relationship, :description])
    |> validate_required([:character_id, :location_id, :relationship])
    |> validate_inclusion(:relationship, relationship_values())
    |> check_constraint(:relationship, name: :character_locations_relationship_valid)
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint(:location_id,
      name: :character_locations_character_id_location_id_index
    )
  end

  def relationship_options do
    @relationship_options
  end

  defp relationship_values do
    Enum.map(@relationship_options, fn {_label, value} -> value end)
  end
end
