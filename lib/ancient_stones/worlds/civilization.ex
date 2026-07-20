defmodule AncientStones.Worlds.Civilization do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CivilizationLocation
  alias AncientStones.Worlds.CivilizationRace
  alias AncientStones.Worlds.TimelineEra
  alias AncientStones.Worlds.World

  @status_options [
    {"Active", "active"},
    {"Fallen", "fallen"},
    {"Past", "past"},
    {"Ruined", "ruined"},
    {"Vanished", "vanished"}
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "civilizations" do
    field :name, :string
    field :era, :string
    field :status, :string
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:timeline_era, TimelineEra)
    has_many(:civilization_locations, CivilizationLocation)
    has_many(:civilization_races, CivilizationRace)
    has_many(:locations, through: [:civilization_locations, :location])
    has_many(:races, through: [:civilization_races, :race])

    timestamps(type: :utc_datetime)
  end

  def changeset(civilization, attrs) do
    civilization
    |> cast(attrs, [:name, :era, :status, :description])
    |> validate_required([:name, :world_id])
    |> validate_inclusion(:status, status_values())
    |> foreign_key_constraint(:timeline_era_id)
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :civilizations_world_id_name_index)
  end

  def status_options do
    @status_options
  end

  defp status_values do
    Enum.map(@status_options, fn {_label, value} -> value end)
  end
end
