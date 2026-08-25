defmodule AncientStones.Worlds.Province do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Maps.MapItem
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Geography
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.ProvinceWaterBody

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "provinces" do
    field :name, :string
    field :description, :string
    field :terrain, Ecto.Enum, values: Geography.terrain_values()
    field :climate, Ecto.Enum, values: Geography.climate_values()
    field :map_x, :integer
    field :map_y, :integer
    field :visibility, Ecto.Enum, values: Geography.visibility_values(), default: :known
    field :climate_zone, :string
    field :moisture_regime, :string
    field :elevation_profile, :string
    field :geology, :string
    field :watershed, :string
    field :area_km2, :integer
    field :latitude, :decimal
    field :longitude, :decimal
    field :mean_winter_temperature_c, :decimal
    field :mean_summer_temperature_c, :decimal
    field :annual_precipitation_mm, :integer
    field :frost_free_days, :integer

    belongs_to(:continent, Continent)
    belongs_to(:capital_hold, Hold)
    has_many(:holds, Hold)
    has_many(:political_offices, PoliticalOffice)
    has_many(:water_body_links, ProvinceWaterBody)
    has_many(:map_items, MapItem)

    timestamps(type: :utc_datetime)
  end

  def changeset(province, attrs) do
    province
    |> cast(attrs, [
      :name,
      :description,
      :terrain,
      :climate,
      :map_x,
      :map_y,
      :visibility,
      :climate_zone,
      :moisture_regime,
      :elevation_profile,
      :geology,
      :watershed,
      :area_km2,
      :latitude,
      :longitude,
      :mean_winter_temperature_c,
      :mean_summer_temperature_c,
      :annual_precipitation_mm,
      :frost_free_days
    ])
    |> validate_measured_geography()
    |> validate_required([:name, :continent_id])
    |> foreign_key_constraint(:continent_id)
    |> foreign_key_constraint(:capital_hold_id)
    |> unique_constraint(:name, name: :provinces_continent_id_name_index)
  end

  defp validate_measured_geography(changeset) do
    changeset
    |> validate_number(:area_km2, greater_than: 0)
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:annual_precipitation_mm, greater_than_or_equal_to: 0)
    |> validate_number(:frost_free_days, greater_than_or_equal_to: 0, less_than_or_equal_to: 366)
    |> validate_temperature_order()
    |> check_constraint(:area_km2, name: :provinces_measured_geography_range)
    |> check_constraint(:mean_winter_temperature_c, name: :provinces_temperature_order)
  end

  defp validate_temperature_order(changeset) do
    winter = get_field(changeset, :mean_winter_temperature_c)
    summer = get_field(changeset, :mean_summer_temperature_c)

    if winter && summer && Decimal.gt?(winter, summer) do
      add_error(changeset, :mean_winter_temperature_c, "cannot exceed the summer mean")
    else
      changeset
    end
  end
end
