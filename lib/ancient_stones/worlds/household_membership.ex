defmodule AncientStones.Worlds.HouseholdMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Household

  @roles [
    :head,
    :spouse,
    :child,
    :other_kin,
    :fosterling,
    :dependent,
    :servant,
    :hired_worker,
    :unfree_dependent,
    :guest
  ]
  @statuses [:active, :absent, :former, :deceased]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "household_memberships" do
    field :role, Ecto.Enum, values: @roles, default: :dependent
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :is_primary, :boolean, default: false
    field :description, :string

    belongs_to :household, Household
    belongs_to :character, Character

    timestamps(type: :utc_datetime)
  end

  def role_options do
    Enum.map(@roles, &{humanize(&1), &1})
  end

  def status_options do
    Enum.map(@statuses, &{humanize(&1), &1})
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :status, :is_primary, :description])
    |> validate_required([:role, :status])
    |> validate_length(:description, max: 2_000)
    |> validate_primary_membership()
    |> foreign_key_constraint(:household_id)
    |> foreign_key_constraint(:character_id)
    |> unique_constraint([:household_id, :character_id])
    |> unique_constraint(:character_id,
      name: :household_memberships_one_primary_per_character_index
    )
    |> check_constraint(:role, name: :household_memberships_role_check)
    |> check_constraint(:status, name: :household_memberships_status_check)
    |> check_constraint(:is_primary, name: :household_memberships_primary_active_check)
  end

  defp validate_primary_membership(changeset) do
    if get_field(changeset, :is_primary) and get_field(changeset, :status) != :active do
      add_error(changeset, :is_primary, "requires an active membership")
    else
      changeset
    end
  end

  defp humanize(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
