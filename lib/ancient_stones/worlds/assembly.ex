defmodule AncientStones.Worlds.Assembly do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.World

  @scopes [:continent, :province, :hold]
  @statuses [:active, :suspended, :historical]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "assemblies" do
    field :name, :string
    field :scope, Ecto.Enum, values: @scopes
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :meeting_cycle, :string
    field :membership_rule, :string
    field :jurisdiction, :string
    field :appeal_path, :string
    field :enforcement, :string
    field :description, :string

    belongs_to :world, World
    belongs_to :continent, Continent
    belongs_to :province, Province
    belongs_to :hold, Hold
    belongs_to :location, Location

    timestamps(type: :utc_datetime)
  end

  def changeset(assembly, attrs, refs \\ %{}) do
    assembly
    |> cast(attrs, [
      :name,
      :scope,
      :status,
      :meeting_cycle,
      :membership_rule,
      :jurisdiction,
      :appeal_path,
      :enforcement,
      :description
    ])
    |> put_refs(refs)
    |> validate_required([
      :name,
      :scope,
      :status,
      :meeting_cycle,
      :membership_rule,
      :jurisdiction,
      :enforcement,
      :world_id
    ])
    |> validate_scope_target()
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:continent_id)
    |> foreign_key_constraint(:province_id)
    |> foreign_key_constraint(:hold_id)
    |> foreign_key_constraint(:location_id)
    |> check_constraint(:scope, name: :assemblies_scope_target)
    |> check_constraint(:status, name: :assemblies_status)
    |> unique_constraint(:name, name: :assemblies_world_id_name_index)
  end

  def scope_options do
    options(@scopes)
  end

  def status_options do
    options(@statuses)
  end

  defp validate_scope_target(changeset) do
    scope = get_field(changeset, :scope)

    targets = %{
      continent: get_field(changeset, :continent_id),
      province: get_field(changeset, :province_id),
      hold: get_field(changeset, :hold_id)
    }

    valid? =
      Enum.all?(targets, fn {target_scope, id} ->
        if target_scope == scope, do: not is_nil(id), else: is_nil(id)
      end)

    if valid? do
      changeset
    else
      add_error(changeset, :scope, "must match exactly one jurisdiction")
    end
  end

  defp options(values) do
    Enum.map(values, fn value ->
      label = value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
      {label, value}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc ->
      put_change(acc, field, value)
    end)
  end
end
