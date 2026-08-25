defmodule AncientStones.Worlds.VentureMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CommercialVenture
  alias AncientStones.Worlds.Household

  @statuses [:active, :withdrawn, :completed, :inherited]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "venture_memberships" do
    field :role, :string
    field :contribution, :string
    field :share_percentage, :decimal
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :description, :string
    belongs_to :commercial_venture, CommercialVenture
    belongs_to :household, Household
    belongs_to :character, Character
    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs, refs \\ %{}) do
    membership
    |> cast(attrs, [:role, :contribution, :share_percentage, :status, :description])
    |> put_refs(refs)
    |> validate_required([:role, :status, :commercial_venture_id])
    |> validate_number(:share_percentage, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_exactly_one_member()
    |> foreign_key_constraint(:commercial_venture_id)
    |> foreign_key_constraint(:household_id)
    |> foreign_key_constraint(:character_id)
    |> check_constraint(:member, name: :venture_memberships_exactly_one_member)
    |> check_constraint(:share_percentage, name: :venture_memberships_share_range)
    |> check_constraint(:status, name: :venture_memberships_status)
    |> unique_constraint(:household_id, name: :venture_memberships_unique_household_index)
    |> unique_constraint(:character_id, name: :venture_memberships_unique_character_index)
  end

  def status_options do
    Enum.map(@statuses, fn status ->
      label = status |> Atom.to_string() |> String.capitalize()
      {label, status}
    end)
  end

  defp validate_exactly_one_member(changeset) do
    household_id = get_field(changeset, :household_id)
    character_id = get_field(changeset, :character_id)

    if is_nil(household_id) == is_nil(character_id) do
      add_error(changeset, :member, "must select exactly one character or household")
    else
      changeset
    end
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
