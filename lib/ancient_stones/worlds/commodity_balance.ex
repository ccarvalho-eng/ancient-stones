defmodule AncientStones.Worlds.CommodityBalance do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Hold

  @statuses [:active, :provisional, :historical]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "commodity_balances" do
    field :commodity, :string
    field :category, :string
    field :unit, :string
    field :annual_output, :decimal
    field :annual_local_need, :decimal
    field :stored_reserve, :decimal, default: 0
    field :bad_year_output_percentage, :decimal
    field :storage_loss_percentage, :decimal, default: 0
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :description, :string
    belongs_to :hold, Hold
    timestamps(type: :utc_datetime)
  end

  def changeset(balance, attrs) do
    balance
    |> cast(attrs, [
      :commodity,
      :category,
      :unit,
      :annual_output,
      :annual_local_need,
      :stored_reserve,
      :bad_year_output_percentage,
      :storage_loss_percentage,
      :status,
      :description
    ])
    |> validate_required([
      :commodity,
      :unit,
      :annual_output,
      :annual_local_need,
      :stored_reserve,
      :bad_year_output_percentage,
      :storage_loss_percentage,
      :status,
      :hold_id
    ])
    |> validate_number(:annual_output, greater_than_or_equal_to: 0)
    |> validate_number(:annual_local_need, greater_than_or_equal_to: 0)
    |> validate_number(:stored_reserve, greater_than_or_equal_to: 0)
    |> validate_number(:bad_year_output_percentage,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    |> validate_number(:storage_loss_percentage,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    |> foreign_key_constraint(:hold_id)
    |> check_constraint(:annual_output, name: :commodity_balances_amounts_non_negative)
    |> check_constraint(:bad_year_output_percentage,
      name: :commodity_balances_bad_year_percentage
    )
    |> check_constraint(:storage_loss_percentage,
      name: :commodity_balances_storage_loss_percentage
    )
    |> unique_constraint([:hold_id, :commodity, :unit])
  end

  def ordinary_balance(%__MODULE__{} = balance) do
    Decimal.sub(balance.annual_output, balance.annual_local_need)
  end

  def bad_year_output(%__MODULE__{} = balance) do
    Decimal.mult(balance.annual_output, Decimal.div(balance.bad_year_output_percentage, 100))
  end

  def status_options do
    Enum.map(@statuses, fn status ->
      {status |> Atom.to_string() |> String.capitalize(), status}
    end)
  end
end
