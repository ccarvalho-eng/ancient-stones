defmodule AncientStones.Worlds.TaxExemption do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.TaxPolicy
  alias AncientStones.Worlds.TradeRoute

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tax_exemptions" do
    field :name, :string
    field :exemption_percentage, :decimal, default: Decimal.new(100)
    field :effective_from, :date
    field :effective_to, :date
    field :description, :string
    belongs_to :tax_policy, TaxPolicy
    belongs_to :guild, Guild
    belongs_to :trade_route, TradeRoute
    belongs_to :continent, Continent
    belongs_to :province, Province
    belongs_to :hold, Hold
    timestamps(type: :utc_datetime)
  end

  def changeset(tax_exemption, attrs, refs \\ %{}) do
    tax_exemption
    |> cast(attrs, [:name, :exemption_percentage, :effective_from, :effective_to, :description])
    |> put_refs(refs)
    |> validate_required([:name, :exemption_percentage, :tax_policy_id])
    |> validate_number(:exemption_percentage,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    |> validate_date_order()
    |> validate_single_beneficiary()
    |> foreign_key_constraint(:tax_policy_id)
    |> foreign_key_constraint(:guild_id)
    |> foreign_key_constraint(:trade_route_id)
    |> foreign_key_constraint(:continent_id)
    |> foreign_key_constraint(:province_id)
    |> foreign_key_constraint(:hold_id)
    |> check_constraint(:beneficiary, name: :tax_exemptions_single_beneficiary)
    |> check_constraint(:exemption_percentage, name: :tax_exemptions_percentage)
    |> check_constraint(:effective_to, name: :tax_exemptions_effective_dates)
    |> unique_constraint(:name, name: :tax_exemptions_tax_policy_id_name_index)
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

  defp validate_single_beneficiary(changeset) do
    fields = [:guild_id, :trade_route_id, :continent_id, :province_id, :hold_id]
    count = Enum.count(fields, &(not is_nil(get_field(changeset, &1))))

    if count == 1 do
      changeset
    else
      add_error(changeset, :beneficiary, "must select exactly one beneficiary")
    end
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
