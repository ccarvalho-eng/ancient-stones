defmodule AncientStones.Repo.Migrations.AddLockVersionToMapDocuments do
  use Ecto.Migration

  def change do
    alter table(:map_documents) do
      add :lock_version, :integer, null: false, default: 1
    end
  end
end
