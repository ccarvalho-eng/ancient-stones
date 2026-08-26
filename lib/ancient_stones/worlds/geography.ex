defmodule AncientStones.Worlds.Geography do
  @moduledoc """
  Shared controlled vocabulary for geographic records and forms.

  Keeping terrain, climate, and discovery visibility here ensures Ecto enums,
  templates, and imported world data use the same persisted values.
  """

  @type terrain ::
          :coast
          | :forest
          | :highlands
          | :marsh
          | :mountain
          | :plains
          | :riverlands
          | :snowfield
          | :tundra
          | :volcanic
          | :wetlands
  @type climate :: :arctic | :coastal | :cold | :dry | :temperate | :volcanic | :wet
  @type visibility :: :known | :rumored | :hidden | :lost
  @type option(value) :: {String.t(), value}

  @terrain_values [
    :coast,
    :forest,
    :highlands,
    :marsh,
    :mountain,
    :plains,
    :riverlands,
    :snowfield,
    :tundra,
    :volcanic,
    :wetlands
  ]

  @climate_values [
    :arctic,
    :coastal,
    :cold,
    :dry,
    :temperate,
    :volcanic,
    :wet
  ]

  @visibility_values [
    :known,
    :rumored,
    :hidden,
    :lost
  ]

  @doc "Returns the terrain atoms accepted by province and hold schemas."
  @spec terrain_values() :: [terrain()]
  def terrain_values do
    @terrain_values
  end

  @doc "Returns the climate atoms accepted by province and hold schemas."
  @spec climate_values() :: [climate()]
  def climate_values do
    @climate_values
  end

  @doc "Returns the discovery states accepted by geographic records."
  @spec visibility_values() :: [visibility()]
  def visibility_values do
    @visibility_values
  end

  @doc "Returns labeled terrain options for forms."
  @spec terrain_options() :: [option(terrain())]
  def terrain_options do
    enum_options(@terrain_values)
  end

  @doc "Returns labeled climate options for forms."
  @spec climate_options() :: [option(climate())]
  def climate_options do
    enum_options(@climate_values)
  end

  @doc "Returns labeled discovery-state options for forms."
  @spec visibility_options() :: [option(visibility())]
  def visibility_options do
    enum_options(@visibility_values)
  end

  @doc "Converts an enum atom or underscore-delimited string into a display label."
  @spec label(atom() | String.t() | nil) :: String.t()
  def label(nil) do
    ""
  end

  def label(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> label()
  end

  def label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp enum_options(values) do
    values
    |> Enum.map(&{label(&1), &1})
    |> Enum.sort_by(fn {label, _value} -> String.downcase(label) end)
  end
end
