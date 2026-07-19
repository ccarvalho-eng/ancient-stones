defmodule AncientStones.Worlds.Geography do
  @moduledoc """
  Shared geography vocabulary for terrain and climate fields.
  """

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

  def terrain_values do
    @terrain_values
  end

  def climate_values do
    @climate_values
  end

  def terrain_options do
    enum_options(@terrain_values)
  end

  def climate_options do
    enum_options(@climate_values)
  end

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
    Enum.map(values, &{label(&1), &1})
  end
end
