defmodule AncientStones.Worlds.Effect do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.ItemEffect
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "effects" do
    field :name, :string
    field :category, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:item_effects, ItemEffect)

    timestamps(type: :utc_datetime)
  end

  def changeset(effect, attrs) do
    effect
    |> cast(attrs, [:name, :category, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :effects_world_id_name_index)
  end
end
