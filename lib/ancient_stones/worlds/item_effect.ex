defmodule AncientStones.Worlds.ItemEffect do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Effect
  alias AncientStones.Worlds.Item

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "item_effects" do
    field :position, :integer
    field :notes, :string

    belongs_to(:item, Item)
    belongs_to(:effect, Effect)

    timestamps(type: :utc_datetime)
  end

  def changeset(item_effect, attrs) do
    item_effect
    |> cast(attrs, [:position, :notes])
    |> validate_required([:item_id, :effect_id, :position])
    |> validate_number(:position, greater_than: 0)
    |> foreign_key_constraint(:item_id)
    |> foreign_key_constraint(:effect_id)
    |> unique_constraint(:effect_id, name: :item_effects_item_id_effect_id_index)
    |> unique_constraint(:position, name: :item_effects_item_id_position_index)
  end
end
