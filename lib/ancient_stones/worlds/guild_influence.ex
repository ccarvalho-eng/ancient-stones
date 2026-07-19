defmodule AncientStones.Worlds.GuildInfluence do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "guild_influences" do
    field :relationship, :string
    field :description, :string

    belongs_to(:guild, Guild)
    belongs_to(:god, God)
    belongs_to(:character, Character)

    timestamps(type: :utc_datetime)
  end

  def changeset(guild_influence, attrs) do
    guild_influence
    |> cast(attrs, [:relationship, :description])
    |> validate_required([:guild_id, :relationship])
    |> foreign_key_constraint(:guild_id)
    |> foreign_key_constraint(:god_id)
    |> foreign_key_constraint(:character_id)
    |> check_constraint(:god_id, name: :guild_influences_one_target)
    |> unique_constraint(:relationship,
      name: :guild_influences_guild_id_god_id_relationship_index
    )
    |> unique_constraint(:relationship,
      name: :guild_influences_guild_id_character_id_relationship_index
    )
  end
end
