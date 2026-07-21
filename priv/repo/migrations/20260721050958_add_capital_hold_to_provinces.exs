defmodule AncientStones.Repo.Migrations.AddCapitalHoldToProvinces do
  use Ecto.Migration

  def change do
    alter table(:provinces) do
      add :capital_hold_id, references(:holds, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:provinces, [:capital_hold_id])
  end
end
