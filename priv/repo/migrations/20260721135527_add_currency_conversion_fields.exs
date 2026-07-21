defmodule AncientStones.Repo.Migrations.AddCurrencyConversionFields do
  use Ecto.Migration

  def change do
    alter table(:continent_currencies) do
      add :value_per_unit, :numeric
      add :value_basis, :string
    end
  end
end
