defmodule AncientStone.Worlds do
  @moduledoc false

  import Ecto.Query

  alias AncientStone.Repo
  alias AncientStone.Worlds.Continent
  alias AncientStone.Worlds.Hold
  alias AncientStone.Worlds.Province
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

  @doc false
  def list_continents(%World{id: world_id}) do
    Continent
    |> where([continent], continent.world_id == ^world_id)
    |> order_by([continent], asc: continent.name)
    |> Repo.all()
  end

  @doc false
  def change_continent(%Continent{} = continent, attrs \\ %{}) do
    Continent.changeset(continent, attrs)
  end

  @doc false
  def create_continent(%World{id: world_id}, attrs) do
    %Continent{world_id: world_id}
    |> Continent.changeset(attrs)
    |> Repo.insert()
  end

  @doc false
  def list_provinces(%Continent{id: continent_id}) do
    Province
    |> where([province], province.continent_id == ^continent_id)
    |> order_by([province], asc: province.name)
    |> Repo.all()
  end

  @doc false
  def change_province(%Province{} = province, attrs \\ %{}) do
    Province.changeset(province, attrs)
  end

  @doc false
  def create_province(%Continent{id: continent_id}, attrs) do
    %Province{continent_id: continent_id}
    |> Province.changeset(attrs)
    |> Repo.insert()
  end

  @doc false
  def list_holds(%Province{id: province_id}) do
    Hold
    |> where([hold], hold.province_id == ^province_id)
    |> order_by([hold], asc: hold.name)
    |> Repo.all()
  end

  @doc false
  def change_hold(%Hold{} = hold, attrs \\ %{}) do
    Hold.changeset(hold, attrs)
  end

  @doc false
  def create_hold(%Province{id: province_id}, attrs) do
    %Hold{province_id: province_id}
    |> Hold.changeset(attrs)
    |> Repo.insert()
  end
end
