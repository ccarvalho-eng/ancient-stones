defmodule AncientStone.Worlds.Continent do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStone.Worlds.Continents.Province
  alias AncientStone.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "continents" do
    field :name, :string
    field :description, :string

    belongs_to(:world, World)

    has_many(:provinces, Province)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(continent, attrs) do
    continent
    |> cast(attrs, [:name, :description, :world_id])
    |> validate_required([:name, :world_id])
  end
end
