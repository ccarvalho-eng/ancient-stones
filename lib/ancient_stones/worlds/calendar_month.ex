defmodule AncientStones.Worlds.CalendarMonth do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Calendar

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "calendar_months" do
    field :name, :string
    field :days, :integer
    field :position, :integer

    belongs_to(:calendar, Calendar)

    timestamps(type: :utc_datetime)
  end

  def changeset(calendar_month, attrs) do
    calendar_month
    |> cast(attrs, [:name, :days, :position])
    |> validate_required([:name, :days, :position, :calendar_id])
    |> validate_number(:days, greater_than: 0)
    |> validate_number(:position, greater_than: 0)
    |> foreign_key_constraint(:calendar_id)
    |> unique_constraint(:name, name: :calendar_months_calendar_id_name_index)
    |> unique_constraint(:position, name: :calendar_months_calendar_id_position_index)
  end
end
