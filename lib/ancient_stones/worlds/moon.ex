defmodule AncientStones.Worlds.Moon do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "moons" do
    field :name, :string
    field :description, :string
    field :orbital_period_days, :decimal
    field :semi_major_axis_km, :integer
    field :mean_radius_km, :integer
    field :mass_lunar, :decimal
    field :orbital_eccentricity, :decimal
    field :inclination_degrees, :decimal
    field :tidal_role, :string

    belongs_to :world, World

    timestamps(type: :utc_datetime)
  end

  def changeset(moon, attrs) do
    moon
    |> cast(attrs, [
      :name,
      :description,
      :orbital_period_days,
      :semi_major_axis_km,
      :mean_radius_km,
      :mass_lunar,
      :orbital_eccentricity,
      :inclination_degrees,
      :tidal_role
    ])
    |> validate_required([:name, :world_id])
    |> validate_number(:orbital_period_days, greater_than: 0)
    |> validate_number(:semi_major_axis_km, greater_than: 0)
    |> validate_number(:mean_radius_km, greater_than: 0)
    |> validate_number(:mass_lunar, greater_than: 0)
    |> validate_number(:orbital_eccentricity, greater_than_or_equal_to: 0, less_than: 1)
    |> validate_number(:inclination_degrees,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 180
    )
    |> foreign_key_constraint(:world_id)
    |> unique_constraint(:name, name: :moons_world_id_name_index)
    |> check_constraint(:orbital_period_days, name: :moons_physical_values_positive)
    |> check_constraint(:orbital_eccentricity, name: :moons_orbital_ranges)
  end
end
