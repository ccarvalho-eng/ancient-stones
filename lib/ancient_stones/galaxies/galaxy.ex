defmodule AncientStones.Galaxies.Galaxy do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "galaxies" do
    field :name, :string
    field :description, :string

    has_many(:worlds, World)

    timestamps(type: :utc_datetime)
  end

  def changeset(galaxy, attrs) do
    galaxy
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :galaxies_name_index)
  end
end
