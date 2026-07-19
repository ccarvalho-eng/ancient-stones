defmodule AncientStones.Worlds.LocationType do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "location_types" do
    field :name, :string
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:parent, LocationType)
    has_many(:children, LocationType, foreign_key: :parent_id)

    timestamps(type: :utc_datetime)
  end

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
