defmodule AncientStones.Worlds.TradeRoute do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.TaxExemption
  alias AncientStones.Worlds.TradeFlow
  alias AncientStones.Worlds.TradeRouteLeg
  alias AncientStones.Worlds.TradeRouteStop
  alias AncientStones.Worlds.VentureTradeRoute
  alias AncientStones.Worlds.World

  @transport_modes [:caravan, :river, :sea, :road, :trail, :mixed]
  @statuses [:active, :seasonal, :suspended, :abandoned]
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
  @risk_levels [:negligible, :low, :moderate, :high, :severe]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "trade_routes" do
    field :name, :string
    field :transport_mode, Ecto.Enum, values: @transport_modes
    field :distance_km, :decimal
    field :seasonality, Ecto.Enum, values: @seasonalities
    field :risk, Ecto.Enum, values: @risk_levels
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :description, :string
    belongs_to :world, World
    belongs_to :origin_hold, Hold
    belongs_to :destination_hold, Hold
    belongs_to :origin_location, Location
    belongs_to :destination_location, Location
    has_many :trade_flows, TradeFlow
    has_many :stops, TradeRouteStop
    has_many :legs, TradeRouteLeg
    has_many :tax_exemptions, TaxExemption
    has_many :venture_links, VentureTradeRoute
    timestamps(type: :utc_datetime)
  end

  def changeset(trade_route, attrs, refs \\ %{}) do
    trade_route
    |> cast(attrs, [
      :name,
      :transport_mode,
      :distance_km,
      :seasonality,
      :risk,
      :status,
      :description
    ])
    |> put_refs(refs)
    |> validate_required([
      :name,
      :transport_mode,
      :status,
      :world_id,
      :origin_hold_id,
      :destination_hold_id
    ])
    |> validate_number(:distance_km, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:origin_hold_id)
    |> foreign_key_constraint(:destination_hold_id)
    |> foreign_key_constraint(:origin_location_id)
    |> foreign_key_constraint(:destination_location_id)
    |> check_constraint(:destination_hold_id, name: :trade_routes_distinct_holds)
    |> check_constraint(:distance_km, name: :trade_routes_distance_non_negative)
    |> check_constraint(:seasonality, name: :trade_routes_seasonality)
    |> check_constraint(:risk, name: :trade_routes_risk)
    |> unique_constraint(:name, name: :trade_routes_world_id_name_index)
  end

  def transport_mode_options do
    enum_options(@transport_modes)
  end

  def status_options do
    enum_options(@statuses)
  end

  def seasonality_options do
    enum_options(@seasonalities)
  end

  def risk_options do
    enum_options(@risk_levels)
  end

  defp enum_options(values) do
    Enum.map(values, fn value ->
      label = value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
      {label, value}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
