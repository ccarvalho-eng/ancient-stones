defmodule AncientStones.Repo.Migrations.CreateMapItems do
  use Ecto.Migration

  def change do
    create table(:map_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :item_key, :binary_id, null: false
      add :object_type, :string, null: false
      add :kind, :string
      add :layer, :string, null: false
      add :position, :integer, null: false
      add :name, :string
      add :icon_author, :string
      add :x, :float, null: false
      add :y, :float, null: false
      add :angle, :float, null: false, default: 0.0
      add :scale_x, :float, null: false, default: 1.0
      add :scale_y, :float, null: false, default: 1.0
      add :object_data, :map, null: false, default: %{}

      add :map_document_id,
          references(:map_documents, type: :binary_id, on_delete: :delete_all),
          null: false

      add :continent_id, references(:continents, type: :binary_id, on_delete: :nilify_all)
      add :province_id, references(:provinces, type: :binary_id, on_delete: :nilify_all)
      add :hold_id, references(:holds, type: :binary_id, on_delete: :nilify_all)
      add :location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create constraint(:map_items, :map_items_single_entity_check,
             check: "num_nonnulls(continent_id, province_id, hold_id, location_id) <= 1"
           )

    create unique_index(:map_items, [:map_document_id, :item_key])

    create unique_index(:map_items, [:map_document_id, :continent_id],
             where: "continent_id IS NOT NULL"
           )

    create unique_index(:map_items, [:map_document_id, :province_id],
             where: "province_id IS NOT NULL"
           )

    create unique_index(:map_items, [:map_document_id, :hold_id], where: "hold_id IS NOT NULL")

    create unique_index(:map_items, [:map_document_id, :location_id],
             where: "location_id IS NOT NULL"
           )

    create index(:map_items, [:continent_id])
    create index(:map_items, [:province_id])
    create index(:map_items, [:hold_id])
    create index(:map_items, [:location_id])
  end
end
