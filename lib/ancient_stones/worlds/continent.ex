defmodule AncientStones.Worlds.Continent do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "continents" do
    field :name, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:calendars, Calendar)
    has_many(:provinces, Province)

    timestamps(type: :utc_datetime)
  end

  def changeset(continent, attrs) do
    continent
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :continents_world_id_name_index)
  end
end
