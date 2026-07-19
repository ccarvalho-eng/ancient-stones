defmodule AncientStones.Worlds.CharacterSpellbookEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Spell

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "character_spellbook_entries" do
    field :favorite, :boolean
    field :notes, :string

    belongs_to(:character, Character)
    belongs_to(:spell, Spell)

    timestamps(type: :utc_datetime)
  end

  def changeset(spellbook_entry, attrs) do
    spellbook_entry
    |> cast(attrs, [:favorite, :notes])
    |> validate_required([:character_id, :spell_id])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:spell_id)
    |> unique_constraint(:spell_id,
      name: :character_spellbook_entries_character_id_spell_id_index
    )
  end
end
