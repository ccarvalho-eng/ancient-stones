defmodule AncientStones.Worlds.SkillLevel do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Skill

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "skill_levels" do
    field :name, :string
    field :rank, :integer
    field :minimum_value, :integer
    field :description, :string

    belongs_to(:skill, Skill)

    timestamps(type: :utc_datetime)
  end

  def changeset(skill_level, attrs) do
    skill_level
    |> cast(attrs, [:name, :rank, :minimum_value, :description])
    |> validate_required([:name, :rank, :skill_id])
    |> validate_number(:rank, greater_than: 0)
    |> validate_number(:minimum_value, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:skill_id)
    |> unique_constraint(:name, name: :skill_levels_skill_id_name_index)
    |> unique_constraint(:rank, name: :skill_levels_skill_id_rank_index)
  end
end
