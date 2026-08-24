defmodule AncientStones.MapsTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.Maps
  alias AncientStones.Worlds

  test "creates hierarchical maps scoped to a world and nilifies children on delete" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, other_world} = Worlds.create_world(%{name: "Masser"})

    assert {:ok, outer_map} =
             Maps.create_world_map(world, %{"name" => "The North", "kind" => "world"})

    assert {:ok, inner_map} =
             Maps.create_world_map(world, %{
               "name" => "Frosthold",
               "kind" => "city",
               "parent_map_id" => outer_map.id
             })

    assert Enum.map(Maps.list_world_maps(world), & &1.name) == ["The North", "Frosthold"]
    assert Maps.get_world_map(world, inner_map.id).parent_map_id == outer_map.id

    assert {:error, changeset} =
             Maps.create_world_map(other_world, %{
               "name" => "Foreign child",
               "kind" => "region",
               "parent_map_id" => outer_map.id
             })

    assert "must belong to this world and cannot create a cycle" in errors_on(changeset).parent_map_id

    assert {:error, changeset} =
             Maps.update_world_map(outer_map, %{"parent_map_id" => inner_map.id})

    assert "must belong to this world and cannot create a cycle" in errors_on(changeset).parent_map_id

    assert {:ok, _deleted_map} = Maps.delete_world_map(outer_map)
    assert Maps.get_world_map(world, inner_map.id).parent_map_id == nil
  end

  test "duplicates a complete map with a unique name and independent item ids" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, parent_map} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, source_map} =
      Maps.create_world_map(world, %{
        "name" => "Skyrim",
        "description" => "The northern province",
        "kind" => "region",
        "parent_map_id" => parent_map.id,
        "width" => 2400,
        "height" => 1600
      })

    source_item_id = Ecto.UUID.generate()

    assert {:ok, saved_source_map} =
             Maps.save_map_document(source_map, %{
               "document" => %{
                 "mapBackground" => "#e7ddc4",
                 "objects" => [
                   %{
                     "type" => "Path",
                     "path" => [],
                     "mapItemId" => source_item_id,
                     "mapKind" => "coastline",
                     "mapLayer" => "terrain",
                     "left" => 120.0,
                     "top" => 80.0
                   }
                 ]
               },
               "width" => 2400,
               "height" => 1600
             })

    assert {:ok, duplicate} = Maps.duplicate_world_map(saved_source_map)
    assert duplicate.name == "Skyrim copy"
    assert duplicate.description == saved_source_map.description
    assert duplicate.kind == saved_source_map.kind
    assert duplicate.parent_map_id == parent_map.id
    assert duplicate.width == 2400
    assert duplicate.height == 1600
    assert duplicate.document["mapBackground"] == "#e7ddc4"
    refute duplicate.id == saved_source_map.id

    [source_item] = Maps.list_map_items(saved_source_map)
    [duplicate_item] = Maps.list_map_items(duplicate)
    refute duplicate_item.item_key == source_item.item_key
    assert duplicate_item.object_data["mapItemId"] == duplicate_item.item_key

    assert {:ok, second_duplicate} = Maps.duplicate_world_map(saved_source_map)
    assert second_duplicate.name == "Skyrim copy 2"

    assert {:ok, _deleted_map} = Maps.delete_world_map(saved_source_map)
    assert {:error, :map_not_found} = Maps.duplicate_world_map(saved_source_map)
  end

  test "persists structured landmasses and map background color" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    item_id = Ecto.UUID.generate()

    document = %{
      "mapBackground" => "#9fb5b2",
      "objects" => [
        %{
          "type" => "Polygon",
          "mapItemId" => item_id,
          "points" => [%{"x" => 10, "y" => 10}, %{"x" => 80, "y" => 20}, %{"x" => 40, "y" => 90}],
          "mapKind" => "landmass",
          "mapLayer" => "terrain",
          "mapLandColor" => "#c8b88f",
          "mapCoastRoughness" => 2
        }
      ]
    }

    assert {:ok, map_document} =
             Maps.save_world_map(world, %{
               "document" => document,
               "width" => 1600,
               "height" => 1000
             })

    assert map_document.document == document
    assert [%{object_type: "Polygon", kind: "landmass"}] = Maps.list_world_map_items(world)
  end

  test "saves the only editable map document in a world" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    item_id = Ecto.UUID.generate()

    document = %{
      "version" => "7.4.0",
      "objects" => [%{"type" => "Path", "path" => [], "mapItemId" => item_id}]
    }

    assert {:ok, map_document} =
             Maps.save_world_map(world, %{
               "document" => document,
               "width" => 1600,
               "height" => 1000
             })

    assert map_document.document == document
    assert Maps.get_world_map(world).id == map_document.id

    updated_document = %{"version" => "7.4.0", "objects" => []}

    assert {:ok, updated_map_document} =
             Maps.save_world_map(world, %{
               "document" => updated_document,
               "width" => 1200,
               "height" => 800
             })

    assert updated_map_document.id == map_document.id
    assert updated_map_document.document == updated_document
  end

  test "rejects unsupported serialized objects" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    assert {:error, changeset} =
             Maps.save_world_map(world, %{
               "document" => %{"objects" => [%{"type" => "ActiveSelection"}]},
               "width" => 1600,
               "height" => 1000
             })

    assert "contains an unsupported map object" in errors_on(changeset).document
    assert Maps.get_world_map(world) == nil
  end

  test "generates and persists stable item ids in the map document" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    assert {:ok, map_document} =
             Maps.save_world_map(world, %{
               "document" => %{"objects" => [%{"type" => "Path", "path" => []}]},
               "width" => 1600,
               "height" => 1000
             })

    assert [%{"mapItemId" => item_id}] = map_document.document["objects"]
    assert {:ok, _uuid} = Ecto.UUID.cast(item_id)
    assert [%{item_key: ^item_id}] = Maps.list_map_items(map_document)
  end

  test "preserves the parent when metadata updates omit parent_map_id" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, outer_map} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    {:ok, inner_map} =
      Maps.create_world_map(world, %{
        "name" => "Whiterun",
        "kind" => "city",
        "parent_map_id" => outer_map.id
      })

    assert {:ok, updated_map} = Maps.update_world_map(inner_map, %{"name" => "Wind District"})
    assert updated_map.parent_map_id == outer_map.id
  end

  test "requires explicit selection when a world has multiple maps" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, _outer_map} = Maps.create_world_map(world, %{"name" => "Tamriel"})
    {:ok, _inner_map} = Maps.create_world_map(world, %{"name" => "Whiterun"})

    assert Maps.get_world_map(world) == nil

    assert {:error, :map_selection_required} =
             Maps.save_world_map(world, %{
               "document" => %{"objects" => []},
               "width" => 1600,
               "height" => 1000
             })
  end

  test "rejects stale canvas saves without overwriting the first save" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, stale_map} = Maps.create_world_map(world, %{"name" => "Tamriel"})

    first_document = %{"objects" => [], "mapBackground" => "#9fb5b2"}
    stale_document = %{"objects" => [], "mapBackground" => "#000000"}

    assert {:ok, saved_map} =
             Maps.save_map_document(stale_map, %{
               "document" => first_document,
               "width" => 1600,
               "height" => 1000
             })

    assert {:error, changeset} =
             Maps.save_map_document(stale_map, %{
               "document" => stale_document,
               "width" => 1600,
               "height" => 1000
             })

    assert "is stale" in errors_on(changeset).lock_version
    assert Maps.get_world_map(world, saved_map.id).document == first_document
  end

  test "rejects malformed geometry and unsupported nested objects" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    invalid_documents = [
      %{"objects" => [%{"type" => "Polygon", "points" => [%{"x" => 1, "y" => 2}]}]},
      %{
        "objects" => [
          %{"type" => "Group", "objects" => [%{"type" => "ActiveSelection"}]}
        ]
      }
    ]

    for document <- invalid_documents do
      assert {:error, changeset} =
               Maps.save_world_map(world, %{
                 "document" => document,
                 "width" => 1600,
                 "height" => 1000
               })

      assert "contains an unsupported map object" in errors_on(changeset).document
    end
  end

  test "rolls back an existing map document when item replacement fails" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, other_world} = Worlds.create_world(%{name: "Mundus"})
    {:ok, other_continent} = Worlds.create_continent(other_world, %{name: "Akavir"})
    original_item_id = Ecto.UUID.generate()

    original_document = %{
      "objects" => [
        %{
          "type" => "Path",
          "path" => [],
          "mapItemId" => original_item_id,
          "mapKind" => "road"
        }
      ]
    }

    assert {:ok, map_document} =
             Maps.save_world_map(world, %{
               "document" => original_document,
               "width" => 1600,
               "height" => 1000
             })

    invalid_document = %{
      "objects" => [
        %{
          "type" => "Path",
          "path" => [],
          "mapItemId" => Ecto.UUID.generate(),
          "mapEntityType" => "continent",
          "mapEntityId" => other_continent.id
        }
      ]
    }

    assert {:error, :entity_outside_world} =
             Maps.save_map_document(map_document, %{
               "document" => invalid_document,
               "width" => 1200,
               "height" => 800
             })

    persisted_map = Maps.get_world_map(world, map_document.id)
    assert persisted_map.document == original_document
    assert persisted_map.width == 1600
    assert [%{item_key: ^original_item_id}] = Maps.list_map_items(persisted_map)
  end

  test "persists grouped texture strokes as one map item" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    document = %{
      "objects" => [
        %{
          "type" => "Group",
          "objects" => [%{"type" => "Path", "path" => []}],
          "mapItemId" => Ecto.UUID.generate(),
          "mapKind" => "texture-forest",
          "mapLayer" => "terrain",
          "mapX" => 240.0,
          "mapY" => 180.0
        }
      ]
    }

    assert {:ok, _map_document} =
             Maps.save_world_map(world, %{
               "document" => document,
               "width" => 1600,
               "height" => 1000
             })

    assert [%{object_type: "Group", kind: "texture-forest"}] =
             Maps.list_world_map_items(world)
  end

  test "persists custom layer definitions and custom layer item ids" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    custom_layer_id = Ecto.UUID.generate()

    document = %{
      "mapLayers" => [
        %{
          "id" => "terrain",
          "name" => "Terrain",
          "visible" => true,
          "locked" => false
        },
        %{
          "id" => custom_layer_id,
          "name" => "Coast details",
          "visible" => false,
          "locked" => true
        }
      ],
      "activeMapLayer" => custom_layer_id,
      "objects" => [
        %{
          "type" => "Path",
          "path" => [],
          "mapItemId" => Ecto.UUID.generate(),
          "mapLayer" => custom_layer_id,
          "mapX" => 100,
          "mapY" => 120
        }
      ]
    }

    assert {:ok, map_document} =
             Maps.save_world_map(world, %{
               "document" => document,
               "width" => 1600,
               "height" => 1000
             })

    assert map_document.document == document
    assert [%{layer: ^custom_layer_id}] = Maps.list_map_items(map_document)
  end

  test "rejects objects assigned to undeclared custom layers" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    document = %{
      "mapLayers" => [
        %{
          "id" => "terrain",
          "name" => "Terrain",
          "visible" => true,
          "locked" => false
        }
      ],
      "objects" => [
        %{
          "type" => "Path",
          "path" => [],
          "mapItemId" => Ecto.UUID.generate(),
          "mapLayer" => Ecto.UUID.generate()
        }
      ]
    }

    assert {:error, changeset} =
             Maps.save_world_map(world, %{
               "document" => document,
               "width" => 1600,
               "height" => 1000
             })

    assert "contains an object assigned to an undeclared layer" in errors_on(changeset).document
  end

  test "rejects malformed custom layer entries without raising" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    assert {:error, changeset} =
             Maps.save_world_map(world, %{
               "document" => %{
                 "mapLayers" => ["terrain"],
                 "objects" => []
               },
               "width" => 1600,
               "height" => 1000
             })

    assert "contains an invalid layer" in errors_on(changeset).document
  end

  test "persists coordinates and an explicit geography association" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})

    document = %{
      "objects" => [
        %{
          "type" => "Path",
          "path" => [],
          "mapItemId" => Ecto.UUID.generate(),
          "mapKind" => "mountains",
          "mapLayer" => "terrain",
          "mapEntityType" => "continent",
          "mapEntityId" => continent.id,
          "mapEntityName" => continent.name,
          "mapX" => 425.5,
          "mapY" => 318.25,
          "angle" => 15.0,
          "scaleX" => 1.25,
          "scaleY" => 0.75
        }
      ]
    }

    assert {:ok, _map_document} =
             Maps.save_world_map(world, %{
               "document" => document,
               "width" => 1600,
               "height" => 1000
             })

    assert [map_item] = Maps.list_world_map_items(world)
    assert map_item.continent_id == continent.id
    assert map_item.name == "Tamriel"
    assert map_item.x == 425.5
    assert map_item.y == 318.25
    assert map_item.angle == 15.0
    assert map_item.scale_x == 1.25
    assert map_item.scale_y == 0.75
  end

  test "rejects geography associations from another world" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, other_world} = Worlds.create_world(%{name: "Mundus"})
    {:ok, other_continent} = Worlds.create_continent(other_world, %{name: "Akavir"})

    document = %{
      "objects" => [
        %{
          "type" => "Path",
          "path" => [],
          "mapItemId" => Ecto.UUID.generate(),
          "mapLayer" => "terrain",
          "mapEntityType" => "continent",
          "mapEntityId" => other_continent.id,
          "mapX" => 10,
          "mapY" => 20
        }
      ]
    }

    assert {:error, :entity_outside_world} =
             Maps.save_world_map(world, %{
               "document" => document,
               "width" => 1600,
               "height" => 1000
             })

    assert Maps.get_world_map(world) == nil
  end
end
