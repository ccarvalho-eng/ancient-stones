defmodule AncientStones.Worlds.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CharacterInventoryItem
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "items" do
    field :name, :string
    field :category, :string
    field :kind, :string
    field :material, :string
    field :hands, :string
    field :damage, :integer
    field :critical_damage, :integer
    field :weight, :decimal
    field :value, :integer
    field :source, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:character_inventory_items, CharacterInventoryItem)

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :name,
      :category,
      :kind,
      :material,
      :hands,
      :damage,
      :critical_damage,
      :weight,
      :value,
      :source,
      :description
    ])
    |> validate_required([:name, :world_id])
    |> validate_number(:damage, greater_than_or_equal_to: 0)
    |> validate_number(:critical_damage, greater_than_or_equal_to: 0)
    |> validate_number(:value, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :items_world_id_name_index)
  end
end
