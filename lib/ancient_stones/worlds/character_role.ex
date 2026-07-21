defmodule AncientStones.Worlds.CharacterRole do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "character_roles" do
    field :name, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:characters, Character)

    timestamps(type: :utc_datetime)
  end

  def changeset(character_role, attrs) do
    character_role
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :character_roles_world_id_name_index)
  end
end
