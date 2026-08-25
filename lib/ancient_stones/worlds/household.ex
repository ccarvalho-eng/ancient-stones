defmodule AncientStones.Worlds.Household do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.HouseholdMembership
  alias AncientStones.Worlds.Landholding
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.VentureMembership
  alias AncientStones.Worlds.World

  @household_types [
    :farmstead,
    :magnate_household,
    :royal_household,
    :craft_household,
    :merchant_household,
    :fishing_household,
    :religious_household,
    :itinerant_household,
    :other
  ]
  @statuses [:active, :dispersed, :extinct, :historical]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "households" do
    field :name, :string
    field :household_type, Ecto.Enum, values: @household_types, default: :farmstead
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :description, :string
    field :resident_count, :integer
    field :dependent_count, :integer
    field :servant_count, :integer

    belongs_to :world, World
    belongs_to :home_location, Location
    has_many :memberships, HouseholdMembership
    has_many :members, through: [:memberships, :character]
    has_many :landholdings, Landholding
    has_many :venture_memberships, VentureMembership

    timestamps(type: :utc_datetime)
  end

  def household_type_options do
    Enum.map(@household_types, &{humanize(&1), &1})
  end

  def status_options do
    Enum.map(@statuses, &{humanize(&1), &1})
  end

  def changeset(household, attrs) do
    household
    |> cast(attrs, [
      :name,
      :household_type,
      :status,
      :resident_count,
      :dependent_count,
      :servant_count,
      :description
    ])
    |> validate_required([:name, :household_type, :status, :world_id])
    |> validate_length(:name, max: 160)
    |> validate_length(:description, max: 4_000)
    |> validate_number(:resident_count, greater_than: 0)
    |> validate_number(:dependent_count, greater_than_or_equal_to: 0)
    |> validate_number(:servant_count, greater_than_or_equal_to: 0)
    |> validate_composition()
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:home_location_id)
    |> unique_constraint(:name, name: :households_world_id_name_index)
    |> check_constraint(:household_type, name: :households_type_check)
    |> check_constraint(:status, name: :households_status_check)
    |> check_constraint(:resident_count, name: :households_composition_complete)
    |> check_constraint(:resident_count, name: :households_composition_within_residents)
  end

  defp validate_composition(changeset) do
    residents = get_field(changeset, :resident_count)
    dependents = get_field(changeset, :dependent_count) || 0
    servants = get_field(changeset, :servant_count) || 0

    cond do
      is_nil(residents) && (dependents > 0 || servants > 0) ->
        add_error(changeset, :resident_count, "is required when composition counts are set")

      residents && dependents + servants > residents ->
        add_error(changeset, :resident_count, "dependents and servants cannot exceed residents")

      true ->
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
