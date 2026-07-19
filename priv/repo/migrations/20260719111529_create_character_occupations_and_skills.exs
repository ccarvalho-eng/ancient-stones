defmodule AncientStones.Repo.Migrations.CreateCharacterOccupationsAndSkills do
  use Ecto.Migration

  def change do
    create table(:occupations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :category, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:occupations, [:world_id, :name])

    create table(:skills, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :category, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:skills, [:world_id, :name])

    create table(:character_occupations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :character_id, references(:characters, type: :binary_id, on_delete: :delete_all),
        null: false

      add :occupation_id, references(:occupations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :rank, :text
      add :primary, :boolean, null: false, default: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:character_occupations, [:occupation_id])
    create unique_index(:character_occupations, [:character_id, :occupation_id])
    create unique_index(:character_occupations, [:character_id], where: "\"primary\" = true")

    create table(:character_skills, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :character_id, references(:characters, type: :binary_id, on_delete: :delete_all),
        null: false

      add :skill_id, references(:skills, type: :binary_id, on_delete: :delete_all), null: false
      add :level, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:character_skills, [:skill_id])
    create unique_index(:character_skills, [:character_id, :skill_id])
  end
end
