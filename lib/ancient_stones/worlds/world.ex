defmodule AncientStones.Worlds.World do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CharacterRole
  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.CreatureType
  alias AncientStones.Worlds.Document
  alias AncientStones.Galaxies.Galaxy
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.Item
  alias AncientStones.Worlds.Effect
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.Occupation
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.LoreConnection
  alias AncientStones.Worlds.Skill
  alias AncientStones.Worlds.SkillTree
  alias AncientStones.Worlds.Spell
  alias AncientStones.Worlds.Timeline

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "worlds" do
    field :name, :string
    field :description, :string
    field :primary_star_name, :string
    field :orbital_period_days, :integer
    field :axial_tilt_degrees, :decimal

    belongs_to(:galaxy, Galaxy)

    has_many(:characters, Character)
    has_many(:character_roles, CharacterRole)
    has_many(:civilizations, Civilization)
    has_many(:continents, Continent)
    has_many(:creature_types, CreatureType)
    has_many(:creatures, Creature)
    has_many(:documents, Document)
    has_many(:gods, God)
    has_many(:guilds, Guild)
    has_many(:items, Item)
    has_many(:effects, Effect)
    has_many(:location_types, LocationType)
    has_many(:occupations, Occupation)
    has_many(:political_offices, PoliticalOffice)
    has_many(:races, Race)
    has_many(:lore_connections, LoreConnection)
    has_many(:skills, Skill)
    has_many(:skill_trees, SkillTree)
    has_many(:spells, Spell)
    has_many(:timelines, Timeline)
    has_many(:timeline_events, through: [:timelines, :events])

    timestamps(type: :utc_datetime)
  end

  def changeset(world, attrs) do
    world
    |> cast(attrs, [
      :name,
      :description,
      :primary_star_name,
      :orbital_period_days,
      :axial_tilt_degrees
    ])
    |> validate_required([:name])
    |> validate_number(:orbital_period_days, greater_than: 0)
    |> validate_number(:axial_tilt_degrees,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 90
    )
    |> foreign_key_constraint(:galaxy_id)
  end
end
