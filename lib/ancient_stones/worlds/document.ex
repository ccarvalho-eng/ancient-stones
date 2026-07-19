defmodule AncientStones.Worlds.Document do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "documents" do
    field :title, :string
    field :kind, :string
    field :source, :string
    field :summary, :string
    field :content, :string

    belongs_to(:world, World)
    belongs_to(:author_character, Character)
    belongs_to(:location, Location)
    belongs_to(:guild, Guild)
    belongs_to(:god, God)
    belongs_to(:race, Race)
    belongs_to(:civilization, Civilization)

    timestamps(type: :utc_datetime)
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [:title, :kind, :source, :summary, :content])
    |> validate_required([:title, :world_id])
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:author_character_id)
    |> foreign_key_constraint(:location_id)
    |> foreign_key_constraint(:guild_id)
    |> foreign_key_constraint(:god_id)
    |> foreign_key_constraint(:race_id)
    |> foreign_key_constraint(:civilization_id)
    |> unique_constraint(:title, name: :documents_world_id_title_index)
  end
end
