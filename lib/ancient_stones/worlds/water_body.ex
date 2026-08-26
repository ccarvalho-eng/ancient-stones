defmodule AncientStones.Worlds.WaterBody do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.ProvinceWaterBody
  alias AncientStones.Worlds.TradeRouteLeg
  alias AncientStones.Worlds.TradeRouteLegWater
  alias AncientStones.Worlds.WaterBodyConnection
  alias AncientStones.Worlds.World

  @kinds [
    :ocean,
    :sea,
    :shelf_sea,
    :gulf,
    :bay,
    :strait,
    :sound,
    :fjord,
    :river,
    :estuary,
    :lake,
    :channel
  ]
  @salinities [:fresh, :brackish, :saline, :variable]
  @navigabilities [:none, :small_craft, :shallow_draft, :coastal, :ocean_going]
  @freeze_patterns [:never, :rare, :shore_ice, :seasonal, :prolonged, :perennial]
  @statuses [:active, :seasonal, :restricted, :historical]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "water_bodies" do
    field :name, :string
    field :kind, Ecto.Enum, values: @kinds
    field :salinity, Ecto.Enum, values: @salinities
    field :navigability, Ecto.Enum, values: @navigabilities
    field :freeze_pattern, Ecto.Enum, values: @freeze_patterns
    field :prevailing_conditions, :string
    field :hazards, :string
    field :latitude, :decimal
    field :longitude, :decimal
    field :source_latitude, :decimal
    field :source_longitude, :decimal
    field :mouth_latitude, :decimal
    field :mouth_longitude, :decimal
    field :length_km, :decimal
    field :area_km2, :decimal
    field :drainage_area_km2, :decimal
    field :source_elevation_m, :integer
    field :mean_discharge_m3_s, :decimal
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :description, :string
    belongs_to :world, World
    belongs_to :parent_water_body, __MODULE__
    has_many :child_water_bodies, __MODULE__, foreign_key: :parent_water_body_id
    has_many :origin_connections, WaterBodyConnection, foreign_key: :origin_water_body_id

    has_many :destination_connections, WaterBodyConnection,
      foreign_key: :destination_water_body_id

    has_many :province_links, ProvinceWaterBody
    has_many :locations, Location
    has_many :trade_route_legs, TradeRouteLeg
    has_many :trade_route_leg_waters, TradeRouteLegWater
    timestamps(type: :utc_datetime)
  end

  def changeset(water_body, attrs, refs \\ %{}) do
    water_body
    |> cast(attrs, [
      :name,
      :kind,
      :salinity,
      :navigability,
      :freeze_pattern,
      :prevailing_conditions,
      :hazards,
      :latitude,
      :longitude,
      :source_latitude,
      :source_longitude,
      :mouth_latitude,
      :mouth_longitude,
      :length_km,
      :area_km2,
      :drainage_area_km2,
      :source_elevation_m,
      :mean_discharge_m3_s,
      :status,
      :description
    ])
    |> validate_measurements()
    |> put_refs(refs)
    |> validate_required([
      :name,
      :kind,
      :salinity,
      :navigability,
      :freeze_pattern,
      :status,
      :world_id
    ])
    |> validate_parent()
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:parent_water_body_id)
    |> check_constraint(:parent_water_body_id, name: :water_bodies_not_own_parent)
    |> check_constraint(:latitude, name: :water_bodies_geographic_ranges)
    |> check_constraint(:length_km, name: :water_bodies_measurements_positive)
    |> unique_constraint(:name, name: :water_bodies_world_id_name_index)
  end

  def delete_changeset(water_body) do
    water_body
    |> change()
    |> no_assoc_constraint(:child_water_bodies)
    |> no_assoc_constraint(:origin_connections)
    |> no_assoc_constraint(:destination_connections)
    |> no_assoc_constraint(:province_links)
    |> no_assoc_constraint(:locations)
    |> no_assoc_constraint(:trade_route_legs)
    |> no_assoc_constraint(:trade_route_leg_waters)
  end

  def kind_options do
    options(@kinds)
  end

  def salinity_options do
    options(@salinities)
  end

  def navigability_options do
    options(@navigabilities)
  end

  def freeze_pattern_options do
    options(@freeze_patterns)
  end

  def status_options do
    options(@statuses)
  end

  defp validate_measurements(changeset) do
    changeset
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:source_latitude,
      greater_than_or_equal_to: -90,
      less_than_or_equal_to: 90
    )
    |> validate_number(:source_longitude,
      greater_than_or_equal_to: -180,
      less_than_or_equal_to: 180
    )
    |> validate_number(:mouth_latitude,
      greater_than_or_equal_to: -90,
      less_than_or_equal_to: 90
    )
    |> validate_number(:mouth_longitude,
      greater_than_or_equal_to: -180,
      less_than_or_equal_to: 180
    )
    |> validate_number(:length_km, greater_than: 0)
    |> validate_number(:area_km2, greater_than: 0)
    |> validate_number(:drainage_area_km2, greater_than: 0)
    |> validate_number(:source_elevation_m, greater_than_or_equal_to: 0)
    |> validate_number(:mean_discharge_m3_s, greater_than: 0)
  end

  defp validate_parent(changeset) do
    if get_field(changeset, :id) &&
         get_field(changeset, :id) == get_field(changeset, :parent_water_body_id) do
      add_error(changeset, :parent_water_body_id, "cannot be itself")
    else
      changeset
    end
  end

  defp options(values) do
    Enum.map(values, fn value ->
      label = value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
      {label, value}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
