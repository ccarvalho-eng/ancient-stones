defmodule AncientStones.Worlds.Character do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CharacterInventoryCategory
  alias AncientStones.Worlds.CharacterInventoryItem
  alias AncientStones.Worlds.CharacterLocation
  alias AncientStones.Worlds.CharacterOccupation
  alias AncientStones.Worlds.CharacterRole
  alias AncientStones.Worlds.CharacterSkill
  alias AncientStones.Worlds.CharacterSpellbookEntry
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.GuildMembership
  alias AncientStones.Worlds.GuildInfluence
  alias AncientStones.Worlds.HouseholdMembership
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.LoreConnection
  alias AncientStones.Worlds.CharacterRelationship
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses ~w(alive dead unknown)
  @genders ~w(female male)
  @social_statuses [
    :magnate,
    :freeholder,
    :tenant,
    :landless_free,
    :freed,
    :unfree,
    :outsider,
    :unknown
  ]
  @life_stages [:child, :adolescent, :adult, :elder, :unknown]
  @wealth_bands [:destitute, :poor, :modest, :comfortable, :wealthy, :exceptional, :unknown]

  def statuses do
    @statuses
  end

  def status_options do
    [
      {"Alive", "alive"},
      {"Dead", "dead"},
      {"Unknown", "unknown"}
    ]
  end

  def gender_options do
    [
      {"Female", "female"},
      {"Male", "male"}
    ]
  end

  def social_status_options do
    [
      {"Magnate", :magnate},
      {"Freeholder", :freeholder},
      {"Tenant", :tenant},
      {"Landless free", :landless_free},
      {"Freed person", :freed},
      {"Unfree", :unfree},
      {"Outsider", :outsider},
      {"Unknown", :unknown}
    ]
  end

  def life_stage_options do
    Enum.map(@life_stages, &{humanize(&1), &1})
  end

  def wealth_band_options do
    Enum.map(@wealth_bands, &{humanize(&1), &1})
  end

  schema "characters" do
    field :name, :string
    field :gender, :string
    field :title, :string
    field :role, :string
    field :politics, :string
    field :status, :string
    field :social_status, Ecto.Enum, values: @social_statuses
    field :life_stage, Ecto.Enum, values: @life_stages
    field :wealth_band, Ecto.Enum, values: @wealth_bands
    field :health, :integer
    field :magicka, :integer
    field :stamina, :integer
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:character_role, CharacterRole)
    belongs_to(:race, Race)
    belongs_to(:guild, Guild)
    has_many(:guild_memberships, GuildMembership)
    has_many(:guilds, through: [:guild_memberships, :guild])
    belongs_to(:home_location, Location)
    has_many(:character_locations, CharacterLocation)
    has_many(:locations, through: [:character_locations, :location])
    has_many(:character_occupations, CharacterOccupation)
    has_many(:character_skills, CharacterSkill)
    has_many(:inventory_categories, CharacterInventoryCategory)
    has_many(:inventory_items, CharacterInventoryItem)
    has_many(:spellbook_entries, CharacterSpellbookEntry)
    has_many(:guild_influences, GuildInfluence)
    has_many(:political_offices, PoliticalOffice)
    has_many(:household_memberships, HouseholdMembership)
    has_many(:households, through: [:household_memberships, :household])
    has_many(:relationships_as_a, CharacterRelationship, foreign_key: :character_a_id)
    has_many(:relationships_as_b, CharacterRelationship, foreign_key: :character_b_id)
    has_many(:source_lore_connections, LoreConnection, foreign_key: :source_character_id)
    has_many(:target_lore_connections, LoreConnection, foreign_key: :target_character_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :name,
      :gender,
      :title,
      :role,
      :politics,
      :status,
      :social_status,
      :life_stage,
      :wealth_band,
      :health,
      :magicka,
      :stamina,
      :description
    ])
    |> validate_required([:name, :world_id])
    |> validate_inclusion(:gender, @genders)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:health, greater_than_or_equal_to: 0)
    |> validate_number(:magicka, greater_than_or_equal_to: 0)
    |> validate_number(:stamina, greater_than_or_equal_to: 0)
    |> check_constraint(:status, name: :characters_status_valid)
    |> check_constraint(:gender, name: :characters_gender_valid)
    |> check_constraint(:social_status, name: :characters_social_status_check)
    |> check_constraint(:life_stage, name: :characters_life_stage_check)
    |> check_constraint(:wealth_band, name: :characters_wealth_band_check)
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:character_role_id)
    |> foreign_key_constraint(:race_id)
    |> foreign_key_constraint(:guild_id)
    |> foreign_key_constraint(:home_location_id)
    |> unique_constraint(:name, name: :characters_world_id_name_index)
  end

  defp humanize(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
