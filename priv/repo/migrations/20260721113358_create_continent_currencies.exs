defmodule AncientStones.Repo.Migrations.CreateContinentCurrencies do
  use Ecto.Migration

  def change do
    create table(:continent_currencies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text

      add :continent_id, references(:continents, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:continent_currencies, [:continent_id])
  end
end
