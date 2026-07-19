defmodule AncientStones.Worlds.RaceTrait do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Race

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "race_traits" do
    field :category, :string
    field :name, :string
    field :description, :string

    belongs_to(:race, Race)

    timestamps(type: :utc_datetime)
  end

  def changeset(race_trait, attrs) do
    race_trait
    |> cast(attrs, [:category, :name, :description])
    |> validate_required([:category, :name, :race_id])
    |> validate_inclusion(:category, ["perk", "power"])
    |> foreign_key_constraint(:race_id)
    |> unique_constraint(:name, name: :race_traits_race_id_category_name_index)
  end
end
