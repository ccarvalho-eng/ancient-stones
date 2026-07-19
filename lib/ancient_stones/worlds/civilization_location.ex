defmodule AncientStones.Worlds.CivilizationLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.Location

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "civilization_locations" do
    field :relationship, :string
    field :description, :string

    belongs_to(:civilization, Civilization)
    belongs_to(:location, Location)

    timestamps(type: :utc_datetime)
  end

  def changeset(civilization_location, attrs) do
    civilization_location
    |> cast(attrs, [:relationship, :description])
    |> validate_required([:civilization_id, :location_id])
    |> foreign_key_constraint(:civilization_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint(:location_id,
      name: :civilization_locations_civilization_id_location_id_index
    )
  end
end
