defmodule AncientStone.Worlds.Continents.Province do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStone.Worlds.Continent
  alias AncientStone.Worlds.Continents.Hold

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "provinces" do
    field :name, :string
    field :description, :string

    belongs_to(:continent, Continent)
    has_many(:holds, Hold)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(province, attrs) do
    province
    |> cast(attrs, [:name, :description, :continent_id])
    |> validate_required([:name, :continent_id])
  end
end
