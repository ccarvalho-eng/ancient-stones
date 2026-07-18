defmodule AncientStone.Worlds do
  @moduledoc false

  alias AncientStone.Repo
  alias AncientStone.Worlds.World

  @doc false
  def get_world!(id) do
    Repo.get!(World, id)
  end

  @doc false
  def change_world(%World{} = world, attrs \\ %{}) do
    World.changeset(world, attrs)
  end

  @doc false
  def create_world(attrs) do
    %World{}
    |> World.changeset(attrs)
    |> Repo.insert()
  end
end
