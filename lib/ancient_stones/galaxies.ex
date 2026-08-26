defmodule AncientStones.Galaxies do
  @moduledoc """
  Catalog operations for top-level galaxy records.
  """

  import Ecto.Query

  alias AncientStones.Galaxies.Galaxy
  alias AncientStones.Repo

  @type attrs :: map()
  @type result(record) :: {:ok, record} | {:error, Ecto.Changeset.t()}

  @doc "Lists galaxies alphabetically with their worlds preloaded."
  @spec list_galaxies() :: [Galaxy.t()]
  def list_galaxies do
    Galaxy
    |> order_by([galaxy], asc: galaxy.name)
    |> Repo.all()
    |> Repo.preload(:worlds)
  end

  @doc "Counts galaxy records."
  @spec count_galaxies() :: non_neg_integer()
  def count_galaxies do
    Repo.aggregate(Galaxy, :count)
  end

  @doc "Creates a galaxy."
  @spec create_galaxy(attrs()) :: result(Galaxy.t())
  def create_galaxy(attrs) do
    %Galaxy{}
    |> Galaxy.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Updates a galaxy's name or description."
  @spec update_galaxy(Galaxy.t(), attrs()) :: result(Galaxy.t())
  def update_galaxy(%Galaxy{} = galaxy, attrs) do
    galaxy
    |> Galaxy.changeset(attrs)
    |> Repo.update()
  end

  @doc "Fetches a galaxy by id and preloads its worlds, raising when absent."
  @spec get_galaxy!(Ecto.UUID.t()) :: Galaxy.t()
  def get_galaxy!(id) do
    Galaxy
    |> Repo.get!(id)
    |> Repo.preload(:worlds)
  end

  @doc "Deletes a galaxy."
  @spec delete_galaxy(Galaxy.t()) :: result(Galaxy.t())
  def delete_galaxy(%Galaxy{} = galaxy) do
    Repo.delete(galaxy)
  end

  @doc """
  Returns the galaxy with the supplied name or creates it.

  Raises `Ecto.InvalidChangesetError` when the fallback insert is invalid.
  """
  @spec get_or_create_galaxy_by_name!(%{
          required(:name) => String.t(),
          optional(atom()) => term()
        }) ::
          Galaxy.t()
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
