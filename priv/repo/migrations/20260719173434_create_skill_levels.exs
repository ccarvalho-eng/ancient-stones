defmodule AncientStones.Repo.Migrations.CreateSkillLevels do
  use Ecto.Migration

  def change do
    create table(:skill_levels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :skill_id, references(:skills, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :rank, :integer, null: false
      add :minimum_value, :integer
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:skill_levels, [:skill_id])
    create unique_index(:skill_levels, [:skill_id, :name])
    create unique_index(:skill_levels, [:skill_id, :rank])
  end
end
