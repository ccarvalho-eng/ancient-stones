defmodule AncientStone.Worlds.Province do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStone.Worlds.Continent
  alias AncientStone.Worlds.Hold

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "provinces" do
    field :name, :string
    field :description, :string

    belongs_to(:continent, Continent)
    has_many(:holds, Hold)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(province, attrs) do
    province
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :continent_id])
    |> foreign_key_constraint(:continent_id)
    |> unique_constraint(:name, name: :provinces_continent_id_name_index)
  end
end
