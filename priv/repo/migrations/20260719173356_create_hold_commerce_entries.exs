defmodule AncientStones.Repo.Migrations.CreateHoldCommerceEntries do
  use Ecto.Migration

  def change do
    create table(:hold_commerce_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :hold_id, references(:holds, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :kind, :text, null: false
      add :category, :text
      add :amount, :integer
      add :currency, :text
      add :frequency, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:hold_commerce_entries, [:hold_id])
    create unique_index(:hold_commerce_entries, [:hold_id, :name])
  end
end
