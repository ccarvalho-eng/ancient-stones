defmodule AncientStones.Worlds.CharacterRelationship do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.World

  @relationship_types [
    :parent_child,
    :siblings,
    :spouses,
    :partners,
    :betrothed,
    :foster_parent_child,
    :foster_siblings,
    :guardian_ward
  ]
  @statuses [:active, :estranged, :dissolved, :deceased, :disputed, :historical]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "character_relationships" do
    field :relationship_type, Ecto.Enum, values: @relationship_types
    field :character_a_role, :string
    field :character_b_role, :string
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :start_date_label, :string
    field :end_date_label, :string
    field :description, :string

    belongs_to :world, World
    belongs_to :character_a, Character
    belongs_to :character_b, Character

    timestamps(type: :utc_datetime)
  end

  def relationship_type_options do
    Enum.map(@relationship_types, &{humanize(&1), &1})
  end

  def status_options do
    Enum.map(@statuses, &{humanize(&1), &1})
  end

  def changeset(relationship, attrs) do
    relationship
    |> cast(attrs, [
      :relationship_type,
      :character_a_role,
      :character_b_role,
      :status,
      :start_date_label,
      :end_date_label,
      :description
    ])
    |> validate_required([:relationship_type, :status, :world_id])
    |> validate_length(:character_a_role, max: 120)
    |> validate_length(:character_b_role, max: 120)
    |> validate_length(:start_date_label, max: 120)
    |> validate_length(:end_date_label, max: 120)
    |> validate_length(:description, max: 4_000)
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:character_a_id)
    |> foreign_key_constraint(:character_b_id)
    |> unique_constraint([:world_id, :character_a_id, :character_b_id, :relationship_type],
      name: :character_relationships_unique_pair_index,
      error_key: :character_a_id,
      message: "relationship already recorded"
    )
    |> check_constraint(:character_b_id,
      name: :character_relationships_distinct_characters,
      message: "must be a different character"
    )
    |> check_constraint(:character_b_id,
      name: :character_relationships_canonical_pair,
      message: "relationship pair must be canonical"
    )
    |> check_constraint(:relationship_type, name: :character_relationships_type_check)
    |> check_constraint(:status, name: :character_relationships_status_check)
  end

  defp humanize(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
