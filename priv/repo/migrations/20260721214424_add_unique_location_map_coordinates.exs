defmodule AncientStones.Repo.Migrations.AddUniqueLocationMapCoordinates do
  use Ecto.Migration

  def change do
    create unique_index(:locations, [:hold_id, :map_x, :map_y],
             where: "map_x IS NOT NULL AND map_y IS NOT NULL",
             name: :locations_hold_id_map_coordinates_index
           )
  end
end
