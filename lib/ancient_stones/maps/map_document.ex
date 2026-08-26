defmodule AncientStones.Maps.MapDocument do
  @moduledoc """
  Persisted canvas metadata and serialized drawing state for one world map.

  A map document can belong to another map, forming an acyclic hierarchy of
  world, regional, city, interior, and dungeon maps. `lock_version` provides
  optimistic concurrency control for editor saves.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Maps.MapItem
  alias AncientStones.Worlds.World

  @max_document_bytes 2_000_000
  @max_objects 2_000
  @max_layers 50
  @max_layer_name_length 80
  @legacy_layer_ids ~w(terrain features labels)
  @allowed_object_types ~w(Path Group IText Textbox Polygon Image path group i-text textbox polygon image)
  @reference_image_path ~r{\A/uploads/map-references/[0-9a-f-]+\.(png|jpg|webp)\z}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type kind :: :world | :region | :city | :interior | :dungeon
  @type document :: map()
  @type t :: %__MODULE__{}

  schema "map_documents" do
    field :name, :string, default: "World Map"
    field :description, :string
    field :kind, Ecto.Enum, values: [:world, :region, :city, :interior, :dungeon], default: :world
    field :document, :map, default: %{"objects" => []}
    field :width, :integer, default: 1600
    field :height, :integer, default: 1000
    field :lock_version, :integer, default: 1

    belongs_to :world, World
    belongs_to :parent_map, __MODULE__
    has_many :items, MapItem, preload_order: [asc: :position]
    has_many :child_maps, __MODULE__, foreign_key: :parent_map_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a complete map changeset, including serialized document validation.

  Canvas documents are bounded by object count and encoded size. Objects,
  layers, geometry, and local reference-image paths are validated before the
  document can be stored.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(map_document, attrs) do
    map_document
    |> metadata_changeset(attrs)
    |> cast(attrs, [:document])
    |> validate_required([:document, :world_id])
    |> validate_change(:document, &validate_document/2)
    |> foreign_key_constraint(:world_id)
    |> foreign_key_constraint(:parent_map_id)
    |> check_constraint(:parent_map_id, name: :map_documents_parent_not_self_check)
    |> unique_constraint(:name, name: :map_documents_world_id_name_index)
  end

  @doc "Builds a changeset for editable map metadata without replacing canvas data."
  @spec metadata_changeset(t(), map()) :: Ecto.Changeset.t()
  def metadata_changeset(map_document, attrs) do
    map_document
    |> cast(attrs, [:name, :description, :kind, :width, :height])
    |> validate_required([:name, :kind, :width, :height])
    |> validate_length(:name, max: 120)
    |> validate_number(:width, greater_than_or_equal_to: 640, less_than_or_equal_to: 8192)
    |> validate_number(:height, greater_than_or_equal_to: 480, less_than_or_equal_to: 8192)
    |> foreign_key_constraint(:parent_map_id)
    |> check_constraint(:parent_map_id, name: :map_documents_parent_not_self_check)
    |> unique_constraint(:name, name: :map_documents_world_id_name_index)
  end

  @doc "Returns the canonical empty serialized canvas document."
  @spec empty_document() :: document()
  def empty_document do
    %{"objects" => []}
  end

  defp validate_document(:document, document) when is_map(document) do
    objects = Map.get(document, "objects")
    layer_error = if is_list(objects), do: layer_validation_error(document, objects)

    cond do
      not is_list(objects) ->
        [document: "must contain an objects list"]

      object_count(objects) > @max_objects ->
        [document: "cannot contain more than #{@max_objects} objects"]

      not Enum.all?(objects, &valid_object?/1) ->
        [document: "contains an unsupported map object"]

      layer_error ->
        [document: layer_error]

      encoded_size(document) > @max_document_bytes ->
        [document: "is too large"]

      true ->
        []
    end
  end

  defp validate_document(:document, _document) do
    [document: "must be a map document"]
  end

  defp valid_object?(%{"type" => type} = object) when type in @allowed_object_types do
    valid_geometry?(object) and valid_object_data?(type, object)
  end

  defp valid_object?(_object) do
    false
  end

  defp layer_validation_error(document, objects) do
    case validate_layer_definitions(Map.get(document, "mapLayers")) do
      {:ok, layer_ids} ->
        if Enum.all?(objects, &valid_object_layer?(&1, layer_ids)) do
          nil
        else
          "contains an object assigned to an undeclared layer"
        end

      {:error, message} ->
        message
    end
  end

  defp validate_layer_definitions(nil) do
    {:ok, @legacy_layer_ids}
  end

  defp validate_layer_definitions(layers) when is_list(layers) do
    cond do
      layers == [] ->
        {:error, "must contain at least one layer"}

      length(layers) > @max_layers ->
        {:error, "cannot contain more than #{@max_layers} layers"}

      not Enum.all?(layers, &valid_layer?/1) ->
        {:error, "contains an invalid layer"}

      true ->
        validate_unique_layers(layers)
    end
  end

  defp validate_layer_definitions(_layers) do
    {:error, "must contain a layers list"}
  end

  defp validate_unique_layers(layers) do
    ids = Enum.map(layers, &Map.fetch!(&1, "id"))
    names = Enum.map(layers, &normalized_layer_name/1)

    cond do
      length(Enum.uniq(ids)) != length(ids) ->
        {:error, "contains duplicate layer ids"}

      length(Enum.uniq(names)) != length(names) ->
        {:error, "contains duplicate layer names"}

      true ->
        {:ok, ids}
    end
  end

  defp valid_layer?(%{
         "id" => id,
         "name" => name,
         "visible" => visible,
         "locked" => locked
       }) do
    valid_layer_id?(id) and
      is_binary(name) and
      String.trim(name) != "" and
      String.length(name) <= @max_layer_name_length and
      is_boolean(visible) and
      is_boolean(locked)
  end

  defp valid_layer?(_layer) do
    false
  end

  defp valid_layer_id?(id) when id in @legacy_layer_ids do
    true
  end

  defp valid_layer_id?(id) when is_binary(id) do
    match?({:ok, _uuid}, Ecto.UUID.cast(id))
  end

  defp valid_layer_id?(_id) do
    false
  end

  defp normalized_layer_name(%{"name" => name}) when is_binary(name) do
    name
    |> String.trim()
    |> String.downcase()
  end

  defp normalized_layer_name(_layer) do
    nil
  end

  defp valid_object_layer?(object, layer_ids) do
    Enum.member?(layer_ids, Map.get(object, "mapLayer", "features"))
  end

  defp valid_object_data?(type, %{"path" => path}) when type in ~w(Path path) do
    is_list(path)
  end

  defp valid_object_data?(type, %{"objects" => objects}) when type in ~w(Group group) do
    is_list(objects) and Enum.all?(objects, &valid_object?/1)
  end

  defp valid_object_data?(type, %{"text" => text})
       when type in ~w(IText Textbox i-text textbox) do
    is_binary(text)
  end

  defp valid_object_data?(type, %{"points" => points}) when type in ~w(Polygon polygon) do
    is_list(points) and length(points) >= 3 and Enum.all?(points, &valid_point?/1)
  end

  defp valid_object_data?(type, %{"src" => src, "mapReferenceSrc" => reference_src})
       when type in ~w(Image image) do
    src == reference_src and is_binary(src) and Regex.match?(@reference_image_path, src)
  end

  defp valid_object_data?(_type, _object) do
    false
  end

  defp valid_geometry?(object) do
    Enum.all?(~w(left top width height angle scaleX scaleY opacity mapX mapY), fn field ->
      not Map.has_key?(object, field) or finite_number?(object[field])
    end)
  end

  defp valid_point?(%{"x" => x, "y" => y}) do
    finite_number?(x) and finite_number?(y)
  end

  defp valid_point?(_point) do
    false
  end

  defp finite_number?(value) when is_integer(value) do
    true
  end

  defp finite_number?(value) when is_float(value) do
    true
  end

  defp finite_number?(_value) do
    false
  end

  defp object_count(objects) do
    Enum.reduce(objects, 0, fn object, count ->
      nested_count =
        case object do
          %{"objects" => nested_objects} when is_list(nested_objects) ->
            object_count(nested_objects)

          _ ->
            0
        end

      count + 1 + nested_count
    end)
  end

  defp encoded_size(document) do
    document
    |> Jason.encode!()
    |> byte_size()
  end
end
