defmodule AncientStones.Worlds.CharacterInventoryItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CharacterInventoryCategory
  alias AncientStones.Worlds.Item

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "character_inventory_items" do
    field :name, :string
    field :quantity, :integer
    field :equipped, :boolean
    field :notes, :string

    belongs_to(:character, Character)
    belongs_to(:inventory_category, CharacterInventoryCategory)
    belongs_to(:item, Item)

    timestamps(type: :utc_datetime)
  end

  def changeset(inventory_item, attrs) do
    inventory_item
    |> cast(attrs, [:name, :quantity, :equipped, :notes])
    |> validate_required([:character_id])
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:inventory_category_id)
    |> foreign_key_constraint(:item_id)
  end
end
