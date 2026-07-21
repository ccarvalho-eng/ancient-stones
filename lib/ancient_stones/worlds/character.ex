defmodule AncientStones.Worlds.Character do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CharacterInventoryCategory
  alias AncientStones.Worlds.CharacterInventoryItem
  alias AncientStones.Worlds.CharacterOccupation
  alias AncientStones.Worlds.CharacterRole
  alias AncientStones.Worlds.CharacterSkill
  alias AncientStones.Worlds.CharacterSpellbookEntry
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.GuildInfluence
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.LoreConnection
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses ~w(alive dead unknown)
  @genders ~w(female male)

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

  schema "characters" do
    field :name, :string
    field :gender, :string
    field :title, :string
    field :role, :string
    field :politics, :string
    field :status, :string
    field :health, :integer
    field :magicka, :integer
    field :stamina, :integer
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:character_role, CharacterRole)
    belongs_to(:race, Race)
    belongs_to(:guild, Guild)
    belongs_to(:home_location, Location)
    has_many(:character_occupations, CharacterOccupation)
    has_many(:character_skills, CharacterSkill)
    has_many(:inventory_categories, CharacterInventoryCategory)
    has_many(:inventory_items, CharacterInventoryItem)
    has_many(:spellbook_entries, CharacterSpellbookEntry)
    has_many(:guild_influences, GuildInfluence)
    has_many(:political_offices, PoliticalOffice)
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
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:character_role_id)
    |> foreign_key_constraint(:race_id)
    |> foreign_key_constraint(:guild_id)
    |> foreign_key_constraint(:home_location_id)
    |> unique_constraint(:name, name: :characters_world_id_name_index)
  end
end
