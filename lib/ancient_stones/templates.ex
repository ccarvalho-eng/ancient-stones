defmodule AncientStones.Templates do
  @moduledoc """
  Starter datasets that can be copied into a user's world.
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

  def options do
    [
      {"Blank", "blank"},
      {"Skyrim", "skyrim"}
    ]
  end

  def defaults(template) do
    case get(template) do
      {:ok, template_data} -> Map.take(template_data, [:name, :description, :galaxy])
      :error -> %{name: "", description: ""}
    end
  end
end
