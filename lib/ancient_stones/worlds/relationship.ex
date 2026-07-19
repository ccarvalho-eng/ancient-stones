defmodule AncientStones.Worlds.Relationship do
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

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "relationships" do
    field :name, :string
    field :relationship_type, :string
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

  def changeset(relationship, attrs) do
    relationship
    |> cast(attrs, [:name, :relationship_type, :status, :started_at, :ended_at, :description])
    |> validate_required([:relationship_type, :world_id])
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraints()
    |> check_constraint(:source_character_id, name: :relationships_one_source)
    |> check_constraint(:target_character_id, name: :relationships_one_target)
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
