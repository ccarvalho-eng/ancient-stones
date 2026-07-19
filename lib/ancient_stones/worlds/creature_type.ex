defmodule AncientStones.Worlds.CreatureType do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "creature_types" do
    field :name, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:creatures, Creature)

    timestamps(type: :utc_datetime)
  end

  def changeset(creature_type, attrs) do
    creature_type
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :creature_types_world_id_name_index)
  end
end
