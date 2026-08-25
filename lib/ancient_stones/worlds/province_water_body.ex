defmodule AncientStones.Worlds.ProvinceWaterBody do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.WaterBody

  @relationships [:coast, :contains, :drains_to, :source, :border]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "province_water_bodies" do
    field :relationship, Ecto.Enum, values: @relationships
    field :description, :string
    belongs_to :province, Province
    belongs_to :water_body, WaterBody
    timestamps(type: :utc_datetime)
  end

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
