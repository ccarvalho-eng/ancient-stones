defmodule AncientStones.Galaxies do
  @moduledoc """
  Catalog operations for top-level galaxy records.
  """

  import Ecto.Query

  alias AncientStones.Galaxies.Galaxy
  alias AncientStones.Repo

  @doc "Lists galaxies alphabetically with their nested planets."
  def list_galaxies do
    Galaxy
    |> order_by([galaxy], asc: galaxy.name)
    |> Repo.all()
    |> Repo.preload(:worlds)
  end

  @doc "Counts galaxy records."
  def count_galaxies do
    Repo.aggregate(Galaxy, :count)
  end

  @doc "Creates a galaxy."
  def create_galaxy(attrs) do
    %Galaxy{}
    |> Galaxy.changeset(attrs)
    |> Repo.insert()
  end

  def get_galaxy!(id) do
    Galaxy
    |> Repo.get!(id)
    |> Repo.preload(:worlds)
  end

  @doc "Deletes a galaxy."
  def delete_galaxy(%Galaxy{} = galaxy) do
    Repo.delete(galaxy)
  end

  @doc "Returns an existing galaxy by name or creates it."
  def get_or_create_galaxy_by_name!(attrs) do
    case Repo.get_by(Galaxy, name: attrs.name) do
      nil ->
        attrs
        |> create_galaxy()
        |> unwrap!()

      galaxy ->
        galaxy
    end
  end

  defp unwrap!({:ok, record}) do
    record
  end

  defp unwrap!({:error, changeset}) do
    raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
  end
end
