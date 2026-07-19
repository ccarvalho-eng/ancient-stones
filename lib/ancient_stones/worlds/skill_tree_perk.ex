defmodule AncientStones.Worlds.SkillTreePerk do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.SkillTree

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "skill_tree_perks" do
    field :name, :string
    field :required_level, :integer
    field :ranks, :integer
    field :position, :integer
    field :description, :string

    belongs_to(:skill_tree, SkillTree)

    timestamps(type: :utc_datetime)
  end

  def changeset(skill_tree_perk, attrs) do
    skill_tree_perk
    |> cast(attrs, [:name, :required_level, :ranks, :position, :description])
    |> validate_required([:name, :position, :skill_tree_id])
    |> validate_number(:required_level, greater_than_or_equal_to: 0)
    |> validate_number(:ranks, greater_than: 0)
    |> validate_number(:position, greater_than: 0)
    |> foreign_key_constraint(:skill_tree_id)
    |> unique_constraint(:name, name: :skill_tree_perks_skill_tree_id_name_index)
    |> unique_constraint(:position, name: :skill_tree_perks_skill_tree_id_position_index)
  end
end
