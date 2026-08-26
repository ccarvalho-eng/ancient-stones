defmodule AncientStones.Worlds.PoliticalOffice do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Continent
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
    field :selection_method, :string
    field :succession_rule, :string
    field :term_started_year, :integer
    field :term_length_years, :integer

    belongs_to(:world, World)
    belongs_to(:continent, Continent)
    belongs_to(:province, Province)
    belongs_to(:hold, Hold)
    belongs_to(:character, Character)
    belongs_to(:designated_successor, Character)

    timestamps(type: :utc_datetime)
  end

  def changeset(political_office, attrs) do
    political_office
    |> cast(attrs, [
      :office,
      :scope,
      :politics,
      :selection_method,
      :succession_rule,
      :term_started_year,
      :term_length_years,
      :description
    ])
    |> validate_required([:office, :scope, :world_id])
    |> validate_inclusion(:scope, ["continent", "province", "hold"])
    |> validate_high_king_scope()
    |> validate_number(:term_length_years, greater_than: 0)
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:continent_id)
    |> foreign_key_constraint(:province_id)
    |> foreign_key_constraint(:hold_id)
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:designated_successor_id)
    |> check_constraint(:scope, name: :political_offices_scope_target)
    |> unique_constraint(:office, name: :political_offices_continent_id_office_index)
    |> unique_constraint(:office, name: :political_offices_province_id_office_index)
    |> unique_constraint(:office, name: :political_offices_hold_id_office_index)
    |> check_constraint(:term_length_years, name: :political_offices_term_length_positive)
  end

  defp validate_high_king_scope(changeset) do
    office = get_field(changeset, :office)
    scope = get_field(changeset, :scope)

    if normalized_office(office) == "high king" && scope not in ["continent", "province"] do
      add_error(changeset, :office, "must be scoped to a continent or province")
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
