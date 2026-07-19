defmodule AncientStones.Repo.Migrations.CreateItemEffects do
  use Ecto.Migration

  def change do
    create table(:effects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :category, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:effects, [:world_id, :name])
    create index(:effects, [:world_id, :category])

    create table(:item_effects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :item_id, references(:items, type: :binary_id, on_delete: :delete_all), null: false
      add :effect_id, references(:effects, type: :binary_id, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:item_effects, [:item_id, :effect_id])
    create unique_index(:item_effects, [:item_id, :position])
    create index(:item_effects, [:effect_id])
  end
end
