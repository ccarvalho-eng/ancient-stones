defmodule AncientStone.World.Continent do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStone.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "continents" do
    field :name, :string
    field :description, :string

    belongs_to(:world, World)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(continent, attrs) do
    continent
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
