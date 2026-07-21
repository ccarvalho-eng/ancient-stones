defmodule AncientStones.Worlds.ContinentCurrency do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Continent

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "continent_currencies" do
    field :name, :string
    field :description, :string
    field :value_per_unit, :decimal
    field :value_basis, :string

    belongs_to(:continent, Continent)

    timestamps(type: :utc_datetime)
  end

  def changeset(continent_currency, attrs) do
    continent_currency
    |> cast(attrs, [:name, :description, :value_per_unit, :value_basis])
    |> validate_required([:name, :continent_id])
    |> validate_number(:value_per_unit, greater_than: 0)
    |> foreign_key_constraint(:continent_id)
    |> unique_constraint(:continent_id)
  end
end
