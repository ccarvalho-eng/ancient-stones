defmodule AncientStones.Worlds.TaxRevenueShare do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.TaxPolicy

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tax_revenue_shares" do
    field :percentage, :decimal
    belongs_to :tax_policy, TaxPolicy
    belongs_to :political_office, PoliticalOffice
    timestamps(type: :utc_datetime)
  end

  def changeset(tax_revenue_share, attrs, refs \\ %{}) do
    tax_revenue_share
    |> cast(attrs, [:percentage])
    |> put_refs(refs)
    |> validate_required([:percentage, :tax_policy_id, :political_office_id])
    |> validate_number(:percentage, greater_than: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:tax_policy_id)
    |> foreign_key_constraint(:political_office_id)
    |> check_constraint(:percentage, name: :tax_revenue_shares_percentage)
    |> unique_constraint(:political_office_id,
      name: :tax_revenue_shares_tax_policy_id_political_office_id_index
    )
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
