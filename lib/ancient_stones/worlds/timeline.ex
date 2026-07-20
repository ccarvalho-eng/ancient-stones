defmodule AncientStones.Worlds.Timeline do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.TimelineEra
  alias AncientStones.Worlds.TimelineEvent
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "timelines" do
    field :name, :string
    field :description, :string

    belongs_to(:world, World)
    has_many(:eras, TimelineEra)
    has_many(:events, TimelineEvent)

    timestamps(type: :utc_datetime)
  end

  def changeset(timeline, attrs) do
    timeline
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :world_id])
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :timelines_world_id_name_index)
  end
end
