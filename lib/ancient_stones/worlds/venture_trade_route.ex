defmodule AncientStones.Worlds.VentureTradeRoute do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CommercialVenture
  alias AncientStones.Worlds.TradeRoute

  @roles [:carrier, :financier, :supplier, :warehouse, :agent]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "venture_trade_routes" do
    field :role, Ecto.Enum, values: @roles
    field :description, :string
    belongs_to :commercial_venture, CommercialVenture
    belongs_to :trade_route, TradeRoute
    timestamps(type: :utc_datetime)
  end

  def changeset(link, attrs, refs \\ %{}) do
    link
    |> cast(attrs, [:role, :description])
    |> put_refs(refs)
    |> validate_required([:role, :commercial_venture_id, :trade_route_id])
    |> foreign_key_constraint(:commercial_venture_id)
    |> foreign_key_constraint(:trade_route_id)
    |> check_constraint(:role, name: :venture_trade_routes_role)
    |> unique_constraint([:commercial_venture_id, :trade_route_id, :role],
      name: :venture_trade_routes_unique_role_index
    )
  end

  def role_options do
    Enum.map(@roles, fn role ->
      label = role |> Atom.to_string() |> String.capitalize()
      {label, role}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
