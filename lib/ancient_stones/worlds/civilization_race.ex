defmodule AncientStones.Worlds.CivilizationRace do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.Race

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "civilization_races" do
    field :relationship, :string
    field :description, :string

    belongs_to(:civilization, Civilization)
    belongs_to(:race, Race)

    timestamps(type: :utc_datetime)
  end

  def changeset(civilization_race, attrs) do
    civilization_race
    |> cast(attrs, [:relationship, :description])
    |> validate_required([:civilization_id, :race_id])
    |> foreign_key_constraint(:civilization_id)
    |> foreign_key_constraint(:race_id)
    |> unique_constraint(:race_id, name: :civilization_races_civilization_id_race_id_index)
  end
end
