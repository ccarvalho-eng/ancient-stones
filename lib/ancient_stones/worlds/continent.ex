defmodule AncientStones.Worlds.Continent do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.ContinentCurrency
  alias AncientStones.Worlds.Geography
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "continents" do
    field :name, :string
    field :description, :string
    field :map_x, :integer
    field :map_y, :integer
    field :visibility, Ecto.Enum, values: Geography.visibility_values(), default: :known

    belongs_to(:world, World)
    has_many(:calendars, Calendar)
    has_many(:provinces, Province)
    has_one(:currency, ContinentCurrency)

    timestamps(type: :utc_datetime)
  end

  def changeset(continent, attrs) do
    continent
    |> cast(attrs, [:name, :description, :map_x, :map_y, :visibility])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :continents_world_id_name_index)
  end
end
