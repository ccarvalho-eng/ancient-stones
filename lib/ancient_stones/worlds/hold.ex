defmodule AncientStones.Worlds.Hold do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Geography
  alias AncientStones.Worlds.HoldCommerceEntry
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Province

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "holds" do
    field :name, :string
    field :description, :string
    field :terrain, Ecto.Enum, values: Geography.terrain_values()
    field :climate, Ecto.Enum, values: Geography.climate_values()
    field :map_x, :integer
    field :map_y, :integer
    field :visibility, Ecto.Enum, values: Geography.visibility_values(), default: :known

    belongs_to(:province, Province)
    belongs_to(:capital_location, Location)
    has_many(:locations, Location)
    has_many(:commerce_entries, HoldCommerceEntry)
    has_many(:political_offices, PoliticalOffice)

    timestamps(type: :utc_datetime)
  end

  def changeset(hold, attrs) do
    hold
    |> cast(attrs, [:name, :description, :terrain, :climate, :map_x, :map_y, :visibility])
    |> validate_required([:name, :province_id])
    |> foreign_key_constraint(:province_id)
    |> foreign_key_constraint(:capital_location_id)
    |> unique_constraint(:name, name: :holds_province_id_name_index)
  end
end
