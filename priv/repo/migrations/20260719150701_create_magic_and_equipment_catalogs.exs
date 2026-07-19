defmodule AncientStones.Repo.Migrations.CreateMagicAndEquipmentCatalogs do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :health, :integer
      add :magicka, :integer
      add :stamina, :integer
    end

    create table(:spells, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :school, :text
      add :level, :text
      add :magicka_cost, :integer
      add :source, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:spells, [:world_id, :name])

    create table(:items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :category, :text
      add :kind, :text
      add :material, :text
      add :hands, :text
      add :damage, :integer
      add :critical_damage, :integer
      add :weight, :decimal
      add :value, :integer
      add :source, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:items, [:world_id, :name])
    create index(:items, [:world_id, :category])

    create table(:character_inventory_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :character_id, references(:characters, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :text, null: false
      add :position, :integer, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:character_inventory_categories, [:character_id, :name])
    create unique_index(:character_inventory_categories, [:character_id, :position])

    create table(:character_inventory_items, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :character_id, references(:characters, type: :binary_id, on_delete: :delete_all),
        null: false

      add :inventory_category_id,
          references(:character_inventory_categories, type: :binary_id, on_delete: :nilify_all)

      add :item_id, references(:items, type: :binary_id, on_delete: :nilify_all)
      add :name, :text
      add :quantity, :integer, null: false, default: 1
      add :equipped, :boolean, null: false, default: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:character_inventory_items, [:character_id])
    create index(:character_inventory_items, [:inventory_category_id])
    create index(:character_inventory_items, [:item_id])

    create table(:character_spellbook_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :character_id, references(:characters, type: :binary_id, on_delete: :delete_all),
        null: false

      add :spell_id, references(:spells, type: :binary_id, on_delete: :delete_all), null: false
      add :favorite, :boolean, null: false, default: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:character_spellbook_entries, [:character_id, :spell_id])
    create index(:character_spellbook_entries, [:spell_id])

    create table(:skill_trees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :category, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:skill_trees, [:world_id, :name])

    alter table(:skills) do
      add :skill_tree_id, references(:skill_trees, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:skills, [:skill_tree_id])

    create table(:skill_tree_perks, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :skill_tree_id, references(:skill_trees, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :text, null: false
      add :required_level, :integer
      add :ranks, :integer, null: false, default: 1
      add :position, :integer, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:skill_tree_perks, [:skill_tree_id, :name])
    create unique_index(:skill_tree_perks, [:skill_tree_id, :position])
  end
end
