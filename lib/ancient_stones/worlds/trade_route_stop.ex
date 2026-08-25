defmodule AncientStones.Worlds.TradeRouteStop do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.TradeRoute

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "trade_route_stops" do
    field :position, :integer
    field :handling_notes, :string
    field :description, :string
    belongs_to :trade_route, TradeRoute
    belongs_to :location, Location
    timestamps(type: :utc_datetime)
  end

  def changeset(stop, attrs, refs \\ %{}) do
    stop
    |> cast(attrs, [:position, :handling_notes, :description])
    |> put_refs(refs)
    |> validate_required([:position, :trade_route_id, :location_id])
    |> validate_number(:position, greater_than: 0)
    |> foreign_key_constraint(:trade_route_id)
    |> foreign_key_constraint(:location_id)
    |> check_constraint(:position, name: :trade_route_stops_position_positive)
    |> unique_constraint([:trade_route_id, :position])
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
