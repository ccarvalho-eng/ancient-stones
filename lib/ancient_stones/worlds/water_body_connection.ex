defmodule AncientStones.Worlds.WaterBodyConnection do
  @moduledoc """
  A hydrologic and navigational link between two water bodies.

  The schema distinguishes physical flow direction from permitted navigation
  and validates semantics for rivers, straits, channels, and tidal exchanges.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.WaterBody

  @connection_types [:flows_into, :opens_to, :narrows_to, :linked_channel, :tidal_exchange]
  @directionalities [:one_way, :two_way]
  @navigation_directionalities [:none, :one_way, :two_way]
  @navigabilities [:none, :small_craft, :shallow_draft, :coastal, :ocean_going]
  @seasonalities [
    :year_round,
    :spring_to_autumn,
    :summer_only,
    :winter_only,
    :dry_season,
    :wet_season,
    :thaw_only,
    :intermittent
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @type t :: %__MODULE__{}
  @type option :: {String.t(), atom()}

  schema "water_body_connections" do
    field :connection_type, Ecto.Enum, values: @connection_types
    field :directionality, Ecto.Enum, values: @directionalities, default: :one_way

    field :navigation_directionality, Ecto.Enum,
      values: @navigation_directionalities,
      default: :two_way

    field :navigability, Ecto.Enum, values: @navigabilities
    field :seasonality, Ecto.Enum, values: @seasonalities
    field :distance_km, :decimal
    field :description, :string
    belongs_to :origin_water_body, WaterBody
    belongs_to :destination_water_body, WaterBody
    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a connection changeset with optional trusted endpoint references.

  Endpoints must differ, hydrologic direction must match the connection type,
  and navigation direction must match navigability.
  """
  @spec changeset(t(), map(), map()) :: Ecto.Changeset.t()
  def changeset(connection, attrs, refs \\ %{}) do
    connection
    |> cast(attrs, [
      :connection_type,
      :directionality,
      :navigation_directionality,
      :navigability,
      :seasonality,
      :distance_km,
      :description
    ])
    |> put_refs(refs)
    |> validate_required([
      :connection_type,
      :directionality,
      :navigation_directionality,
      :navigability,
      :origin_water_body_id,
      :destination_water_body_id
    ])
    |> validate_number(:distance_km, greater_than: 0)
    |> validate_distinct_endpoints()
    |> validate_connection_semantics()
    |> foreign_key_constraint(:origin_water_body_id)
    |> foreign_key_constraint(:destination_water_body_id)
    |> check_constraint(:destination_water_body_id,
      name: :water_body_connections_distinct_endpoints
    )
    |> check_constraint(:distance_km, name: :water_body_connections_distance_positive)
    |> check_constraint(:navigation_directionality,
      name: :water_body_connections_navigation_consistency
    )
    |> check_constraint(:directionality,
      name: :water_body_connections_hydrologic_semantics
    )
    |> unique_constraint([:origin_water_body_id, :destination_water_body_id, :connection_type],
      name: :water_body_connections_directed_link_index
    )
    |> unique_constraint(:destination_water_body_id,
      name: :water_body_connections_symmetric_link_index,
      message: "already exists in either direction"
    )
  end

  @doc "Returns labeled hydrologic connection types."
  @spec connection_type_options() :: [option()]
  def connection_type_options do
    options(@connection_types)
  end

  @doc "Returns labeled hydrologic directionality options."
  @spec directionality_options() :: [option()]
  def directionality_options do
    options(@directionalities)
  end

  @doc "Returns labeled vessel-capability options."
  @spec navigability_options() :: [option()]
  def navigability_options do
    options(@navigabilities)
  end

  @doc "Returns labeled navigation-direction options."
  @spec navigation_directionality_options() :: [option()]
  def navigation_directionality_options do
    options(@navigation_directionalities)
  end

  @doc "Returns labeled seasonal-access options."
  @spec seasonality_options() :: [option()]
  def seasonality_options do
    options(@seasonalities)
  end

  defp validate_distinct_endpoints(changeset) do
    if get_field(changeset, :origin_water_body_id) ==
         get_field(changeset, :destination_water_body_id) do
      add_error(changeset, :destination_water_body_id, "must differ from origin")
    else
      changeset
    end
  end

  defp validate_connection_semantics(changeset) do
    connection_type = get_field(changeset, :connection_type)
    hydrologic_directionality = get_field(changeset, :directionality)
    navigability = get_field(changeset, :navigability)
    navigation_directionality = get_field(changeset, :navigation_directionality)

    changeset =
      if (connection_type == :flows_into and hydrologic_directionality != :one_way) or
           (connection_type != :flows_into and hydrologic_directionality != :two_way) do
        add_error(changeset, :directionality, "does not match the hydrologic connection")
      else
        changeset
      end

    if (navigability == :none and navigation_directionality != :none) or
         (navigability != :none and navigation_directionality == :none) do
      add_error(changeset, :navigation_directionality, "does not match navigability")
    else
      changeset
    end
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
