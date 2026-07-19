defmodule AncientStones.Worlds.Occupation do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CharacterOccupation
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "occupations" do
    field :name, :string
    field :category, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:character_occupations, CharacterOccupation)

    timestamps(type: :utc_datetime)
  end

  def changeset(occupation, attrs) do
    occupation
    |> cast(attrs, [:name, :category, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :occupations_world_id_name_index)
  end
end
