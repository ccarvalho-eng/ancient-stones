defmodule AncientStones.Worlds.TimelineEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Timeline
  alias AncientStones.Worlds.TimelineEra

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "timeline_events" do
    field :name, :string
    field :year, :integer
    field :position, :integer
    field :description, :string

    belongs_to(:timeline, Timeline)
    belongs_to(:timeline_era, TimelineEra)

    timestamps(type: :utc_datetime)
  end

  def changeset(timeline_event, attrs) do
    timeline_event
    |> cast(attrs, [:name, :year, :position, :description])
    |> validate_required([:name, :position, :timeline_id])
    |> validate_number(:position, greater_than: 0)
    |> foreign_key_constraint(:timeline_id)
    |> foreign_key_constraint(:timeline_era_id)
    |> unique_constraint(:name, name: :timeline_events_timeline_id_name_index)
  end
end
