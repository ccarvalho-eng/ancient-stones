defmodule AncientStones.Worlds.Province do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Geography
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.PoliticalOffice

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "provinces" do
    field :name, :string
    field :description, :string
    field :terrain, Ecto.Enum, values: Geography.terrain_values()
    field :climate, Ecto.Enum, values: Geography.climate_values()

    belongs_to(:continent, Continent)
    has_many(:holds, Hold)
    has_many(:political_offices, PoliticalOffice)

    timestamps(type: :utc_datetime)
  end

  def changeset(province, attrs) do
    province
    |> cast(attrs, [:name, :description, :terrain, :climate])
    |> validate_required([:name, :continent_id])
    |> foreign_key_constraint(:continent_id)
    |> unique_constraint(:name, name: :provinces_continent_id_name_index)
  end
end
