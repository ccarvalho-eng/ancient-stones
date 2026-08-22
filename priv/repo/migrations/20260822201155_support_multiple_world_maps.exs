defmodule AncientStones.Repo.Migrations.SupportMultipleWorldMaps do
  use Ecto.Migration

  def up do
    alter table(:map_documents) do
      add :name, :string
      add :description, :text
      add :kind, :string

      add :parent_map_id,
          references(:map_documents, type: :binary_id, on_delete: :nilify_all)
    end

    execute "UPDATE map_documents SET name = 'World Map', kind = 'world' WHERE name IS NULL"

    alter table(:map_documents) do
      modify :name, :string, null: false
      modify :kind, :string, null: false
    end

    drop unique_index(:map_documents, [:world_id])
    create index(:map_documents, [:world_id])
    create index(:map_documents, [:parent_map_id])
    create unique_index(:map_documents, [:world_id, :name])

    create constraint(:map_documents, :map_documents_kind_check,
             check: "kind IN ('world', 'region', 'city', 'interior', 'dungeon')"
           )

    create constraint(:map_documents, :map_documents_parent_not_self_check,
             check: "parent_map_id IS NULL OR parent_map_id <> id"
           )
  end

  def down do
    require Logger

    Logger.warning(
      "Skipping rollback for support_multiple_world_maps because map hierarchy data cannot be restored safely"
    )

    :ok
  end
end
