defmodule AncientStones.Worlds.CharacterInventoryCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CharacterInventoryItem

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "character_inventory_categories" do
    field :name, :string
    field :position, :integer
    field :description, :string

    belongs_to(:character, Character)
    has_many(:inventory_items, CharacterInventoryItem, foreign_key: :inventory_category_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :position, :description])
    |> validate_required([:name, :position, :character_id])
    |> validate_number(:position, greater_than: 0)
    |> foreign_key_constraint(:character_id)
    |> unique_constraint(:name, name: :character_inventory_categories_character_id_name_index)
    |> unique_constraint(:position,
      name: :character_inventory_categories_character_id_position_index
    )
  end
end
