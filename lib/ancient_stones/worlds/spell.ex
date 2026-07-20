defmodule AncientStones.Worlds.Spell do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CharacterSpellbookEntry
  alias AncientStones.Worlds.World

  @level_options [
    {"Adept", "Adept"},
    {"Apprentice", "Apprentice"},
    {"Expert", "Expert"},
    {"Master", "Master"},
    {"N/A", "N/A"},
    {"Novice", "Novice"}
  ]

  @school_options [
    {"Alteration", "Alteration"},
    {"Conjuration", "Conjuration"},
    {"Destruction", "Destruction"},
    {"Illusion", "Illusion"},
    {"Restoration", "Restoration"}
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "spells" do
    field :name, :string
    field :school, :string
    field :level, :string
    field :magicka_cost, :integer
    field :source, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:character_spellbook_entries, CharacterSpellbookEntry)

    timestamps(type: :utc_datetime)
  end

  def changeset(spell, attrs) do
    spell
    |> cast(attrs, [:name, :school, :level, :magicka_cost, :source, :description])
    |> validate_required([:name, :world_id])
    |> validate_inclusion(:school, option_values(@school_options))
    |> validate_inclusion(:level, option_values(@level_options))
    |> validate_number(:magicka_cost, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :spells_world_id_name_index)
  end

  def school_options do
    @school_options
  end

  def level_options do
    @level_options
  end

  defp option_values(options) do
    Enum.map(options, fn {_label, value} -> value end)
  end
end
