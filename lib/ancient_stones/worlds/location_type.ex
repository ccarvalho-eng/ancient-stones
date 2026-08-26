defmodule AncientStones.Worlds.LocationType do
  @moduledoc """
  A world-owned classification for locations.

  Types may be nested to distinguish broad place categories from more specific
  establishments or geographic features.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}

  schema "location_types" do
    field :name, :string
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:parent, LocationType)
    has_many(:children, LocationType, foreign_key: :parent_id)

    timestamps(type: :utc_datetime)
  end

  @doc "Builds a location-type changeset and enforces sibling-name uniqueness."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(location_type, attrs) do
    location_type
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:parent_id)
    |> unique_constraint(:name, name: :location_types_world_id_name_root_index)
    |> unique_constraint(:name, name: :location_types_world_id_parent_id_name_index)
  end
end
