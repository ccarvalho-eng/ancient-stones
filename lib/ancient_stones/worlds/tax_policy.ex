defmodule AncientStones.Worlds.TaxPolicy do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.ContinentCurrency
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.TaxExemption
  alias AncientStones.Worlds.TaxRevenueShare
  alias AncientStones.Worlds.World

  @tax_types [
    :import_tariff,
    :export_duty,
    :road_toll,
    :harbor_due,
    :market_fee,
    :land_levy,
    :tribute,
    :excise
  ]
  @rate_bases [:percentage, :per_unit, :fixed]
  @directions [:any, :import, :export, :internal]
  @statuses [:draft, :active, :retired]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tax_policies" do
    field :name, :string
    field :tax_type, Ecto.Enum, values: @tax_types
    field :rate_basis, Ecto.Enum, values: @rate_bases
    field :rate, :decimal
    field :commodity, :string
    field :category, :string
    field :direction, Ecto.Enum, values: @directions, default: :any
    field :effective_from, :date
    field :effective_to, :date
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :description, :string
    belongs_to :world, World
    belongs_to :continent, Continent
    belongs_to :province, Province
    belongs_to :hold, Hold
    belongs_to :collecting_office, PoliticalOffice
    belongs_to :currency, ContinentCurrency
    has_many :tax_exemptions, TaxExemption
    has_many :revenue_shares, TaxRevenueShare
    timestamps(type: :utc_datetime)
  end

  def changeset(tax_policy, attrs, refs \\ %{}) do
    tax_policy
    |> cast(attrs, [
      :name,
      :tax_type,
      :rate_basis,
      :rate,
      :commodity,
      :category,
      :direction,
      :effective_from,
      :effective_to,
      :status,
      :description
    ])
    |> put_refs(refs)
    |> validate_required([:name, :tax_type, :rate_basis, :rate, :direction, :status, :world_id])
    |> validate_number(:rate, greater_than_or_equal_to: 0)
    |> validate_percentage_rate()
    |> validate_currency_for_rate_basis()
    |> validate_date_order()
    |> validate_single_jurisdiction()
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:continent_id)
    |> foreign_key_constraint(:province_id)
    |> foreign_key_constraint(:hold_id)
    |> foreign_key_constraint(:collecting_office_id)
    |> foreign_key_constraint(:currency_id)
    |> check_constraint(:jurisdiction, name: :tax_policies_single_jurisdiction)
    |> check_constraint(:rate, name: :tax_policies_rate_non_negative)
    |> check_constraint(:rate, name: :tax_policies_percentage_rate)
    |> check_constraint(:effective_to, name: :tax_policies_effective_dates)
    |> unique_constraint(:name, name: :tax_policies_world_id_name_index)
  end

  def tax_type_options do
    options(@tax_types)
  end

  def rate_basis_options do
    options(@rate_bases)
  end

  def direction_options do
    options(@directions)
  end

  def status_options do
    options(@statuses)
  end

  defp validate_percentage_rate(changeset) do
    if get_field(changeset, :rate_basis) == :percentage do
      validate_number(changeset, :rate, less_than_or_equal_to: 100)
    else
      changeset
    end
  end

  defp validate_currency_for_rate_basis(changeset) do
    rate_basis = get_field(changeset, :rate_basis)
    currency_id = get_field(changeset, :currency_id)

    if rate_basis in [:per_unit, :fixed] && is_nil(currency_id) do
      add_error(changeset, :currency_id, "is required for fixed and per-unit taxes")
    else
      changeset
    end
  end

  defp validate_date_order(changeset) do
    from = get_field(changeset, :effective_from)
    to = get_field(changeset, :effective_to)

    if from && to && Date.before?(to, from) do
      add_error(changeset, :effective_to, "must be on or after the effective start date")
    else
      changeset
    end
  end

  defp validate_single_jurisdiction(changeset) do
    count =
      Enum.count([:continent_id, :province_id, :hold_id], &(not is_nil(get_field(changeset, &1))))

    if count == 1 do
      changeset
    else
      add_error(changeset, :jurisdiction, "must select exactly one jurisdiction")
    end
  end

  defp options(values) do
    Enum.map(values, fn value ->
      label = value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
      {label, value}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
