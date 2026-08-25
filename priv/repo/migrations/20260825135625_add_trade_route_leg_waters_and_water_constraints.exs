defmodule AncientStones.Repo.Migrations.AddTradeRouteLegWatersAndWaterConstraints do
  use Ecto.Migration

  def up do
    alter table(:water_body_connections) do
      add :navigation_directionality, :text
    end

    execute """
    UPDATE water_body_connections
    SET navigation_directionality = CASE
      WHEN navigability = 'none' THEN 'none'
      ELSE 'two_way'
    END
    """

    alter table(:water_body_connections) do
      modify :navigation_directionality, :text, null: false
    end

    drop constraint(:water_body_connections, :water_body_connections_distance_non_negative)

    create constraint(:water_body_connections, :water_body_connections_distance_positive,
             check: "distance_km IS NULL OR distance_km > 0"
           )

    create constraint(:water_body_connections, :water_body_connections_navigation_directionality,
             check: "navigation_directionality IN ('none', 'one_way', 'two_way')"
           )

    create constraint(:water_body_connections, :water_body_connections_navigation_consistency,
             check:
               "(navigability = 'none' AND navigation_directionality = 'none') OR (navigability <> 'none' AND navigation_directionality <> 'none')"
           )

    create constraint(:water_body_connections, :water_body_connections_hydrologic_semantics,
             check:
               "(connection_type = 'flows_into' AND directionality = 'one_way') OR (connection_type <> 'flows_into' AND directionality = 'two_way')"
           )

    execute """
    CREATE UNIQUE INDEX water_body_connections_symmetric_link_index
    ON water_body_connections (
      LEAST(origin_water_body_id, destination_water_body_id),
      GREATEST(origin_water_body_id, destination_water_body_id),
      connection_type
    )
    """

    drop constraint(:trade_route_legs, :trade_route_legs_distance_non_negative)

    create constraint(:trade_route_legs, :trade_route_legs_distance_positive,
             check: "distance_km > 0"
           )

    create constraint(:trade_route_legs, :trade_route_legs_mode_water_consistency,
             check:
               "(transport_mode IN ('sea', 'river') AND water_body_id IS NOT NULL) OR (transport_mode IN ('road', 'trail', 'caravan') AND water_body_id IS NULL) OR transport_mode = 'mixed'"
           )

    create table(:trade_route_leg_waters, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :trade_route_leg_id,
          references(:trade_route_legs, type: :binary_id, on_delete: :delete_all), null: false

      add :water_body_id, references(:water_bodies, type: :binary_id, on_delete: :restrict),
        null: false

      add :position, :integer, null: false
      add :distance_km, :decimal
      add :description, :text
      timestamps(type: :utc_datetime)
    end

    create unique_index(:trade_route_leg_waters, [:trade_route_leg_id, :position])

    create unique_index(:trade_route_leg_waters, [:trade_route_leg_id, :water_body_id],
             name: :trade_route_leg_waters_unique_water_index
           )

    create index(:trade_route_leg_waters, [:water_body_id])

    create constraint(:trade_route_leg_waters, :trade_route_leg_waters_position_positive,
             check: "position > 0"
           )

    create constraint(:trade_route_leg_waters, :trade_route_leg_waters_distance_positive,
             check: "distance_km IS NULL OR distance_km > 0"
           )

    execute """
    INSERT INTO trade_route_leg_waters (
      id,
      trade_route_leg_id,
      water_body_id,
      position,
      distance_km,
      inserted_at,
      updated_at
    )
    SELECT
      gen_random_uuid(),
      id,
      water_body_id,
      1,
      distance_km,
      inserted_at,
      updated_at
    FROM trade_route_legs
    WHERE water_body_id IS NOT NULL
    """
  end

  def down do
    drop table(:trade_route_leg_waters)

    drop constraint(:trade_route_legs, :trade_route_legs_mode_water_consistency)
    drop constraint(:trade_route_legs, :trade_route_legs_distance_positive)

    create constraint(:trade_route_legs, :trade_route_legs_distance_non_negative,
             check: "distance_km >= 0"
           )

    execute "DROP INDEX water_body_connections_symmetric_link_index"

    drop constraint(
           :water_body_connections,
           :water_body_connections_hydrologic_semantics
         )

    drop constraint(
           :water_body_connections,
           :water_body_connections_navigation_consistency
         )

    drop constraint(
           :water_body_connections,
           :water_body_connections_navigation_directionality
         )

    drop constraint(:water_body_connections, :water_body_connections_distance_positive)

    create constraint(:water_body_connections, :water_body_connections_distance_non_negative,
             check: "distance_km IS NULL OR distance_km >= 0"
           )

    alter table(:water_body_connections) do
      remove :navigation_directionality
    end
  end
end
