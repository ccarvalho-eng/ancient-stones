defmodule AncientStones.Worlds.SkillTree do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Skill
  alias AncientStones.Worlds.SkillTreePerk
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "skill_trees" do
    field :name, :string
    field :category, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:skills, Skill)
    has_many(:perks, SkillTreePerk)

    timestamps(type: :utc_datetime)
  end

  def changeset(skill_tree, attrs) do
    skill_tree
    |> cast(attrs, [:name, :category, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :skill_trees_world_id_name_index)
  end
end
