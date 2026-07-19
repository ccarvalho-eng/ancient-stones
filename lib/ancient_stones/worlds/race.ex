defmodule AncientStones.Worlds.Race do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CivilizationRace
  alias AncientStones.Worlds.RaceTrait
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "races" do
    field :name, :string
    field :description, :string

    has_many(:civilization_races, CivilizationRace)
    has_many(:civilizations, through: [:civilization_races, :civilization])
    belongs_to(:world, World)
    has_many(:traits, RaceTrait)

    timestamps(type: :utc_datetime)
  end

  def changeset(race, attrs) do
    race
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :races_world_id_name_index)
  end
end
