defmodule AncientStones.Worlds.CharacterSkill do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Skill

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "character_skills" do
    field :level, :string
    field :description, :string

    belongs_to(:character, Character)
    belongs_to(:skill, Skill)

    timestamps(type: :utc_datetime)
  end

  def changeset(character_skill, attrs) do
    character_skill
    |> cast(attrs, [:level, :description])
    |> validate_required([:character_id, :skill_id])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:skill_id)
    |> unique_constraint(:skill_id, name: :character_skills_character_id_skill_id_index)
  end
end
