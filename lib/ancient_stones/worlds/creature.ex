defmodule AncientStones.Worlds.Creature do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CreatureLocation
  alias AncientStones.Worlds.CreatureType
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "creatures" do
    field :name, :string
    field :habitat, :string
    field :temperament, :string
    field :danger_level, :string
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:creature_type, CreatureType)
    has_many(:creature_locations, CreatureLocation)
    has_many(:locations, through: [:creature_locations, :location])

    timestamps(type: :utc_datetime)
  end

  def changeset(creature, attrs) do
    creature
    |> cast(attrs, [:name, :habitat, :temperament, :danger_level, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:creature_type_id)
    |> unique_constraint(:name, name: :creatures_world_id_name_index)
  end
end
