defmodule AncientStones.Worlds.ContinentCurrency do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Continent

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "continent_currencies" do
    field :name, :string
    field :description, :string

    belongs_to(:continent, Continent)

    timestamps(type: :utc_datetime)
  end

  def changeset(continent_currency, attrs) do
    continent_currency
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :continent_id])
    |> foreign_key_constraint(:continent_id)
    |> unique_constraint(:continent_id)
  end
end
