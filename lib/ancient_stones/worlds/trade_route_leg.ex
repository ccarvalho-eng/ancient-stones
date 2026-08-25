defmodule AncientStones.Worlds.TradeRouteLeg do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.TradeRoute
  alias AncientStones.Worlds.TradeRouteLegWater
  alias AncientStones.Worlds.TradeRouteStop
  alias AncientStones.Worlds.WaterBody

  @transport_modes [:caravan, :river, :sea, :road, :trail, :mixed]
  @seasonalities [
    :year_round,
    :spring_to_autumn,
    :summer_only,
    :winter_only,
    :dry_season,
    :wet_season,
    :thaw_only,
    :intermittent
  ]
  @risks [:negligible, :low, :moderate, :high, :severe]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "trade_route_legs" do
    field :position, :integer
    field :transport_mode, Ecto.Enum, values: @transport_modes
    field :distance_km, :decimal
    field :typical_travel_days, :decimal
    field :seasonality, Ecto.Enum, values: @seasonalities
    field :risk, Ecto.Enum, values: @risks
    field :handling_notes, :string
    field :description, :string
    belongs_to :trade_route, TradeRoute
    belongs_to :origin_stop, TradeRouteStop
    belongs_to :destination_stop, TradeRouteStop
    belongs_to :water_body, WaterBody
    has_many :water_traversals, TradeRouteLegWater
    timestamps(type: :utc_datetime)
  end

  def changeset(leg, attrs, refs \\ %{}) do
    leg
    |> cast(attrs, [
      :position,
      :transport_mode,
      :distance_km,
      :typical_travel_days,
      :seasonality,
      :risk,
      :handling_notes,
      :description
    ])
    |> put_refs(refs)
    |> validate_required([
      :position,
      :transport_mode,
      :distance_km,
      :typical_travel_days,
      :trade_route_id,
      :origin_stop_id,
      :destination_stop_id
    ])
    |> validate_number(:position, greater_than: 0)
    |> validate_number(:distance_km, greater_than: 0)
    |> validate_number(:typical_travel_days, greater_than: 0)
    |> validate_distinct_stops()
    |> foreign_key_constraint(:trade_route_id)
    |> foreign_key_constraint(:origin_stop_id)
    |> foreign_key_constraint(:destination_stop_id)
    |> foreign_key_constraint(:water_body_id)
    |> check_constraint(:destination_stop_id, name: :trade_route_legs_distinct_stops)
    |> check_constraint(:position, name: :trade_route_legs_position_positive)
    |> check_constraint(:distance_km, name: :trade_route_legs_distance_positive)
    |> check_constraint(:water_body_id, name: :trade_route_legs_mode_water_consistency)
    |> check_constraint(:typical_travel_days, name: :trade_route_legs_travel_time_positive)
    |> unique_constraint([:trade_route_id, :position])
  end

  def transport_mode_options do
    options(@transport_modes)
  end

  def seasonality_options do
    options(@seasonalities)
  end

  def risk_options do
    options(@risks)
  end

  defp validate_distinct_stops(changeset) do
    if get_field(changeset, :origin_stop_id) == get_field(changeset, :destination_stop_id) do
      add_error(changeset, :destination_stop_id, "must differ from origin")
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
