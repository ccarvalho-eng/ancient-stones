defmodule AncientStones.Repo.Migrations.CreateCharacterRoles do
  use Ecto.Migration

  def change do
    create table(:character_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :world_id, references(:worlds, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:character_roles, [:world_id])
    create unique_index(:character_roles, [:world_id, :name])

    alter table(:characters) do
      add :character_role_id,
          references(:character_roles, on_delete: :nilify_all, type: :binary_id)
    end

    create index(:characters, [:character_role_id])
  end
end
