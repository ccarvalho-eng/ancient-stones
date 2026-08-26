defmodule AncientStones.Templates do
  @moduledoc """
  Provides starter datasets for creating worlds.

  Templates are returned as plain nested maps so the worlds context can persist
  them as records owned by the current user.
  """

  alias AncientStones.Templates.Skyrim

  @blank %{
    name: "Untitled World",
    description: "",
    continents: [],
    guilds: [],
    location_types: [],
    races: []
  }

  @type key :: :blank | :skyrim | String.t()
  @type template :: map()

  @doc """
  Fetches a template by its atom or string identifier.

  Returns `:error` when the identifier is not registered.
  """
  @spec get(key()) :: {:ok, template()} | :error
  def get(:blank) do
    {:ok, @blank}
  end

  def get("blank") do
    {:ok, @blank}
  end

  def get(:skyrim) do
    {:ok, Skyrim.data()}
  end

  def get("skyrim") do
    {:ok, Skyrim.data()}
  end

  def get(_template) do
    :error
  end

  @doc "Returns the labels and identifiers accepted by the world creation form."
  @spec options() :: [{String.t(), String.t()}]
  def options do
    [
      {"Blank", "blank"},
      {"Skyrim", "skyrim"}
    ]
  end

  @doc """
  Returns the world-level form defaults supplied by a template.

  Unknown template identifiers produce empty name and description defaults.
  """
  @spec defaults(key()) :: map()
  def defaults(template) do
    case get(template) do
      {:ok, template_data} -> Map.take(template_data, [:name, :description, :galaxy])
      :error -> %{name: "", description: ""}
    end
  end
end
