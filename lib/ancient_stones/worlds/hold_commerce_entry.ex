defmodule AncientStones.Worlds.HoldCommerceEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Hold

  @kind_options [
    {"Asset", "asset"},
    {"Expense", "expense"},
    {"Income", "income"},
    {"Liability", "liability"}
  ]
  @accounting_scopes [
    :gross_output,
    :net_local_income,
    :treasury_revenue,
    :treasury_outlay,
    :asset_value,
    :liability
  ]
  @coverage_scopes [:named_establishment, :partial_register, :estimated_total]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "hold_commerce_entries" do
    field :name, :string
    field :kind, :string
    field :category, :string
    field :amount, :integer
    field :currency, :string
    field :frequency, :string
    field :accounting_scope, Ecto.Enum, values: @accounting_scopes
    field :coverage_scope, Ecto.Enum, values: @coverage_scopes
    field :description, :string

    belongs_to(:hold, Hold)

    timestamps(type: :utc_datetime)
  end

  def changeset(hold_commerce_entry, attrs) do
    hold_commerce_entry
    |> cast(attrs, [
      :name,
      :kind,
      :category,
      :amount,
      :currency,
      :frequency,
      :accounting_scope,
      :coverage_scope,
      :description
    ])
    |> validate_required([:name, :kind, :hold_id])
    |> validate_inclusion(:kind, kind_values())
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:hold_id)
    |> unique_constraint(:name, name: :hold_commerce_entries_hold_id_name_index)
  end

  def kind_options do
    @kind_options
  end

  def accounting_scope_options do
    options(@accounting_scopes)
  end

  def coverage_scope_options do
    options(@coverage_scopes)
  end

  defp options(values) do
    Enum.map(values, fn value ->
      label = value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
      {label, value}
    end)
  end

  defp kind_values do
    Enum.map(@kind_options, fn {_label, value} -> value end)
  end
end
