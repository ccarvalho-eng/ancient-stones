defmodule AncientStones.Worlds.LoreConnection do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.World

  @connection_type_options [
    {"Ally", "ally"},
    {"Controls", "controls"},
    {"Criminal Contact", "criminal contact"},
    {"Historical Tie", "historical tie"},
    {"Leader", "leader"},
    {"Member", "member"},
    {"Opposes", "opposes"},
    {"Patron", "patron"},
    {"Rival", "rival"},
    {"Serves", "serves"},
    {"Teacher At", "teacher at"},
    {"Trade", "trade"},
    {"Worships", "worships"}
  ]

  @status_options [
    {"Active", "active"},
    {"Broken", "broken"},
    {"Hidden", "hidden"},
    {"Historical", "historical"},
    {"Rumored", "rumored"},
    {"Tense", "tense"}
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "lore_connections" do
    field :name, :string
    field :connection_type, :string
    field :status, :string
    field :started_at, :string
    field :ended_at, :string
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:source_character, Character)
    belongs_to(:source_guild, Guild)
    belongs_to(:source_god, God)
    belongs_to(:source_race, Race)
    belongs_to(:source_civilization, Civilization)
    belongs_to(:source_location, Location)
    belongs_to(:source_hold, Hold)
    belongs_to(:source_province, Province)
    belongs_to(:source_continent, Continent)
    belongs_to(:target_character, Character)
    belongs_to(:target_guild, Guild)
    belongs_to(:target_god, God)
    belongs_to(:target_race, Race)
    belongs_to(:target_civilization, Civilization)
    belongs_to(:target_location, Location)
    belongs_to(:target_hold, Hold)
    belongs_to(:target_province, Province)
    belongs_to(:target_continent, Continent)

    timestamps(type: :utc_datetime)
  end

  def changeset(lore_connection, attrs) do
    lore_connection
    |> cast(attrs, [:name, :connection_type, :status, :started_at, :ended_at, :description])
    |> validate_required([:connection_type, :world_id])
    |> validate_inclusion(:connection_type, connection_type_values())
    |> validate_inclusion(:status, status_values())
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraints()
    |> check_constraint(:source_character_id, name: :lore_connections_one_source)
    |> check_constraint(:target_character_id, name: :lore_connections_one_target)
  end

  def connection_type_options do
    @connection_type_options
  end

  def status_options do
    @status_options
  end

  defp connection_type_values do
    Enum.map(@connection_type_options, fn {_label, value} -> value end)
  end

  defp status_values do
    Enum.map(@status_options, fn {_label, value} -> value end)
  end

  defp foreign_key_constraints(changeset) do
    changeset
    |> foreign_key_constraint(:source_character_id)
    |> foreign_key_constraint(:source_guild_id)
    |> foreign_key_constraint(:source_god_id)
    |> foreign_key_constraint(:source_race_id)
    |> foreign_key_constraint(:source_civilization_id)
    |> foreign_key_constraint(:source_location_id)
    |> foreign_key_constraint(:source_hold_id)
    |> foreign_key_constraint(:source_province_id)
    |> foreign_key_constraint(:source_continent_id)
    |> foreign_key_constraint(:target_character_id)
    |> foreign_key_constraint(:target_guild_id)
    |> foreign_key_constraint(:target_god_id)
    |> foreign_key_constraint(:target_race_id)
    |> foreign_key_constraint(:target_civilization_id)
    |> foreign_key_constraint(:target_location_id)
    |> foreign_key_constraint(:target_hold_id)
    |> foreign_key_constraint(:target_province_id)
    |> foreign_key_constraint(:target_continent_id)
  end
end
