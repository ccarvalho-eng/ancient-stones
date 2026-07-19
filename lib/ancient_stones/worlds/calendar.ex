defmodule AncientStones.Worlds.Calendar do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.CalendarMonth
  alias AncientStones.Worlds.Continent

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "calendars" do
    field :name, :string
    field :description, :string
    field :days_per_week, :integer
    field :era, :string

    belongs_to(:continent, Continent)
    has_many(:months, CalendarMonth)

    timestamps(type: :utc_datetime)
  end

  def changeset(calendar, attrs) do
    calendar
    |> cast(attrs, [:name, :description, :days_per_week, :era])
    |> validate_required([:name, :continent_id])
    |> validate_number(:days_per_week, greater_than: 0)
    |> foreign_key_constraint(:continent_id)
    |> unique_constraint(:name, name: :calendars_continent_id_name_index)
  end
end
