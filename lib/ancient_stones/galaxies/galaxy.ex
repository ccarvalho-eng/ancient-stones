defmodule AncientStones.Galaxies.Galaxy do
  @moduledoc """
  A named galaxy that groups worlds at the top of the setting hierarchy.

  Galaxy names are unique. Worlds reference a galaxy through their
  `galaxy_id` foreign key.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Worlds.World

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "galaxies" do
    field :name, :string
    field :description, :string

    has_many(:worlds, World)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for creating or updating a galaxy.

  The changeset requires a name and enforces the database-backed unique-name
  constraint.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(galaxy, attrs) do
    galaxy
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :galaxies_name_index)
  end
end
