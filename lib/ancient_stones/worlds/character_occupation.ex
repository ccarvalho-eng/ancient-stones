defmodule AncientStones.Worlds.CharacterOccupation do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Occupation

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "character_occupations" do
    field :rank, :string
    field :primary, :boolean, default: false
    field :description, :string

    belongs_to(:character, Character)
    belongs_to(:occupation, Occupation)

    timestamps(type: :utc_datetime)
  end

  def changeset(character_occupation, attrs) do
    character_occupation
    |> cast(attrs, [:rank, :primary, :description])
    |> validate_required([:character_id, :occupation_id])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:occupation_id)
    |> unique_constraint(:occupation_id,
      name: :character_occupations_character_id_occupation_id_index
    )
    |> unique_constraint(:primary, name: :character_occupations_character_id_index)
  end
end
