defmodule AncientStones.Worlds.LocationGod do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Location

  @roles [:primary, :associated, :shared, :contested, :historical]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "location_gods" do
    field :role, Ecto.Enum, values: @roles, default: :primary
    field :description, :string
    belongs_to :location, Location
    belongs_to :god, God
    timestamps(type: :utc_datetime)
  end

  def changeset(location_god, attrs, refs \\ %{}) do
    location_god
    |> cast(attrs, [:role, :description])
    |> put_refs(refs)
    |> validate_required([:role, :location_id, :god_id])
    |> foreign_key_constraint(:location_id)
    |> foreign_key_constraint(:god_id)
    |> check_constraint(:role, name: :location_gods_role)
    |> unique_constraint([:location_id, :god_id])
  end

  def role_options do
    Enum.map(@roles, fn role ->
      {role |> Atom.to_string() |> String.capitalize(), role}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc ->
      put_change(acc, field, value)
    end)
  end
end
