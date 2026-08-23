defmodule AncientStones.Repo.Migrations.AddContinentScopeToPoliticalOffices do
  use Ecto.Migration

  def up do
    alter table(:political_offices) do
      add :continent_id,
          references(:continents, type: :binary_id, on_delete: :delete_all)
    end

    create index(:political_offices, [:continent_id])

    create unique_index(:political_offices, [:continent_id, :office],
             where: "continent_id IS NOT NULL"
           )

    drop constraint(:political_offices, :political_offices_scope_target)

    create constraint(:political_offices, :political_offices_scope_target,
             check:
               "(scope = 'continent' AND continent_id IS NOT NULL AND province_id IS NULL AND hold_id IS NULL) OR " <>
                 "(scope = 'province' AND continent_id IS NULL AND province_id IS NOT NULL AND hold_id IS NULL) OR " <>
                 "(scope = 'hold' AND continent_id IS NULL AND province_id IS NULL AND hold_id IS NOT NULL)"
           )
  end

  def down do
    execute("DELETE FROM political_offices WHERE scope = 'continent'")

    drop constraint(:political_offices, :political_offices_scope_target)
    drop index(:political_offices, [:continent_id, :office])
    drop index(:political_offices, [:continent_id])

    alter table(:political_offices) do
      remove :continent_id
    end

    create constraint(:political_offices, :political_offices_scope_target,
             check:
               "(scope = 'province' AND province_id IS NOT NULL AND hold_id IS NULL) OR " <>
                 "(scope = 'hold' AND hold_id IS NOT NULL AND province_id IS NULL)"
           )
  end
end
