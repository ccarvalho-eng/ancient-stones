defmodule AncientStones.Worlds.Guild do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.GuildInfluence
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "guilds" do
    field :name, :string
    field :description, :string
    field :leader, :string
    field :headquarters, :string
    field :alignment, :string

    belongs_to(:world, World)
    has_many(:guild_influences, GuildInfluence)

    timestamps(type: :utc_datetime)
  end

  def changeset(guild, attrs) do
    guild
    |> cast(attrs, [:name, :description, :leader, :headquarters, :alignment])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :guilds_world_id_name_index)
  end
end
