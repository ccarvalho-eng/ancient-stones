defmodule AncientStones.Worlds.Spell do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CharacterSpellbookEntry
  alias AncientStones.Worlds.World

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
    |> validate_number(:magicka_cost, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :spells_world_id_name_index)
  end
end
