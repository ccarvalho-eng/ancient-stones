defmodule AncientStones.Worlds.CreatureLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.Location

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "creature_locations" do
    field :presence, :string
    field :description, :string

    belongs_to(:creature, Creature)
    belongs_to(:location, Location)

    timestamps(type: :utc_datetime)
  end

  def changeset(creature_location, attrs) do
    creature_location
    |> cast(attrs, [:presence, :description])
    |> validate_required([:creature_id, :location_id])
    |> foreign_key_constraint(:creature_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint(:location_id, name: :creature_locations_creature_id_location_id_index)
  end
end
