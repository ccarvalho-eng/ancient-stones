defmodule AncientStones.Maps.MapItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Maps.MapDocument
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.Province

  @layers ~w(terrain features labels)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "map_items" do
    field :item_key, :binary_id
    field :object_type, :string
    field :kind, :string
    field :layer, :string
    field :position, :integer
    field :name, :string
    field :icon_author, :string
    field :x, :float
    field :y, :float
    field :angle, :float, default: 0.0
    field :scale_x, :float, default: 1.0
    field :scale_y, :float, default: 1.0
    field :object_data, :map, default: %{}

    belongs_to :map_document, MapDocument
    belongs_to :continent, Continent
    belongs_to :province, Province
    belongs_to :hold, Hold
    belongs_to :location, Location

    timestamps(type: :utc_datetime)
  end

  def changeset(map_item, attrs) do
    map_item
    |> cast(attrs, [
      :item_key,
      :object_type,
      :kind,
      :layer,
      :position,
      :name,
      :icon_author,
      :x,
      :y,
      :angle,
      :scale_x,
      :scale_y,
      :object_data,
      :continent_id,
      :province_id,
      :hold_id,
      :location_id
    ])
    |> validate_required([
      :item_key,
      :object_type,
      :layer,
      :position,
      :x,
      :y,
      :object_data,
      :map_document_id
    ])
    |> validate_inclusion(:layer, @layers)
    |> validate_number(:scale_x, greater_than: 0)
    |> validate_number(:scale_y, greater_than: 0)
    |> foreign_key_constraint(:continent_id)
    |> foreign_key_constraint(:province_id)
    |> foreign_key_constraint(:hold_id)
    |> foreign_key_constraint(:location_id)
    |> check_constraint(:continent_id, name: :map_items_single_entity_check)
    |> unique_constraint(:item_key, name: :map_items_map_document_id_item_key_index)
    |> unique_constraint(:continent_id,
      name: :map_items_map_document_id_continent_id_index,
      message: "is already placed on this map"
    )
    |> unique_constraint(:province_id,
      name: :map_items_map_document_id_province_id_index,
      message: "is already placed on this map"
    )
    |> unique_constraint(:hold_id,
      name: :map_items_map_document_id_hold_id_index,
      message: "is already placed on this map"
    )
    |> unique_constraint(:location_id,
      name: :map_items_map_document_id_location_id_index,
      message: "is already placed on this map"
    )
  end
end
