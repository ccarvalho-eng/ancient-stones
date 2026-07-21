defmodule AncientStones.Repo.Migrations.AddMapCoordinatesToGeography do
  use Ecto.Migration

  def change do
    alter table(:continents) do
      add :map_x, :integer
      add :map_y, :integer
      add :visibility, :string
    end

    alter table(:provinces) do
      add :map_x, :integer
      add :map_y, :integer
      add :visibility, :string
    end

    alter table(:holds) do
      add :map_x, :integer
      add :map_y, :integer
      add :visibility, :string
    end

    alter table(:locations) do
      add :map_x, :integer
      add :map_y, :integer
      add :visibility, :string
    end

    create constraint(:continents, :continents_visibility_check,
             check: "visibility IN ('known', 'rumored', 'hidden', 'lost')"
           )

    create constraint(:provinces, :provinces_visibility_check,
             check: "visibility IN ('known', 'rumored', 'hidden', 'lost')"
           )

    create constraint(:holds, :holds_visibility_check,
             check: "visibility IN ('known', 'rumored', 'hidden', 'lost')"
           )

    create constraint(:locations, :locations_visibility_check,
             check: "visibility IN ('known', 'rumored', 'hidden', 'lost')"
           )
  end
end
