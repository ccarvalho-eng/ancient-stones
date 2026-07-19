defmodule AncientStones.Worlds.HoldCommerceEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Hold

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "hold_commerce_entries" do
    field :name, :string
    field :kind, :string
    field :category, :string
    field :amount, :integer
    field :currency, :string
    field :frequency, :string
    field :description, :string

    belongs_to(:hold, Hold)

    timestamps(type: :utc_datetime)
  end

  def changeset(hold_commerce_entry, attrs) do
    hold_commerce_entry
    |> cast(attrs, [:name, :kind, :category, :amount, :currency, :frequency, :description])
    |> validate_required([:name, :kind, :hold_id])
    |> validate_inclusion(:kind, ["income", "expense", "asset", "liability"])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:hold_id)
    |> unique_constraint(:name, name: :hold_commerce_entries_hold_id_name_index)
  end
end
