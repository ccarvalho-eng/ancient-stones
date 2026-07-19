defmodule AncientStones.Repo.Migrations.CreateHoldOffices do
  use Ecto.Migration

  def change do
    create table(:political_offices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :world_id, references(:worlds, type: :binary_id, on_delete: :delete_all), null: false
      add :province_id, references(:provinces, type: :binary_id, on_delete: :delete_all)
      add :hold_id, references(:holds, type: :binary_id, on_delete: :delete_all)
      add :character_id, references(:characters, type: :binary_id, on_delete: :nilify_all)
      add :office, :text, null: false
      add :scope, :text, null: false
      add :politics, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:political_offices, [:world_id])
    create index(:political_offices, [:province_id])
    create index(:political_offices, [:hold_id])
    create index(:political_offices, [:character_id])

    create constraint(:political_offices, :political_offices_scope_target,
             check:
               "(scope = 'province' AND province_id IS NOT NULL AND hold_id IS NULL) OR (scope = 'hold' AND hold_id IS NOT NULL AND province_id IS NULL)"
           )

    create unique_index(:political_offices, [:province_id, :office], where: "hold_id IS NULL")

    create unique_index(:political_offices, [:hold_id, :office], where: "hold_id IS NOT NULL")
  end
end
