defmodule AncientStone.Worlds.World do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStone.Worlds.Continent

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "worlds" do
    field :name, :string
    field :description, :string

    has_many(:continents, Continent)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(world, attrs) do
    world
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
