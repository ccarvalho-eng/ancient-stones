defmodule AncientStones.Worlds.Creature do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CreatureLocation
  alias AncientStones.Worlds.CreatureType
  alias AncientStones.Worlds.World

  @danger_level_options [
    {"High", "high"},
    {"Low", "low"},
    {"Medium", "medium"},
    {"Severe", "severe"}
  ]

  @temperament_options [
    {"Aggressive", "aggressive"},
    {"Docile", "docile"},
    {"Hostile", "hostile"},
    {"Neutral", "neutral"},
    {"Territorial", "territorial"}
  ]

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
    |> validate_inclusion(:temperament, option_values(@temperament_options))
    |> validate_inclusion(:danger_level, option_values(@danger_level_options))
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:creature_type_id)
    |> unique_constraint(:name, name: :creatures_world_id_name_index)
  end

  def temperament_options do
    @temperament_options
  end

  def danger_level_options do
    @danger_level_options
  end

  defp option_values(options) do
    Enum.map(options, fn {_label, value} -> value end)
  end
end
