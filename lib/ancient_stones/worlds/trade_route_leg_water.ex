defmodule AncientStones.Worlds.TradeRouteLegWater do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.TradeRouteLeg
  alias AncientStones.Worlds.WaterBody

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "trade_route_leg_waters" do
    field :position, :integer
    field :distance_km, :decimal
    field :description, :string
    belongs_to :trade_route_leg, TradeRouteLeg
    belongs_to :water_body, WaterBody
    timestamps(type: :utc_datetime)
  end

  def changeset(traversal, attrs, refs \\ %{}) do
    traversal
    |> cast(attrs, [:position, :distance_km, :description])
    |> put_refs(refs)
    |> validate_required([:position, :trade_route_leg_id, :water_body_id])
    |> validate_number(:position, greater_than: 0)
    |> validate_number(:distance_km, greater_than: 0)
    |> foreign_key_constraint(:trade_route_leg_id)
    |> foreign_key_constraint(:water_body_id)
    |> check_constraint(:position, name: :trade_route_leg_waters_position_positive)
    |> check_constraint(:distance_km, name: :trade_route_leg_waters_distance_positive)
    |> unique_constraint([:trade_route_leg_id, :position])
    |> unique_constraint([:trade_route_leg_id, :water_body_id],
      name: :trade_route_leg_waters_unique_water_index
    )
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
