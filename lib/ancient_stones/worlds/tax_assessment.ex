defmodule AncientStones.Worlds.TaxAssessment do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.ContinentCurrency
  alias AncientStones.Worlds.TaxPolicy

  @confidences [:low, :medium, :high]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tax_assessments" do
    field :assessment_period_label, :string
    field :cash_yield, :decimal, default: 0
    field :in_kind_value, :decimal, default: 0
    field :customary_labor_days, :integer, default: 0
    field :confidence, Ecto.Enum, values: @confidences, default: :medium
    field :assessed_unit, :string
    field :assessed_unit_count, :decimal
    field :coverage_percentage, :decimal
    field :valuation_basis, :string
    field :description, :string
    belongs_to :tax_policy, TaxPolicy
    belongs_to :currency, ContinentCurrency
    timestamps(type: :utc_datetime)
  end

  def changeset(assessment, attrs, refs \\ %{}) do
    assessment
    |> cast(attrs, [
      :assessment_period_label,
      :cash_yield,
      :in_kind_value,
      :customary_labor_days,
      :confidence,
      :assessed_unit,
      :assessed_unit_count,
      :coverage_percentage,
      :valuation_basis,
      :description
    ])
    |> put_refs(refs)
    |> validate_required([
      :assessment_period_label,
      :cash_yield,
      :in_kind_value,
      :customary_labor_days,
      :confidence,
      :tax_policy_id,
      :currency_id
    ])
    |> validate_number(:cash_yield, greater_than_or_equal_to: 0)
    |> validate_number(:in_kind_value, greater_than_or_equal_to: 0)
    |> validate_number(:customary_labor_days, greater_than_or_equal_to: 0)
    |> validate_number(:assessed_unit_count, greater_than: 0)
    |> validate_number(:coverage_percentage,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    |> foreign_key_constraint(:tax_policy_id)
    |> foreign_key_constraint(:currency_id)
    |> check_constraint(:cash_yield, name: :tax_assessments_values_non_negative)
    |> check_constraint(:assessed_unit_count, name: :tax_assessments_coverage)
    |> unique_constraint([:tax_policy_id, :assessment_period_label])
  end

  def confidence_options do
    Enum.map(@confidences, fn confidence ->
      {confidence |> Atom.to_string() |> String.capitalize(), confidence}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc ->
      put_change(acc, field, value)
    end)
  end
end
