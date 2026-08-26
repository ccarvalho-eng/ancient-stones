defmodule AncientStones.Worlds.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CharacterInventoryItem
  alias AncientStones.Worlds.ItemEffect
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.World

  @hands_options [
    {"Ammunition", "ammunition"},
    {"One-Handed", "one-handed"},
    {"Two-Handed", "two-handed"},
    {"Worn", "worn"}
  ]

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
    field :period_name, :string
    field :date_label, :string
    field :maker, :string
    field :provenance, :string

    field :authenticity, Ecto.Enum,
      values: [:working, :historic, :reconstructed, :disputed, :legendary]

    field :description, :string

    belongs_to(:world, World)
    belongs_to(:find_location, Location)
    has_many(:character_inventory_items, CharacterInventoryItem)
    has_many(:item_effects, ItemEffect)

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
      :period_name,
      :date_label,
      :maker,
      :provenance,
      :authenticity,
      :description
    ])
    |> validate_required([:name, :world_id])
    |> validate_number(:damage, greater_than_or_equal_to: 0)
    |> validate_number(:critical_damage, greater_than_or_equal_to: 0)
    |> validate_number(:value, greater_than_or_equal_to: 0)
    |> validate_inclusion(:hands, hands_values())
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:find_location_id)
    |> check_constraint(:authenticity, name: :items_authenticity)
    |> unique_constraint(:name, name: :items_world_id_name_index)
  end

  def hands_options do
    @hands_options
  end

  defp hands_values do
    Enum.map(@hands_options, fn {_label, value} -> value end)
  end
end
