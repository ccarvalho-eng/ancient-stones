defmodule AncientStones.Worlds.RaceTrait do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Race

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @category_options [
    {"Power", :power},
    {"Perk", :perk}
  ]

  schema "race_traits" do
    field :category, Ecto.Enum, values: [:perk, :power]
    field :name, :string
    field :description, :string

    belongs_to(:race, Race)

    timestamps(type: :utc_datetime)
  end

  def changeset(race_trait, attrs) do
    race_trait
    |> cast(attrs, [:category, :name, :description])
    |> validate_required([:category, :name, :race_id])
    |> foreign_key_constraint(:race_id)
    |> unique_constraint(:name, name: :race_traits_race_id_category_name_index)
  end

  def category_options do
    @category_options
  end
end
