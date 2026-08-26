defmodule AncientStones.Worlds.TradeFlow do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.ContinentCurrency
  alias AncientStones.Worlds.TradeRoute

  @frequencies [:daily, :weekly, :monthly, :seasonal, :annual]
  @coverage_scopes [:representative_consignment, :minimum_recorded, :estimated_total]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "trade_flows" do
    field :commodity, :string
    field :category, :string
    field :quantity, :decimal
    field :unit, :string
    field :declared_value, :decimal
    field :frequency, Ecto.Enum, values: @frequencies, default: :annual
    field :coverage_scope, Ecto.Enum, values: @coverage_scopes
    field :quantity_basis, :string
    field :unit_mass_kg, :decimal
    field :annual_consignment_count, :integer
    field :description, :string
    belongs_to :trade_route, TradeRoute
    belongs_to :currency, ContinentCurrency
    timestamps(type: :utc_datetime)
  end

  def changeset(trade_flow, attrs, refs \\ %{}) do
    trade_flow
    |> cast(attrs, [
      :commodity,
      :category,
      :quantity,
      :unit,
      :declared_value,
      :frequency,
      :coverage_scope,
      :quantity_basis,
      :unit_mass_kg,
      :annual_consignment_count,
      :description
    ])
    |> put_refs(refs)
    |> validate_required([
      :commodity,
      :quantity,
      :unit,
      :declared_value,
      :frequency,
      :trade_route_id,
      :currency_id
    ])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:declared_value, greater_than_or_equal_to: 0)
    |> validate_number(:unit_mass_kg, greater_than: 0)
    |> validate_number(:annual_consignment_count, greater_than: 0)
    |> foreign_key_constraint(:trade_route_id)
    |> foreign_key_constraint(:currency_id)
    |> check_constraint(:quantity, name: :trade_flows_quantity_positive)
    |> check_constraint(:declared_value, name: :trade_flows_declared_value_non_negative)
    |> check_constraint(:frequency, name: :trade_flows_frequency)
    |> check_constraint(:unit_mass_kg, name: :trade_flows_mass_and_count_positive)
    |> unique_constraint(:commodity, name: :trade_flows_trade_route_id_commodity_index)
  end

  def frequency_options do
    Enum.map(@frequencies, fn frequency ->
      {frequency |> Atom.to_string() |> String.capitalize(), frequency}
    end)
  end

  def coverage_scope_options do
    options(@coverage_scopes)
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
