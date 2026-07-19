defmodule AncientStones.Worlds.PoliticalOffice do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "political_offices" do
    field :office, :string
    field :scope, :string
    field :politics, :string
    field :description, :string

    belongs_to(:world, World)
    belongs_to(:province, Province)
    belongs_to(:hold, Hold)
    belongs_to(:character, Character)

    timestamps(type: :utc_datetime)
  end

  def changeset(political_office, attrs) do
    political_office
    |> cast(attrs, [:office, :scope, :politics, :description])
    |> validate_required([:office, :scope, :world_id])
    |> validate_inclusion(:scope, ["province", "hold"])
    |> validate_high_king_scope()
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:province_id)
    |> foreign_key_constraint(:hold_id)
    |> foreign_key_constraint(:character_id)
    |> unique_constraint(:office, name: :political_offices_province_id_office_index)
    |> unique_constraint(:office, name: :political_offices_hold_id_office_index)
  end

  defp validate_high_king_scope(changeset) do
    office = get_field(changeset, :office)
    scope = get_field(changeset, :scope)

    if normalized_office(office) == "high king" && scope != "province" do
      add_error(changeset, :office, "must be scoped to a province")
    else
      changeset
    end
  end

  defp normalized_office(nil) do
    nil
  end

  defp normalized_office(office) do
    office
    |> String.downcase()
    |> String.trim()
  end
end
