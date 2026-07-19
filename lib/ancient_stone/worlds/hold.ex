defmodule AncientStone.Worlds.Hold do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStone.Worlds.Province

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "holds" do
    field :name, :string
    field :description, :string

    belongs_to(:province, Province)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hold, attrs) do
    hold
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :province_id])
    |> foreign_key_constraint(:province_id)
    |> unique_constraint(:name, name: :holds_province_id_name_index)
  end
end
