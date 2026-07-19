defmodule AncientStones.Worlds.Skill do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CharacterSkill
  alias AncientStones.Worlds.SkillLevel
  alias AncientStones.Worlds.SkillTree
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "skills" do
    field :name, :string
    field :category, :string
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:skill_tree, SkillTree)
    has_many(:character_skills, CharacterSkill)
    has_many(:levels, SkillLevel)

    timestamps(type: :utc_datetime)
  end

  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:name, :category, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:skill_tree_id)
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :skills_world_id_name_index)
  end
end
