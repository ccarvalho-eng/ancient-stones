defmodule AncientStones.Worlds.Continent do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Maps.MapItem
  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.ContinentCurrency
  alias AncientStones.Worlds.Geography
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "continents" do
    field :name, :string
    field :description, :string
    field :map_x, :integer
    field :map_y, :integer
    field :visibility, Ecto.Enum, values: Geography.visibility_values(), default: :known
    field :north_latitude, :decimal
    field :south_latitude, :decimal
    field :west_longitude, :decimal
    field :east_longitude, :decimal
    field :area_km2, :integer
    field :tectonic_setting, :string
    field :prevailing_winds, :string
    field :ocean_currents, :string
    field :major_watersheds, :string

    belongs_to(:world, World)
    has_many(:calendars, Calendar)
    has_many(:provinces, Province)
    has_one(:currency, ContinentCurrency)
    has_many(:map_items, MapItem)

    timestamps(type: :utc_datetime)
  end

  def changeset(continent, attrs) do
    continent
    |> cast(attrs, [
      :name,
      :description,
      :map_x,
      :map_y,
      :visibility,
      :north_latitude,
      :south_latitude,
      :west_longitude,
      :east_longitude,
      :area_km2,
      :tectonic_setting,
      :prevailing_winds,
      :ocean_currents,
      :major_watersheds
    ])
    |> validate_required([:name, :world_id])
    |> validate_number(:north_latitude,
      greater_than_or_equal_to: -90,
      less_than_or_equal_to: 90
    )
    |> validate_number(:south_latitude,
      greater_than_or_equal_to: -90,
      less_than_or_equal_to: 90
    )
    |> validate_number(:west_longitude,
      greater_than_or_equal_to: -180,
      less_than_or_equal_to: 180
    )
    |> validate_number(:east_longitude,
      greater_than_or_equal_to: -180,
      less_than_or_equal_to: 180
    )
    |> validate_number(:area_km2, greater_than: 0)
    |> check_constraint(:north_latitude, name: :continents_latitude_bounds)
    |> check_constraint(:west_longitude, name: :continents_longitude_bounds)
    |> check_constraint(:north_latitude, name: :continents_latitude_order)
    |> check_constraint(:area_km2, name: :continents_area_km2_positive)
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :continents_world_id_name_index)
  end
end
