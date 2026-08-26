defmodule AncientStones.Maps do
  @moduledoc """
  Map-document persistence and searchable canvas-object indexing.

  This context keeps serialized Fabric.js documents and relational map-item
  indexes consistent. Linked geography is validated against the owning world,
  map hierarchies are kept acyclic, and editor updates use optimistic locking.
  """

  import Ecto.Query

  alias AncientStones.Maps.MapDocument
  alias AncientStones.Maps.MapItem
  alias AncientStones.Repo
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.World

  @type attrs :: map()
  @type error ::
          Ecto.Changeset.t()
          | :map_selection_required
          | :map_not_found
          | :entity_outside_world
          | :invalid_map_document
  @type result(record) :: {:ok, record} | {:error, error()}

  @doc "Lists every map alphabetically with its world and parent map preloaded."
  @spec list_maps() :: [MapDocument.t()]
  def list_maps do
    MapDocument
    |> order_by([map], asc: map.name)
    |> Repo.all()
    |> Repo.preload([:world, :parent_map])
  end

  @doc "Counts all map documents."
  @spec count_maps() :: non_neg_integer()
  def count_maps do
    Repo.aggregate(MapDocument, :count, :id)
  end

  @doc """
  Returns a world's map when the world has exactly one map.

  Returns `nil` when the world has no map or when multiple maps require an
  explicit selection.
  """
  @spec get_world_map(%World{}) :: MapDocument.t() | nil
  def get_world_map(%World{id: world_id}) do
    world_id
    |> world_maps_query()
    |> limit(2)
    |> Repo.all()
    |> case do
      [map_document] -> preload_items(map_document)
      _ -> nil
    end
  end

  @doc "Returns the selected map when it belongs to the supplied world."
  @spec get_world_map(%World{}, Ecto.UUID.t()) :: MapDocument.t() | nil
  def get_world_map(%World{id: world_id}, id) do
    MapDocument
    |> Repo.get_by(id: id, world_id: world_id)
    |> preload_items()
  end

  @doc "Lists a world's maps with parent-map metadata preloaded."
  @spec list_world_maps(%World{}) :: [MapDocument.t()]
  def list_world_maps(%World{id: world_id}) do
    world_id
    |> world_maps_query()
    |> Repo.all()
    |> Repo.preload(:parent_map)
  end

  @doc "Builds a metadata-only changeset for a world map."
  @spec change_world_map(MapDocument.t(), attrs()) :: Ecto.Changeset.t()
  def change_world_map(%MapDocument{} = map_document, attrs \\ %{}) do
    MapDocument.metadata_changeset(map_document, attrs)
  end

  @doc "Creates a map owned by a world after validating any parent map."
  @spec create_world_map(%World{}, attrs()) :: result(MapDocument.t())
  def create_world_map(%World{id: world_id}, attrs) do
    map_document = %MapDocument{world_id: world_id}

    map_document
    |> MapDocument.changeset(attrs)
    |> put_parent_map(world_id, map_document.id, parent_map_id(attrs))
    |> Repo.insert()
  end

  @doc """
  Updates map metadata under a world-scoped lock.

  Stale editor state returns a changeset error on `lock_version`; parent-map
  changes are checked for cross-world references and cycles.
  """
  @spec update_world_map(MapDocument.t(), attrs()) :: result(MapDocument.t())
  def update_world_map(%MapDocument{world_id: world_id} = map_document, attrs) do
    Repo.transaction(fn ->
      lock_world_maps(world_id)
      current_map_document = Repo.get!(MapDocument, map_document.id)

      if current_map_document.lock_version == map_document.lock_version do
        current_map_document
        |> MapDocument.metadata_changeset(attrs)
        |> maybe_put_parent_map(attrs, world_id, map_document.id)
        |> Ecto.Changeset.optimistic_lock(:lock_version)
        |> Repo.update(stale_error_field: :lock_version)
        |> unwrap_transaction_result()
      else
        map_document
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.add_error(:lock_version, "is stale")
        |> Repo.rollback()
      end
    end)
    |> unwrap_repo_transaction()
  end

  @doc "Deletes a map document."
  @spec delete_world_map(MapDocument.t()) :: result(MapDocument.t())
  def delete_world_map(%MapDocument{} = map_document) do
    Repo.delete(map_document)
  end

  @doc """
  Duplicates a map and regenerates every indexed canvas-object identifier.

  The duplicate receives the first available `copy` suffix within its world.
  """
  @spec duplicate_world_map(MapDocument.t()) :: result(MapDocument.t())
  def duplicate_world_map(%MapDocument{id: id, world_id: world_id}) do
    Repo.transaction(fn ->
      lock_world_maps(world_id)

      source_map =
        case Repo.get_by(MapDocument, id: id, world_id: world_id) do
          nil -> Repo.rollback(:map_not_found)
          map_document -> map_document
        end

      duplicate_map = %MapDocument{
        world_id: world_id,
        parent_map_id: source_map.parent_map_id
      }

      attrs = %{
        "name" => duplicate_map_name(world_id, source_map.name),
        "description" => source_map.description,
        "kind" => source_map.kind,
        "document" => regenerate_map_item_ids(source_map.document),
        "width" => source_map.width,
        "height" => source_map.height
      }

      case save_map_document(duplicate_map, attrs) do
        {:ok, duplicated_map} -> duplicated_map
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
    |> unwrap_repo_transaction()
  end

  @doc "Lists indexed objects for a world's only map, or an empty list otherwise."
  @spec list_world_map_items(%World{}) :: [MapItem.t()]
  def list_world_map_items(%World{} = world) do
    case get_world_map(world) do
      nil -> []
      map_document -> map_document.items
    end
  end

  @doc "Lists indexed objects for a map in canvas order."
  @spec list_map_items(MapDocument.t()) :: [MapItem.t()]
  def list_map_items(%MapDocument{id: map_document_id}) do
    MapItem
    |> where([item], item.map_document_id == ^map_document_id)
    |> order_by([item], asc: item.position)
    |> Repo.all()
  end

  @doc """
  Creates or replaces a world's map when selection is unambiguous.

  Returns `{:error, :map_selection_required}` when the world has multiple maps.
  """
  @spec save_world_map(%World{}, attrs()) :: result(MapDocument.t())
  def save_world_map(%World{id: world_id}, attrs) do
    world_id
    |> world_maps_query()
    |> limit(2)
    |> Repo.all()
    |> case do
      [] -> save_map_document(%MapDocument{world_id: world_id}, attrs)
      [map_document] -> save_map_document(map_document, attrs)
      _maps -> {:error, :map_selection_required}
    end
  end

  @doc """
  Atomically saves serialized canvas state and its relational object index.

  Map objects receive stable identifiers when missing. Any linked geography
  must belong to the map's world, and stale updates fail through optimistic
  locking without partially replacing indexed items.
  """
  @spec save_map_document(MapDocument.t(), attrs()) :: result(MapDocument.t())
  def save_map_document(%MapDocument{world_id: world_id} = map_document, attrs) do
    document =
      attrs
      |> document_from_attrs()
      |> ensure_item_ids()

    attrs = put_document(attrs, document)

    changeset =
      map_document
      |> MapDocument.changeset(attrs)
      |> maybe_optimistic_lock(map_document)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:map_document, fn repo, _changes ->
      if map_document.id do
        repo.update(changeset, stale_error_field: :lock_version)
      else
        repo.insert(changeset)
      end
    end)
    |> Ecto.Multi.run(:map_items, fn repo, %{map_document: saved_map_document} ->
      replace_map_items(repo, world_id, saved_map_document, document)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{map_document: saved_map_document}} ->
        {:ok, Repo.preload(saved_map_document, :items, force: true)}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  defp replace_map_items(repo, world_id, map_document, %{"objects" => objects})
       when is_list(objects) do
    changesets =
      objects
      |> Enum.with_index()
      |> Enum.map(fn {object, index} -> map_item_changeset(map_document, object, index) end)

    with :ok <- validate_changesets(changesets),
         :ok <- validate_entity_ownership(repo, world_id, changesets) do
      repo.delete_all(from item in MapItem, where: item.map_document_id == ^map_document.id)
      insert_map_items(repo, changesets)
    end
  end

  defp replace_map_items(_repo, _world_id, _map_document, _document) do
    {:error, :invalid_map_document}
  end

  defp map_item_changeset(map_document, object, index) do
    entity_attrs = entity_attrs(object["mapEntityType"], object["mapEntityId"])

    attrs =
      %{
        "item_key" => item_key(object["mapItemId"]),
        "object_type" => object["type"],
        "kind" => object["mapKind"],
        "layer" => object["mapLayer"] || "features",
        "position" => index,
        "name" => object["mapEntityName"] || object["mapIconName"],
        "icon_author" => object["mapIconAuthor"],
        "x" => number(object["mapX"] || object["left"]),
        "y" => number(object["mapY"] || object["top"]),
        "angle" => number(object["angle"], 0.0),
        "scale_x" => number(object["scaleX"], 1.0),
        "scale_y" => number(object["scaleY"], 1.0),
        "object_data" => object
      }
      |> Map.merge(entity_attrs)

    %MapItem{map_document_id: map_document.id}
    |> MapItem.changeset(attrs)
  end

  defp validate_changesets(changesets) do
    case Enum.find(changesets, &(not &1.valid?)) do
      nil -> :ok
      changeset -> {:error, changeset}
    end
  end

  defp validate_entity_ownership(repo, world_id, changesets) do
    Enum.reduce_while(changesets, :ok, fn changeset, :ok ->
      case linked_entity(changeset) do
        nil ->
          {:cont, :ok}

        {type, id} ->
          if entity_belongs_to_world?(repo, world_id, type, id) do
            {:cont, :ok}
          else
            {:halt, {:error, :entity_outside_world}}
          end
      end
    end)
  end

  defp linked_entity(changeset) do
    Enum.find_value(~w(continent province hold location)a, fn type ->
      case Ecto.Changeset.get_field(changeset, entity_field(type)) do
        nil -> nil
        id -> {type, id}
      end
    end)
  end

  defp entity_belongs_to_world?(repo, world_id, :continent, id) do
    repo.exists?(
      from continent in Continent,
        where: continent.id == ^id and continent.world_id == ^world_id
    )
  end

  defp entity_belongs_to_world?(repo, world_id, :province, id) do
    repo.exists?(
      from province in Province,
        join: continent in assoc(province, :continent),
        where: province.id == ^id and continent.world_id == ^world_id
    )
  end

  defp entity_belongs_to_world?(repo, world_id, :hold, id) do
    repo.exists?(
      from hold in Hold,
        join: province in assoc(hold, :province),
        join: continent in assoc(province, :continent),
        where: hold.id == ^id and continent.world_id == ^world_id
    )
  end

  defp entity_belongs_to_world?(repo, world_id, :location, id) do
    repo.exists?(
      from location in Location,
        join: hold in assoc(location, :hold),
        join: province in assoc(hold, :province),
        join: continent in assoc(province, :continent),
        where: location.id == ^id and continent.world_id == ^world_id
    )
  end

  defp insert_map_items(repo, changesets) do
    Enum.reduce_while(changesets, {:ok, []}, fn changeset, {:ok, items} ->
      case repo.insert(changeset) do
        {:ok, item} -> {:cont, {:ok, [item | items]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp entity_attrs(type, id)
       when type in ~w(continent province hold location) and is_binary(id) do
    field = type |> String.to_existing_atom() |> entity_field() |> Atom.to_string()
    %{field => id}
  end

  defp entity_attrs(_type, _id) do
    %{}
  end

  defp entity_field(:continent), do: :continent_id
  defp entity_field(:province), do: :province_id
  defp entity_field(:hold), do: :hold_id
  defp entity_field(:location), do: :location_id

  defp item_key(value) when is_binary(value) do
    case Ecto.UUID.cast(value) do
      {:ok, item_key} -> item_key
      :error -> Ecto.UUID.generate()
    end
  end

  defp item_key(_value) do
    Ecto.UUID.generate()
  end

  defp number(value, default \\ 0.0)
  defp number(value, _default) when is_integer(value), do: value / 1
  defp number(value, _default) when is_float(value), do: value
  defp number(_value, default), do: default

  defp preload_items(nil), do: nil
  defp preload_items(map_document), do: Repo.preload(map_document, :items)

  defp world_maps_query(world_id) do
    MapDocument
    |> where([map_document], map_document.world_id == ^world_id)
    |> order_by(
      [map_document],
      asc_nulls_first: map_document.parent_map_id,
      asc: map_document.name
    )
  end

  defp lock_world_maps(world_id) do
    MapDocument
    |> where([map_document], map_document.world_id == ^world_id)
    |> lock("FOR UPDATE")
    |> Repo.all()
  end

  defp duplicate_map_name(world_id, source_name) do
    existing_names =
      MapDocument
      |> where([map_document], map_document.world_id == ^world_id)
      |> select([map_document], map_document.name)
      |> Repo.all()
      |> MapSet.new()

    Stream.iterate(1, &(&1 + 1))
    |> Enum.find_value(fn copy_number ->
      suffix = if copy_number == 1, do: " copy", else: " copy #{copy_number}"
      available_length = 120 - String.length(suffix)

      candidate =
        source_name
        |> String.slice(0, available_length)
        |> String.trim_trailing()
        |> Kernel.<>(suffix)

      if MapSet.member?(existing_names, candidate), do: nil, else: candidate
    end)
  end

  defp regenerate_map_item_ids(%{"objects" => objects} = document) when is_list(objects) do
    Map.put(document, "objects", Enum.map(objects, &regenerate_map_item_id/1))
  end

  defp regenerate_map_item_ids(document) do
    document
  end

  defp regenerate_map_item_id(object) when is_map(object) do
    Map.put(object, "mapItemId", Ecto.UUID.generate())
  end

  defp regenerate_map_item_id(object) do
    object
  end

  defp maybe_put_parent_map(changeset, attrs, world_id, map_id) do
    if Map.has_key?(attrs, "parent_map_id") or Map.has_key?(attrs, :parent_map_id) do
      put_parent_map(changeset, world_id, map_id, parent_map_id(attrs))
    else
      changeset
    end
  end

  defp maybe_optimistic_lock(changeset, %MapDocument{id: nil}), do: changeset

  defp maybe_optimistic_lock(changeset, %MapDocument{}) do
    Ecto.Changeset.optimistic_lock(changeset, :lock_version)
  end

  defp unwrap_transaction_result({:ok, value}), do: value
  defp unwrap_transaction_result({:error, changeset}), do: Repo.rollback(changeset)

  defp unwrap_repo_transaction({:ok, value}), do: {:ok, value}
  defp unwrap_repo_transaction({:error, reason}), do: {:error, reason}

  defp document_from_attrs(attrs) do
    attrs["document"] || attrs[:document]
  end

  defp put_document(attrs, document) when is_map_key(attrs, "document") do
    Map.put(attrs, "document", document)
  end

  defp put_document(attrs, document) do
    Map.put(attrs, :document, document)
  end

  defp ensure_item_ids(%{"objects" => objects} = document) when is_list(objects) do
    Map.put(document, "objects", Enum.map(objects, &ensure_item_id/1))
  end

  defp ensure_item_ids(document), do: document

  defp ensure_item_id(object) when is_map(object) do
    case Ecto.UUID.cast(object["mapItemId"]) do
      {:ok, item_id} -> Map.put(object, "mapItemId", item_id)
      :error -> Map.put(object, "mapItemId", Ecto.UUID.generate())
    end
  end

  defp ensure_item_id(object) do
    object
  end

  defp put_parent_map(changeset, _world_id, _map_id, parent_id)
       when parent_id in [nil, ""] do
    Ecto.Changeset.put_change(changeset, :parent_map_id, nil)
  end

  defp put_parent_map(changeset, world_id, map_id, parent_id) do
    if valid_parent_map?(world_id, map_id, parent_id) do
      Ecto.Changeset.put_change(changeset, :parent_map_id, parent_id)
    else
      Ecto.Changeset.add_error(
        changeset,
        :parent_map_id,
        "must belong to this world and cannot create a cycle"
      )
    end
  end

  defp valid_parent_map?(world_id, map_id, parent_id) do
    with {:ok, parent_id} <- Ecto.UUID.cast(parent_id),
         %MapDocument{} = parent_map <-
           Repo.get_by(MapDocument, id: parent_id, world_id: world_id) do
      not parent_cycle?(parent_map, map_id, %{})
    else
      _ -> false
    end
  end

  defp parent_cycle?(_map_document, nil, _visited) do
    false
  end

  defp parent_cycle?(%MapDocument{id: id}, map_id, _visited) when id == map_id do
    true
  end

  defp parent_cycle?(%MapDocument{parent_map_id: nil}, _map_id, _visited) do
    false
  end

  defp parent_cycle?(%MapDocument{id: id, parent_map_id: parent_id}, map_id, visited) do
    if Map.has_key?(visited, id) do
      true
    else
      case Repo.get(MapDocument, parent_id) do
        nil -> false
        parent_map -> parent_cycle?(parent_map, map_id, Map.put(visited, id, true))
      end
    end
  end

  defp parent_map_id(attrs) do
    attrs["parent_map_id"] || attrs[:parent_map_id]
  end
end
