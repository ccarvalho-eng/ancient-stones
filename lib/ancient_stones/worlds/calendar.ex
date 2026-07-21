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
    field :year_start_angle, :decimal
    field :perihelion_day, :integer

    belongs_to(:continent, Continent)
    has_many(:months, CalendarMonth)

    timestamps(type: :utc_datetime)
  end

  def changeset(calendar, attrs) do
    calendar
    |> cast(attrs, [
      :name,
      :description,
      :days_per_week,
      :era,
      :year_start_angle,
      :perihelion_day
    ])
    |> validate_required([:name, :continent_id])
    |> validate_number(:days_per_week, greater_than: 0)
    |> validate_number(:year_start_angle, greater_than_or_equal_to: 0, less_than: 360)
    |> validate_number(:perihelion_day, greater_than: 0)
    |> foreign_key_constraint(:continent_id)
    |> unique_constraint(:name, name: :calendars_continent_id_name_index)
  end
end
