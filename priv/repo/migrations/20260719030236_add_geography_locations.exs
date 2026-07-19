defmodule AncientStones.Repo.Migrations.AddGeographyLocations do
  use Ecto.Migration

  def change do
    create table(:location_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :world_id, references(:worlds, on_delete: :delete_all, type: :binary_id), null: false

      add :parent_id, references(:location_types, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:location_types, [:world_id])
    create index(:location_types, [:parent_id])

    create unique_index(:location_types, [:world_id, :name],
             where: "parent_id IS NULL",
             name: :location_types_world_id_name_root_index
           )

    create unique_index(:location_types, [:world_id, :parent_id, :name],
             where: "parent_id IS NOT NULL",
             name: :location_types_world_id_parent_id_name_index
           )

    create table(:locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :hold_id, references(:holds, on_delete: :delete_all, type: :binary_id), null: false

      add :parent_location_id, references(:locations, on_delete: :nilify_all, type: :binary_id)

      add :location_type_id,
          references(:location_types, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:locations, [:hold_id])
    create index(:locations, [:parent_location_id])
    create index(:locations, [:location_type_id])

    create unique_index(:locations, [:hold_id, :name],
             where: "parent_location_id IS NULL",
             name: :locations_hold_id_name_root_index
           )

    create unique_index(:locations, [:hold_id, :parent_location_id, :name],
             where: "parent_location_id IS NOT NULL",
             name: :locations_hold_id_parent_location_id_name_index
           )

    alter table(:holds) do
      add :capital_location_id, references(:locations, on_delete: :nilify_all, type: :binary_id)
    end

    create index(:holds, [:capital_location_id])
  end
end
