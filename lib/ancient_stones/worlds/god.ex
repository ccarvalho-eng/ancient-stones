defmodule AncientStones.Worlds.God do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.GuildInfluence
  alias AncientStones.Worlds.Relationship
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gods" do
    field :name, :string
    field :pantheon, :string
    field :domain, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:guild_influences, GuildInfluence)
    has_many(:source_relationships, Relationship, foreign_key: :source_god_id)
    has_many(:target_relationships, Relationship, foreign_key: :target_god_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(god, attrs) do
    god
    |> cast(attrs, [:name, :pantheon, :domain, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :gods_world_id_name_index)
  end
end
