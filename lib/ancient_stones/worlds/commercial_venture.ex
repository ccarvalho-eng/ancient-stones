defmodule AncientStones.Worlds.CommercialVenture do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.VentureMembership
  alias AncientStones.Worlds.VentureTradeRoute
  alias AncientStones.Worlds.World

  @venture_types [
    :felag,
    :merchant_house,
    :ship_share,
    :caravan_partnership,
    :workshop_partnership
  ]
  @statuses [:active, :seasonal, :dormant, :completed, :dissolved]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "commercial_ventures" do
    field :name, :string
    field :venture_type, Ecto.Enum, values: @venture_types
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :purpose, :string
    field :capital_basis, :string
    field :formation_label, :string
    field :end_label, :string
    field :description, :string
    belongs_to :world, World
    belongs_to :home_location, Location
    has_many :memberships, VentureMembership
    has_many :trade_route_links, VentureTradeRoute
    timestamps(type: :utc_datetime)
  end

  def changeset(venture, attrs, refs \\ %{}) do
    venture
    |> cast(attrs, [
      :name,
      :venture_type,
      :status,
      :purpose,
      :capital_basis,
      :formation_label,
      :end_label,
      :description
    ])
    |> put_refs(refs)
    |> validate_required([:name, :venture_type, :status, :purpose, :world_id])
    |> validate_length(:name, max: 160)
    |> validate_length(:purpose, max: 1_000)
    |> validate_length(:description, max: 4_000)
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:home_location_id)
    |> unique_constraint(:name, name: :commercial_ventures_world_id_name_index)
    |> check_constraint(:venture_type, name: :commercial_ventures_type)
    |> check_constraint(:status, name: :commercial_ventures_status)
  end

  def venture_type_options do
    options(@venture_types)
  end

  def status_options do
    options(@statuses)
  end

  defp options(values) do
    Enum.map(values, fn value ->
      label = value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
      {label, value}
    end)
  end

  defp put_refs(changeset, refs) do
    Enum.reduce(refs, changeset, fn {field, value}, acc -> put_change(acc, field, value) end)
  end
end
