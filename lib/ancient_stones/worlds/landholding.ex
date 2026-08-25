defmodule AncientStones.Worlds.Landholding do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Household
  alias AncientStones.Worlds.Location

  @tenure_types [
    :allodial,
    :customary,
    :leasehold,
    :granted,
    :communal_right,
    :usufruct,
    :disputed,
    :other
  ]
  @primary_uses [
    :residence,
    :farming,
    :pasture,
    :woodland,
    :fishing,
    :mining,
    :quarrying,
    :workshop,
    :trade,
    :ritual,
    :mixed,
    :other
  ]
  @statuses [:active, :disputed, :abandoned, :transferred, :historical]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "landholdings" do
    field :name, :string
    field :tenure_type, Ecto.Enum, values: @tenure_types
    field :primary_use, Ecto.Enum, values: @primary_uses, default: :mixed
    field :size_hectares, :decimal
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :description, :string

    belongs_to :household, Household
    belongs_to :hold, Hold
    belongs_to :location, Location

    timestamps(type: :utc_datetime)
  end

  def tenure_type_options do
    Enum.map(@tenure_types, &{humanize_tenure(&1), &1})
  end

  def primary_use_options do
    Enum.map(@primary_uses, &{humanize(&1), &1})
  end

  def status_options do
    Enum.map(@statuses, &{humanize(&1), &1})
  end

  def changeset(landholding, attrs) do
    landholding
    |> cast(attrs, [:name, :tenure_type, :primary_use, :size_hectares, :status, :description])
    |> validate_required([:name, :tenure_type, :primary_use, :status, :household_id])
    |> validate_length(:name, max: 160)
    |> validate_length(:description, max: 4_000)
    |> validate_number(:size_hectares, greater_than: 0)
    |> foreign_key_constraint(:household_id)
    |> foreign_key_constraint(:hold_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint(:name, name: :landholdings_household_id_name_index)
    |> check_constraint(:hold_id,
      name: :landholdings_single_geographic_scope,
      message: "select either a hold or a location"
    )
    |> check_constraint(:size_hectares, name: :landholdings_size_positive)
    |> check_constraint(:tenure_type, name: :landholdings_tenure_type_check)
    |> check_constraint(:primary_use, name: :landholdings_primary_use_check)
    |> check_constraint(:status, name: :landholdings_status_check)
  end

  defp humanize_tenure(:allodial), do: "Allodial (odal)"
  defp humanize_tenure(:communal_right), do: "Communal use right"
  defp humanize_tenure(value), do: humanize(value)

  defp humanize(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
