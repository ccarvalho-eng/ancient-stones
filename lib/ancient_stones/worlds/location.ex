defmodule AncientStones.Worlds.Location do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Maps.MapItem
  alias AncientStones.Worlds.CharacterLocation
  alias AncientStones.Worlds.CivilizationLocation
  alias AncientStones.Worlds.CommercialVenture
  alias AncientStones.Worlds.CreatureLocation
  alias AncientStones.Worlds.Geography
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.LoreConnection
  alias AncientStones.Worlds.Household
  alias AncientStones.Worlds.Landholding
  alias AncientStones.Worlds.WaterBody

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "locations" do
    field :name, :string
    field :description, :string
    field :map_x, :integer
    field :map_y, :integer
    field :visibility, Ecto.Enum, values: Geography.visibility_values(), default: :known

    belongs_to(:hold, Hold)
    belongs_to(:parent_location, Location)
    belongs_to(:location_type, LocationType)
    belongs_to(:water_body, WaterBody)
    has_many(:child_locations, Location, foreign_key: :parent_location_id)
    has_many(:character_locations, CharacterLocation)
    has_many(:characters, through: [:character_locations, :character])
    has_many(:civilization_locations, CivilizationLocation)
    has_many(:civilizations, through: [:civilization_locations, :civilization])
    has_many(:commercial_ventures, CommercialVenture, foreign_key: :home_location_id)
    has_many(:creature_locations, CreatureLocation)
    has_many(:creatures, through: [:creature_locations, :creature])
    has_many(:source_lore_connections, LoreConnection, foreign_key: :source_location_id)
    has_many(:target_lore_connections, LoreConnection, foreign_key: :target_location_id)
    has_many(:map_items, MapItem)
    has_many(:households, Household, foreign_key: :home_location_id)
    has_many(:landholdings, Landholding)

    timestamps(type: :utc_datetime)
  end

  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name, :description, :map_x, :map_y, :visibility])
    |> validate_required([:name, :hold_id, :location_type_id])
    |> foreign_key_constraint(:hold_id)
    |> foreign_key_constraint(:parent_location_id)
    |> foreign_key_constraint(:location_type_id)
    |> foreign_key_constraint(:water_body_id)
    |> unique_constraint(:name, name: :locations_hold_id_name_root_index)
    |> unique_constraint(:name, name: :locations_hold_id_parent_location_id_name_index)
    |> unique_constraint(:map_x,
      name: :locations_hold_id_map_coordinates_index,
      message: "coordinates already used by another location in this hold"
    )
  end
end
