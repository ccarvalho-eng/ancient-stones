defmodule AncientStones.Worlds.HoldEconomicProfile do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Hold

  @confidences [:low, :medium, :high]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "hold_economic_profiles" do
    field :population_estimate, :integer
    field :household_estimate, :integer
    field :urban_population_estimate, :integer, default: 0
    field :arable_hectares_estimate, :decimal
    field :pasture_hectares_estimate, :decimal
    field :staple_reserve_months, :decimal
    field :assessment_label, :string
    field :confidence, Ecto.Enum, values: @confidences, default: :medium
    field :description, :string
    belongs_to :hold, Hold
    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :population_estimate,
      :household_estimate,
      :urban_population_estimate,
      :arable_hectares_estimate,
      :pasture_hectares_estimate,
      :staple_reserve_months,
      :assessment_label,
      :confidence,
      :description
    ])
    |> validate_required([
      :population_estimate,
      :household_estimate,
      :urban_population_estimate,
      :assessment_label,
      :confidence,
      :hold_id
    ])
    |> validate_number(:population_estimate, greater_than_or_equal_to: 0)
    |> validate_number(:household_estimate, greater_than_or_equal_to: 0)
    |> validate_number(:urban_population_estimate, greater_than_or_equal_to: 0)
    |> validate_number(:arable_hectares_estimate, greater_than_or_equal_to: 0)
    |> validate_number(:pasture_hectares_estimate, greater_than_or_equal_to: 0)
    |> validate_number(:staple_reserve_months, greater_than_or_equal_to: 0)
    |> validate_urban_population()
    |> foreign_key_constraint(:hold_id)
    |> check_constraint(:population_estimate,
      name: :hold_economic_profiles_population_non_negative
    )
    |> check_constraint(:household_estimate,
      name: :hold_economic_profiles_households_non_negative
    )
    |> check_constraint(:urban_population_estimate,
      name: :hold_economic_profiles_urban_non_negative
    )
    |> check_constraint(:urban_population_estimate,
      name: :hold_economic_profiles_urban_within_population
    )
    |> check_constraint(:arable_hectares_estimate,
      name: :hold_economic_profiles_land_non_negative
    )
    |> check_constraint(:staple_reserve_months,
      name: :hold_economic_profiles_reserves_non_negative
    )
    |> unique_constraint(:hold_id)
  end

  def confidence_options do
    Enum.map(@confidences, fn confidence ->
      {confidence |> Atom.to_string() |> String.capitalize(), confidence}
    end)
  end

  defp validate_urban_population(changeset) do
    population = get_field(changeset, :population_estimate)
    urban_population = get_field(changeset, :urban_population_estimate)

    if population && urban_population && urban_population > population do
      add_error(changeset, :urban_population_estimate, "cannot exceed total population")
    else
      changeset
    end
  end
end
