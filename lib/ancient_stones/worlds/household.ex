defmodule AncientStones.Worlds.Household do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.HouseholdMembership
  alias AncientStones.Worlds.Landholding
  alias AncientStones.Worlds.Location
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

    belongs_to :world, World
    belongs_to :home_location, Location
    has_many :memberships, HouseholdMembership
    has_many :members, through: [:memberships, :character]
    has_many :landholdings, Landholding

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
    |> cast(attrs, [:name, :household_type, :status, :description])
    |> validate_required([:name, :household_type, :status, :world_id])
    |> validate_length(:name, max: 160)
    |> validate_length(:description, max: 4_000)
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:home_location_id)
    |> unique_constraint(:name, name: :households_world_id_name_index)
    |> check_constraint(:household_type, name: :households_type_check)
    |> check_constraint(:status, name: :households_status_check)
  end

  defp humanize(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
