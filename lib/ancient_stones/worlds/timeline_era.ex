defmodule AncientStones.Worlds.TimelineEra do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.Timeline
  alias AncientStones.Worlds.TimelineEvent

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "timeline_eras" do
    field :name, :string
    field :abbreviation, :string
    field :position, :integer
    field :starts_at_year, :integer
    field :ends_at_year, :integer
    field :description, :string

    belongs_to(:timeline, Timeline)
    has_many(:civilizations, Civilization)
    has_many(:events, TimelineEvent)

    timestamps(type: :utc_datetime)
  end

  def changeset(timeline_era, attrs) do
    timeline_era
    |> cast(attrs, [
      :name,
      :abbreviation,
      :position,
      :starts_at_year,
      :ends_at_year,
      :description
    ])
    |> validate_required([:name, :position, :timeline_id])
    |> validate_number(:position, greater_than: 0)
    |> foreign_key_constraint(:timeline_id)
    |> unique_constraint(:name, name: :timeline_eras_timeline_id_name_index)
    |> unique_constraint(:position, name: :timeline_eras_timeline_id_position_index)
  end
end
