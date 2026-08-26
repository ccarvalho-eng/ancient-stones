defmodule AncientStones.Worlds.ProvinceWaterBody do
  @moduledoc """
  Joins a province to a water body with a geographic relationship.

  Relationships distinguish coasts and borders from containment, drainage, and
  river sources.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.WaterBody

  @relationships [:coast, :contains, :drains_to, :source, :border]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}
  @type option :: {String.t(), atom()}

  schema "province_water_bodies" do
    field :relationship, Ecto.Enum, values: @relationships
    field :description, :string
    belongs_to :province, Province
    belongs_to :water_body, WaterBody
    timestamps(type: :utc_datetime)
  end

  @doc "Builds a province-water link changeset with optional trusted references."
  @spec changeset(t(), map(), map()) :: Ecto.Changeset.t()
  def changeset(link, attrs, refs \\ %{}) do
    link
    |> cast(attrs, [:relationship, :description])
    |> put_refs(refs)
    |> validate_required([:relationship, :province_id, :water_body_id])
    |> foreign_key_constraint(:province_id)
    |> foreign_key_constraint(:water_body_id)
    |> unique_constraint([:province_id, :water_body_id, :relationship],
      name: :province_water_bodies_unique_link_index
    )
  end

  @doc "Returns labeled province-to-water relationship options."
  @spec relationship_options() :: [option()]
  def relationship_options do
    Enum.map(@relationships, fn relationship ->
      label = relationship |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
      {label, relationship}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
