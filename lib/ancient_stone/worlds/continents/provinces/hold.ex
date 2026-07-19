defmodule AncientStone.Worlds.Continents.Provinces.Hold do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStone.Worlds.Continents.Province

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
    |> cast(attrs, [:name, :description, :province_id])
    |> validate_required([:name, :province_id])
  end
end
