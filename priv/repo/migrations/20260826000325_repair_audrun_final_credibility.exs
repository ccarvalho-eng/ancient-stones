defmodule AncientStones.Repo.Migrations.RepairAudrunFinalCredibility do
  use Ecto.Migration

  def up do
    repair_astronomy_and_historical_baseline()
    repair_geography_and_routes()
    repair_economy_and_trade()
    repair_politics_and_taxation()
    repair_religion_water_and_material_culture()
    repair_ecology()
    repair_timeline()
  end

  def down do
    :ok
  end

  defp repair_astronomy_and_historical_baseline do
    execute """
    DO $audrun$
    DECLARE
      audrun_world_id uuid := '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM worlds WHERE id = audrun_world_id AND name = 'Audrun'
      ) THEN
        RETURN;
      END IF;

      UPDATE worlds
      SET day_length_hours = 24.0,
          orbital_period_days = 365,
          description = 'Audrun turns beneath Eldvar''s warm light, an ancient rocky world of broad oceans, strongly marked seasons, and shifting bands of cloud.',
          updated_at = NOW()
      WHERE id = audrun_world_id;

      UPDATE galaxies galaxy
      SET description = 'Elvstjerne is a barred spiral galaxy. From Audrun, its disk appears as a pale, irregular band across the night sky, broken by dark lanes of interstellar dust.',
          updated_at = NOW()
      FROM worlds world
      WHERE world.id = audrun_world_id
        AND galaxy.id = world.galaxy_id;

      UPDATE moons
      SET orbital_period_days = 27.08,
          description = 'Mani is a pale, cratered moon completing its sidereal passage in 27.08 days. Its visible phase cycle lasts about 29.25 days and provides the coastal count used by fishers and navigators.',
          tidal_role = 'Mani raises the principal coastal tide. Spring and neap tides govern harbor depths, weir work, coastal departures, and the strongest estuary currents.',
          updated_at = NOW()
      WHERE world_id = audrun_world_id AND name = 'Mani';

      UPDATE calendars ca
      SET description = 'Tyrven Reckoning divides the ordinary year into twelve named months totaling 364 days. Seven public feast days follow the final winter month every seventh year, giving a long-term mean of 365 days.',
          intercalation_rule = 'Seven intercalary feast days follow the final winter month every seventh year. Courts suspend ordinary hearings while households settle accounts and renew public oaths.',
          updated_at = NOW()
      FROM continents c
      WHERE ca.continent_id = c.id AND c.world_id = audrun_world_id;

      UPDATE civilizations
      SET era = 'Early High Middle Ages',
          description = 'The Tyrven communities belong to an early high-medieval society whose older assembly law, elective crown, provincial jarldoms, clinker-built fleets, household cults, and silver-weight customs remain in active use. Public writing, chartered mines, permanent markets, measured tolls, and maintained trunk routes have expanded since the Compact. Provincial law permits any recognized adult of a ruling lineage to present a succession claim, although wealth, kin support, estate management, and the assent of the thing determine whether that claim succeeds. Tyrven writing uses an unaccented common spelling while preserving compounds inherited from several regional dialects.',
          updated_at = NOW()
      WHERE world_id = audrun_world_id AND name = 'Tyrven Communities';

      UPDATE holds h
      SET terrain = 'forest',
          climate = 'cold',
          climate_zone = 'Subarctic birch and conifer woodland grading into open upland tundra',
          mean_winter_temperature_c = -13,
          mean_summer_temperature_c = 10,
          annual_precipitation_mm = 620,
          frost_free_days = 75,
          description = 'Bjornmark is a broad northern woodland of birch, pine, wet meadow, and open upland. Moose, hare, capercaillie, lynx, wolf, and bear follow the forest edge and river valleys, while exposed ridges carry tundra vegetation.',
          updated_at = NOW()
      FROM provinces p
      JOIN continents c ON c.id = p.continent_id
      WHERE h.province_id = p.id AND c.world_id = audrun_world_id AND h.name = 'Bjornmark';

      UPDATE holds h
      SET mean_winter_temperature_c = -6,
          mean_summer_temperature_c = 10,
          annual_precipitation_mm = 1050,
          frost_free_days = 105,
          climate_zone = 'Cold maritime fjord coast moderated by a western current branch',
          description = 'Hrafnsfjord occupies a deep western inlet where a branch of the milder western current limits winter ice near the settled shore. Outer headlands remain exposed to cold water, strong wind, and drifting sea ice.',
          updated_at = NOW()
      FROM provinces p
      JOIN continents c ON c.id = p.continent_id
      WHERE h.province_id = p.id AND c.world_id = audrun_world_id AND h.name = 'Hrafnsfjord';

      UPDATE water_bodies
      SET description = 'The northern sea lies beyond the Frostgard fjords. Cold northern water dominates the outer basin, while a narrower western branch carries milder water toward Hrafnsfjord during much of the year.',
          updated_at = NOW()
      WHERE world_id = audrun_world_id AND name = 'Hrafn Sea';

      UPDATE water_bodies
      SET name = 'Vikvatn',
          description = 'A fish-rich lake beside Vatnvik, with sheltered beaches, reed margins, and a small seasonal camp.',
          updated_at = NOW()
      WHERE world_id = audrun_world_id AND name = 'Vatnvik Lake';

      UPDATE locations l
      SET name = 'Vikvatn',
          description = replace(l.description, 'Vatnvik Lake', 'Vikvatn'),
          updated_at = NOW()
      FROM holds h
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      WHERE l.hold_id = h.id AND c.world_id = audrun_world_id AND l.name = 'Vatnvik Lake';

      INSERT INTO location_types (id, world_id, name, description, inserted_at, updated_at)
      VALUES (
        gen_random_uuid(), audrun_world_id, 'Saltworks',
        'A coastal working site where brine is concentrated and boiled in shallow iron pans, then dried, weighed, and packed for trade.',
        NOW(), NOW()
      )
      ON CONFLICT (world_id, name) WHERE parent_id IS NULL DO UPDATE
      SET description = EXCLUDED.description, updated_at = NOW();

      INSERT INTO locations (
        id, hold_id, location_type_id, water_body_id, name, description,
        visibility, population_estimate, record_scope, inserted_at, updated_at
      )
      SELECT gen_random_uuid(), h.id, lt.id, wb.id, 'South Brine Houses',
        'South Brine Houses stand above the sheltered gulf shore. Crews pre-concentrate seawater in lined settling beds, boil brine with managed coppice and purchased peat, and pack coarse salt in sealed tubs for fisheries and inland markets.',
        'known', 90, 'specific', NOW(), NOW()
      FROM holds h
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      JOIN location_types lt ON lt.world_id = c.world_id AND lt.name = 'Saltworks'
      JOIN water_bodies wb ON wb.world_id = c.world_id AND wb.name = 'Solmark Gulf'
      WHERE c.world_id = audrun_world_id AND h.name = 'Sudhavn'
      ON CONFLICT DO NOTHING;

      INSERT INTO hold_commerce_entries (
        id, hold_id, name, kind, category, amount, currency, frequency,
        accounting_scope, coverage_scope, description, inserted_at, updated_at
      )
      SELECT gen_random_uuid(), h.id, 'South Brine Houses', 'income', 'salt making',
        7200, 'Tyrven Pennings', 'seasonal', 'gross_output', 'named_establishment',
        'The brine houses produce coarse preserving salt during the calmer months. Fuel, pan repair, and barrel supply limit output more than access to seawater.',
        NOW(), NOW()
      FROM holds h
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      WHERE c.world_id = audrun_world_id AND h.name = 'Sudhavn'
      ON CONFLICT (hold_id, name) DO UPDATE
      SET frequency = EXCLUDED.frequency,
          accounting_scope = EXCLUDED.accounting_scope,
          coverage_scope = EXCLUDED.coverage_scope,
          description = EXCLUDED.description,
          updated_at = NOW();
    END
    $audrun$;
    """
  end

  defp repair_geography_and_routes do
    execute """
    WITH weighted AS (
      SELECT h.id,
             p.id AS province_id,
             p.area_km2,
             0.85 + (mod(abs(hashtext(h.name)), 31)::numeric / 100) AS weight,
             row_number() OVER (PARTITION BY p.id ORDER BY h.name) AS position
      FROM holds h
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ), allocated AS (
      SELECT weighted.*,
             floor(area_km2 * weight / sum(weight) OVER (PARTITION BY province_id))::bigint AS base_area
      FROM weighted
    ), final AS (
      SELECT allocated.*,
             base_area + CASE WHEN position = 1
               THEN area_km2 - sum(base_area) OVER (PARTITION BY province_id)
               ELSE 0 END AS corrected_area
      FROM allocated
    )
    UPDATE holds h
    SET area_km2 = final.corrected_area,
        updated_at = NOW()
    FROM final
    WHERE h.id = final.id;
    """

    execute """
    WITH ranked AS (
      SELECT l.id,
             l.hold_id,
             h.capital_location_id,
             h.latitude AS hold_latitude,
             h.longitude AS hold_longitude,
             h.area_km2,
             row_number() OVER (PARTITION BY h.id ORDER BY l.name, l.id) AS position,
             count(*) OVER (PARTITION BY h.id) AS location_count,
             radians(mod(abs(hashtext(l.name || l.id::text)), 360)) AS bearing,
             sqrt(h.area_km2::numeric / pi()) * 0.42 AS working_radius_km
      FROM locations l
      JOIN holds h ON h.id = l.hold_id
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ), placed AS (
      SELECT ranked.*,
             CASE WHEN id = capital_location_id THEN 0
               ELSE working_radius_km * sqrt(position::numeric / greatest(location_count, 1)) END AS radius_km
      FROM ranked
    )
    UPDATE locations l
    SET latitude = round(
          (placed.hold_latitude +
            (placed.radius_km * cos(placed.bearing) / 111.32))::numeric,
          6
        ),
        longitude = round(
          (placed.hold_longitude +
            (placed.radius_km * sin(placed.bearing) /
              (111.32 * greatest(cos(radians(placed.hold_latitude)), 0.20))))::numeric,
          6
        ),
        record_scope = CASE
          WHEN l.id = placed.capital_location_id THEN 'specific'
          ELSE 'representative'
        END,
        updated_at = NOW()
    FROM placed
    WHERE l.id = placed.id;
    """

    execute """
    WITH numbered AS (
      SELECT l.id,
             c.north_latitude,
             c.south_latitude,
             c.west_longitude,
             c.east_longitude,
             row_number() OVER (PARTITION BY h.id ORDER BY l.name, l.id) AS position
      FROM locations l
      JOIN holds h ON h.id = l.hold_id
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    )
    UPDATE locations l
    SET map_x = greatest(0, least(1000,
          round(((l.longitude - numbered.west_longitude) /
            (numbered.east_longitude - numbered.west_longitude)) * 1000)::integer
        )),
        map_y = greatest(0, least(1000,
          round(((numbered.north_latitude - l.latitude) /
            (numbered.north_latitude - numbered.south_latitude)) * 1000)::integer
        )),
        population_estimate = CASE
          WHEN h.capital_location_id = l.id THEN profile.urban_population_estimate
          WHEN lt.name = 'Farmstead' THEN 8 + mod(abs(hashtext(l.name)), 13)
          WHEN lt.name = 'Inn' THEN 8 + mod(abs(hashtext(l.name)), 23)
          WHEN lt.name = 'Shipyard' THEN 35 + mod(abs(hashtext(l.name)), 55)
          WHEN lt.name = 'Saltworks' THEN 90
          WHEN lt.name IN ('Seasonal Camp', 'Trail Shelter') THEN 6 + mod(abs(hashtext(l.name)), 25)
          ELSE NULL END,
        updated_at = NOW()
    FROM numbered, holds h, location_types lt, hold_economic_profiles profile
    WHERE l.id = numbered.id
    AND h.id = l.hold_id
    AND lt.id = l.location_type_id
    AND profile.hold_id = h.id;
    """

    execute """
    WITH measured AS (
      SELECT leg.id,
             origin_location.name AS origin_name,
             destination_location.name AS destination_name,
             leg.transport_mode,
             6371.0 * acos(least(1.0, greatest(-1.0,
               sin(radians(origin_location.latitude::double precision)) *
                 sin(radians(destination_location.latitude::double precision)) +
               cos(radians(origin_location.latitude::double precision)) *
                 cos(radians(destination_location.latitude::double precision)) *
               cos(radians(destination_location.longitude::double precision -
                 origin_location.longitude::double precision))
             ))) AS geodesic_km
      FROM trade_route_legs leg
      JOIN trade_routes route ON route.id = leg.trade_route_id
      JOIN trade_route_stops origin_stop ON origin_stop.id = leg.origin_stop_id
      JOIN trade_route_stops destination_stop ON destination_stop.id = leg.destination_stop_id
      JOIN locations origin_location ON origin_location.id = origin_stop.location_id
      JOIN locations destination_location ON destination_location.id = destination_stop.location_id
      WHERE route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ), corrected AS (
      SELECT measured.*,
             greatest(5.0, geodesic_km * CASE transport_mode
               WHEN 'sea' THEN 1.08
               WHEN 'river' THEN 1.12
               WHEN 'road' THEN 1.18
               WHEN 'trail' THEN 1.28
               WHEN 'caravan' THEN 1.22
               ELSE 1.20 END) AS corrected_distance,
             CASE transport_mode
               WHEN 'sea' THEN 72.0
               WHEN 'river' THEN 30.0
               WHEN 'road' THEN 24.0
               WHEN 'trail' THEN 18.0
               WHEN 'caravan' THEN 21.0
               ELSE 23.0 END AS daily_distance
      FROM measured
    )
    UPDATE trade_route_legs leg
    SET distance_km = round(corrected.corrected_distance::numeric, 1),
        typical_travel_days = round(
          (corrected.corrected_distance / corrected.daily_distance)::numeric,
          1
        ),
        description = corrected.origin_name || ' to ' || corrected.destination_name ||
          ' is a ' || round(corrected.corrected_distance::numeric, 1) ||
          '-kilometer ' || replace(corrected.transport_mode, '_', ' ') ||
          ' stage following the usable terrain and customary crossings.',
        updated_at = NOW()
    FROM corrected
    WHERE leg.id = corrected.id;
    """

    execute """
    WITH traversal_counts AS (
      SELECT link.trade_route_leg_id,
             count(*) AS traversal_count
      FROM trade_route_leg_waters link
      JOIN trade_route_legs leg ON leg.id = link.trade_route_leg_id
      JOIN trade_routes route ON route.id = leg.trade_route_id
      WHERE route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      GROUP BY link.trade_route_leg_id
    )
    UPDATE trade_route_leg_waters link
    SET distance_km = round((leg.distance_km / traversal_counts.traversal_count)::numeric, 1),
        updated_at = NOW()
    FROM trade_route_legs leg
    JOIN traversal_counts ON traversal_counts.trade_route_leg_id = leg.id
    WHERE link.trade_route_leg_id = leg.id;
    """

    execute """
    UPDATE trade_routes route
    SET distance_km = totals.distance_km,
        updated_at = NOW()
    FROM (
      SELECT leg.trade_route_id, round(sum(leg.distance_km), 1) AS distance_km
      FROM trade_route_legs leg
      JOIN trade_routes route ON route.id = leg.trade_route_id
      WHERE route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      GROUP BY leg.trade_route_id
    ) totals
    WHERE route.id = totals.trade_route_id;
    """

    execute """
    WITH province_means AS (
      SELECT p.id,
             round(sum(h.mean_winter_temperature_c * h.area_km2) / sum(h.area_km2), 1) AS winter_c,
             round(sum(h.mean_summer_temperature_c * h.area_km2) / sum(h.area_km2), 1) AS summer_c,
             round(sum(h.annual_precipitation_mm * h.area_km2)::numeric / sum(h.area_km2))::integer AS precipitation_mm,
             round(sum(h.frost_free_days * h.area_km2)::numeric / sum(h.area_km2))::integer AS frost_free_days
      FROM provinces p
      JOIN holds h ON h.province_id = p.id
      JOIN continents c ON c.id = p.continent_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      GROUP BY p.id
    )
    UPDATE provinces p
    SET mean_winter_temperature_c = province_means.winter_c,
        mean_summer_temperature_c = province_means.summer_c,
        annual_precipitation_mm = province_means.precipitation_mm,
        frost_free_days = province_means.frost_free_days,
        updated_at = NOW()
    FROM province_means
    WHERE p.id = province_means.id;
    """
  end

  defp repair_economy_and_trade do
    execute """
    WITH weighted AS MATERIALIZED (
      SELECT profile.id,
             profile.hold_id,
             profile.population_estimate AS old_population,
             p.id AS province_id,
             sum(profile.population_estimate) OVER (PARTITION BY p.id) AS province_population,
             0.86 + (mod(abs(hashtext(h.name)), 29)::numeric / 100) AS weight,
             row_number() OVER (PARTITION BY p.id ORDER BY h.name) AS position,
             h.terrain,
             (h.id = p.capital_hold_id) AS provincial_capital
      FROM hold_economic_profiles profile
      JOIN holds h ON h.id = profile.hold_id
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ), allocated AS (
      SELECT weighted.*,
             floor(
               province_population * weight /
                 sum(weight) OVER (PARTITION BY province_id)
             )::bigint AS base_population
      FROM weighted
    ), final AS (
      SELECT allocated.*,
             base_population + CASE WHEN position = 1
               THEN province_population - sum(base_population) OVER (PARTITION BY province_id)
               ELSE 0 END AS new_population
      FROM allocated
    )
    UPDATE commodity_balances balance
    SET annual_output = round(
          balance.annual_output * final.new_population / final.old_population,
          1
        ),
        annual_local_need = round(
          balance.annual_local_need * final.new_population / final.old_population,
          1
        ),
        stored_reserve = round(
          balance.stored_reserve * final.new_population / final.old_population,
          1
        ),
        updated_at = NOW()
    FROM final
    WHERE balance.hold_id = final.hold_id;
    """

    execute """
    WITH weighted AS MATERIALIZED (
      SELECT profile.id,
             profile.hold_id,
             p.id AS province_id,
             sum(profile.population_estimate) OVER (PARTITION BY p.id) AS province_population,
             0.86 + (mod(abs(hashtext(h.name)), 29)::numeric / 100) AS weight,
             row_number() OVER (PARTITION BY p.id ORDER BY h.name) AS position,
             h.name AS hold_name,
             h.terrain,
             (h.id = p.capital_hold_id) AS provincial_capital
      FROM hold_economic_profiles profile
      JOIN holds h ON h.id = profile.hold_id
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ), allocated AS (
      SELECT weighted.*,
             floor(
               province_population * weight /
                 sum(weight) OVER (PARTITION BY province_id)
             )::bigint AS base_population
      FROM weighted
    ), final AS (
      SELECT allocated.*,
             base_population + CASE WHEN position = 1
               THEN province_population - sum(base_population) OVER (PARTITION BY province_id)
               ELSE 0 END AS new_population
      FROM allocated
    ), measured AS (
      SELECT final.*,
             4.70 + (mod(abs(hashtext(hold_name || 'household')), 46)::numeric / 100) AS household_size,
             CASE terrain
               WHEN 'plains' THEN 0.62
               WHEN 'riverlands' THEN 0.54
               WHEN 'coast' THEN 0.22
               WHEN 'forest' THEN 0.23
               WHEN 'wetlands' THEN 0.20
               WHEN 'marsh' THEN 0.16
               WHEN 'highlands' THEN 0.18
               WHEN 'mountain' THEN 0.10
               WHEN 'tundra' THEN 0.07
               ELSE 0.28 END AS arable_per_person,
             CASE terrain
               WHEN 'plains' THEN 0.48
               WHEN 'riverlands' THEN 0.42
               WHEN 'coast' THEN 0.38
               WHEN 'forest' THEN 0.52
               WHEN 'wetlands' THEN 0.46
               WHEN 'marsh' THEN 0.40
               WHEN 'highlands' THEN 0.68
               WHEN 'mountain' THEN 0.72
               WHEN 'tundra' THEN 0.82
               ELSE 0.50 END AS pasture_per_person
      FROM final
    )
    UPDATE hold_economic_profiles profile
    SET population_estimate = measured.new_population,
        household_estimate = greatest(1, round(measured.new_population / measured.household_size)),
        urban_population_estimate = round(
          measured.new_population *
            CASE WHEN measured.provincial_capital THEN 0.12
                 WHEN measured.terrain IN ('coast', 'riverlands', 'plains') THEN 0.08
                 ELSE 0.055 END
        ),
        arable_hectares_estimate = round(measured.new_population * measured.arable_per_person),
        pasture_hectares_estimate = round(measured.new_population * measured.pasture_per_person),
        description = measured.hold_name || ' supports about ' || measured.new_population ||
          ' people. The estimate distinguishes its principal settlement from a wider rural population of farms, seasonal workers, and dispersed households.',
        updated_at = NOW()
    FROM measured
    WHERE profile.id = measured.id;
    """

    execute """
    UPDATE commodity_balances balance
    SET stored_reserve = round(greatest(
          balance.stored_reserve,
          balance.annual_local_need * CASE
            WHEN p.name IN ('Frostgard', 'Jarnfell', 'Skeldvik') THEN 0.45
            ELSE 0.38 END
        ), 1),
        description = 'Cleaned grain equivalent available to households after seed retention and ordinary milling losses. The reserve is sized for one widespread poor harvest, with rationing required if failures continue.',
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    WHERE balance.hold_id = h.id
      AND c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND balance.commodity = 'Staple grain equivalent';
    """

    execute """
    UPDATE commodity_balances balance
    SET annual_output = round(greatest(balance.annual_output, balance.annual_local_need * 1.08), 1),
        stored_reserve = round(greatest(balance.stored_reserve, balance.annual_local_need * 0.20), 1),
        bad_year_output_percentage = 82,
        description = 'Hay, straw, sedges, leaf fodder, and sheltered browse reserved for breeding and working animals. Autumn slaughter and seasonal movement reduce the herd before the stored-fodder season.',
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    WHERE balance.hold_id = h.id
      AND c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND balance.commodity = 'Winter fodder';
    """

    execute """
    UPDATE commodity_balances balance
    SET stored_reserve = round(greatest(balance.stored_reserve, balance.annual_local_need * 0.25), 1),
        bad_year_output_percentage = greatest(balance.bad_year_output_percentage, 75),
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    WHERE balance.hold_id = h.id
      AND c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND balance.commodity = 'Preserved fish';
    """

    execute """
    UPDATE commodity_balances balance
    SET stored_reserve = round(greatest(balance.stored_reserve, balance.annual_local_need * 0.18), 1),
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    WHERE balance.hold_id = h.id
      AND c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND balance.commodity = 'Livestock food products';
    """

    execute """
    UPDATE hold_economic_profiles profile
    SET staple_reserve_months = round((balance.stored_reserve / balance.annual_local_need) * 12, 1),
        updated_at = NOW()
    FROM commodity_balances balance
    JOIN holds h ON h.id = balance.hold_id
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    WHERE profile.hold_id = h.id
      AND balance.commodity = 'Staple grain equivalent'
      AND c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    """

    execute """
    WITH disconnected AS (
      SELECT h.id AS hold_id,
             h.name AS hold_name,
             h.terrain,
             h.capital_location_id AS destination_location_id,
             p.capital_hold_id,
             capital.name AS capital_name,
             capital.capital_location_id AS origin_location_id,
             CASE
               WHEN h.terrain = 'coast' THEN 'mixed'
               WHEN h.terrain IN ('mountain', 'highlands', 'tundra', 'snowfield') THEN 'trail'
               ELSE 'road' END AS mode
      FROM holds h
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      JOIN holds capital ON capital.id = p.capital_hold_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
        AND h.id <> p.capital_hold_id
        AND NOT EXISTS (
          SELECT 1
          FROM trade_route_stops stop
          JOIN trade_routes route ON route.id = stop.trade_route_id
          JOIN locations location ON location.id = stop.location_id
          WHERE route.world_id = c.world_id AND location.hold_id = h.id
        )
    )
    INSERT INTO trade_routes (
      id, world_id, name, transport_mode, distance_km, annual_capacity_tonnes,
      capacity_basis, seasonality, risk, status, origin_hold_id, destination_hold_id,
      origin_location_id, destination_location_id, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), '7d897439-8af4-4baf-8617-722959777bdc'::uuid,
      disconnected.hold_name || ' Feeder Way', disconnected.mode, 1,
      CASE disconnected.mode WHEN 'trail' THEN 1800 WHEN 'mixed' THEN 4800 ELSE 3200 END,
      'Estimated ordinary-year capacity after weather closures, maintenance days, return loads, and animal or vessel availability.',
      CASE WHEN disconnected.mode = 'road' THEN 'year_round' ELSE 'spring_to_autumn' END,
      CASE WHEN disconnected.mode = 'road' THEN 'moderate' ELSE 'high' END,
      'active', disconnected.capital_hold_id, disconnected.hold_id,
      disconnected.origin_location_id, disconnected.destination_location_id,
      'The feeder way links ' || disconnected.hold_name || ' with the provincial market at ' ||
        disconnected.capital_name || '. Households use it for taxes, court attendance, grain, tools, and compact return freight.',
      NOW(), NOW()
    FROM disconnected
    ON CONFLICT (world_id, name) DO UPDATE
    SET annual_capacity_tonnes = EXCLUDED.annual_capacity_tonnes,
        capacity_basis = EXCLUDED.capacity_basis,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    WITH feeder AS (
      SELECT route.id AS route_id,
             route.origin_location_id,
             route.destination_hold_id,
             destination_hold.capital_location_id AS destination_location_id
      FROM trade_routes route
      JOIN holds destination_hold ON destination_hold.id = route.destination_hold_id
      WHERE route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
        AND route.name LIKE '% Feeder Way'
    )
    INSERT INTO trade_route_stops (
      id, trade_route_id, location_id, position, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), feeder.route_id, stop.location_id, stop.position,
      'A regular exchange and rest point on the feeder route.', NOW(), NOW()
    FROM feeder
    CROSS JOIN LATERAL (
      VALUES (1, feeder.origin_location_id), (2, feeder.destination_location_id)
    ) AS stop(position, location_id)
    ON CONFLICT (trade_route_id, position) DO UPDATE
    SET location_id = EXCLUDED.location_id,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    WITH feeder AS (
      SELECT route.id AS route_id,
             route.transport_mode,
             route.seasonality,
             route.risk,
             origin_stop.id AS origin_stop_id,
             destination_stop.id AS destination_stop_id,
             origin_location.name AS origin_name,
             destination_location.name AS destination_name,
             6371.0 * acos(least(1.0, greatest(-1.0,
               sin(radians(origin_location.latitude::double precision)) *
                 sin(radians(destination_location.latitude::double precision)) +
               cos(radians(origin_location.latitude::double precision)) *
                 cos(radians(destination_location.latitude::double precision)) *
               cos(radians(destination_location.longitude::double precision -
                 origin_location.longitude::double precision))
             ))) * CASE route.transport_mode
               WHEN 'trail' THEN 1.28 WHEN 'road' THEN 1.18 ELSE 1.20 END AS distance_km
      FROM trade_routes route
      JOIN trade_route_stops origin_stop ON origin_stop.trade_route_id = route.id AND origin_stop.position = 1
      JOIN trade_route_stops destination_stop ON destination_stop.trade_route_id = route.id AND destination_stop.position = 2
      JOIN locations origin_location ON origin_location.id = origin_stop.location_id
      JOIN locations destination_location ON destination_location.id = destination_stop.location_id
      WHERE route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
        AND route.name LIKE '% Feeder Way'
    )
    INSERT INTO trade_route_legs (
      id, trade_route_id, origin_stop_id, destination_stop_id, position,
      transport_mode, distance_km, typical_travel_days, seasonality, risk,
      description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), feeder.route_id, feeder.origin_stop_id, feeder.destination_stop_id, 1,
      feeder.transport_mode, round(feeder.distance_km::numeric, 1),
      round((feeder.distance_km / CASE feeder.transport_mode
        WHEN 'trail' THEN 18.0 WHEN 'road' THEN 24.0 ELSE 23.0 END)::numeric, 1),
      feeder.seasonality, feeder.risk,
      feeder.origin_name || ' to ' || feeder.destination_name ||
        ' follows the maintained local way and its customary crossings.', NOW(), NOW()
    FROM feeder
    ON CONFLICT (trade_route_id, position) DO UPDATE
    SET distance_km = EXCLUDED.distance_km,
        typical_travel_days = EXCLUDED.typical_travel_days,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    UPDATE trade_routes route
    SET distance_km = leg.distance_km,
        destination_location_id = destination_stop.location_id,
        updated_at = NOW()
    FROM trade_route_legs leg
    JOIN trade_route_stops destination_stop
      ON destination_stop.trade_route_id = leg.trade_route_id AND destination_stop.position = 2
    WHERE route.id = leg.trade_route_id
      AND route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND route.name LIKE '% Feeder Way';
    """

    execute """
    UPDATE trade_flows flow
    SET unit_mass_kg = CASE
          WHEN lower(flow.unit) LIKE '%tonne%' THEN 1000
          WHEN lower(flow.unit) LIKE '%sack%' THEN 50
          WHEN lower(flow.unit) LIKE '%barrel%' THEN 100
          WHEN lower(flow.unit) LIKE '%crate%' THEN 40
          WHEN lower(flow.unit) LIKE '%bundle%' THEN 25
          WHEN lower(flow.unit) LIKE '%packload%' THEN 80
          WHEN lower(flow.unit) LIKE '%cart%' OR lower(flow.unit) LIKE '%load%' THEN 500
          WHEN lower(flow.unit) LIKE '%head%' THEN 350
          ELSE 50 END,
        annual_consignment_count = CASE flow.frequency
          WHEN 'daily' THEN 300
          WHEN 'weekly' THEN 45
          WHEN 'monthly' THEN 10
          WHEN 'seasonal' THEN 4
          ELSE 1 END,
        updated_at = NOW()
    FROM trade_routes route
    WHERE flow.trade_route_id = route.id
      AND route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    """

    execute """
    INSERT INTO trade_flows (
      id, trade_route_id, currency_id, commodity, category, quantity, unit,
      declared_value, frequency, coverage_scope, quantity_basis,
      unit_mass_kg, annual_consignment_count, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), route.id, currency.id, 'staple grain inward', 'staple food',
      round(greatest(0, balance.annual_local_need - balance.annual_output) * 1.10, 1),
      'tonnes', round(greatest(0, balance.annual_local_need - balance.annual_output) * 22, 0),
      'annual', 'estimated_total',
      'Ordinary-year grain requirement above recorded local output, including a ten-percent handling margin.',
      1000, 1,
      'Grain moves from the provincial market to the destination hold in witnessed wagon, pack, or coastal lots.',
      NOW(), NOW()
    FROM trade_routes route
    JOIN holds destination_hold ON destination_hold.id = route.destination_hold_id
    JOIN commodity_balances balance
      ON balance.hold_id = destination_hold.id AND balance.commodity = 'Staple grain equivalent'
    JOIN provinces p ON p.id = destination_hold.province_id
    JOIN continents c ON c.id = p.continent_id
    JOIN continent_currencies currency ON currency.continent_id = c.id
    WHERE route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND route.name LIKE '% Feeder Way'
      AND balance.annual_local_need > balance.annual_output
    ON CONFLICT (trade_route_id, commodity) DO UPDATE
    SET quantity = EXCLUDED.quantity,
        declared_value = EXCLUDED.declared_value,
        coverage_scope = EXCLUDED.coverage_scope,
        quantity_basis = EXCLUDED.quantity_basis,
        unit_mass_kg = EXCLUDED.unit_mass_kg,
        annual_consignment_count = EXCLUDED.annual_consignment_count,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    INSERT INTO trade_flows (
      id, trade_route_id, currency_id, commodity, category, quantity, unit,
      declared_value, frequency, coverage_scope, quantity_basis,
      unit_mass_kg, annual_consignment_count, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), route.id, currency.id, 'boiled sea salt', 'preservation supply',
      CASE route.name WHEN 'South Grain Road' THEN 1400 ELSE 900 END,
      'tonnes', CASE route.name WHEN 'South Grain Road' THEN 52000 ELSE 35000 END,
      'annual', 'estimated_total',
      'Ordinary-year packed salt dispatched from the South Brine Houses after local fishery needs.',
      1000, 1,
      'Coarse salt from Sudhavn moves to inland markets and western fisheries in sealed tubs and lined sacks.',
      NOW(), NOW()
    FROM trade_routes route
    JOIN continents c ON c.world_id = route.world_id
    JOIN continent_currencies currency ON currency.continent_id = c.id
    WHERE route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND route.name IN ('South Grain Road', 'Brannskar Coastal Run')
    ON CONFLICT (trade_route_id, commodity) DO UPDATE
    SET quantity = EXCLUDED.quantity,
        declared_value = EXCLUDED.declared_value,
        coverage_scope = EXCLUDED.coverage_scope,
        quantity_basis = EXCLUDED.quantity_basis,
        unit_mass_kg = EXCLUDED.unit_mass_kg,
        annual_consignment_count = EXCLUDED.annual_consignment_count,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    WITH flow_mass AS (
      SELECT route.id,
             coalesce(sum(
               flow.quantity * flow.unit_mass_kg * flow.annual_consignment_count / 1000
             ), 0) AS annual_tonnage
      FROM trade_routes route
      LEFT JOIN trade_flows flow ON flow.trade_route_id = route.id
      WHERE route.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      GROUP BY route.id
    )
    UPDATE trade_routes route
    SET annual_capacity_tonnes = round(greatest(
          CASE route.transport_mode
            WHEN 'sea' THEN 28000
            WHEN 'river' THEN 18000
            WHEN 'road' THEN 12000
            WHEN 'trail' THEN 2200
            WHEN 'caravan' THEN 7000
            ELSE 16000 END,
          flow_mass.annual_tonnage * 1.25
        ), 1),
        capacity_basis = 'Estimated ordinary-year throughput with a twenty-five-percent margin above recorded cargo, allowing for return freight, uneven departures, weather closure, repairs, and empty repositioning.',
        updated_at = NOW()
    FROM flow_mass
    WHERE route.id = flow_mass.id;
    """

    execute """
    UPDATE hold_commerce_entries
    SET description = regexp_replace(
          description,
          '(^|[.!?]\\s+)(Monthly|Each month|Every month)',
          CASE frequency
            WHEN 'annual' THEN '\\1Annual'
            WHEN 'seasonal' THEN '\\1Seasonal'
            ELSE '\\1Regular' END,
          'gi'
        ),
        updated_at = NOW()
    WHERE hold_id IN (
      SELECT h.id
      FROM holds h
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    );
    """
  end

  defp repair_politics_and_taxation do
    execute """
    INSERT INTO character_roles (id, world_id, name, description, inserted_at, updated_at)
    SELECT
      gen_random_uuid(),
      '7d897439-8af4-4baf-8617-722959777bdc'::uuid,
      'Succession Claimant',
      'An acknowledged adult of a ruling lineage who may present a claim when a provincial jarldom becomes vacant.',
      NOW(), NOW()
    WHERE EXISTS (
      SELECT 1
      FROM worlds
      WHERE id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
        AND name = 'Audrun'
    )
    ON CONFLICT (world_id, name) DO UPDATE
    SET description = EXCLUDED.description, updated_at = NOW();
    """

    execute """
    WITH successors(province_name, successor_name, gender, politics, description) AS (
      VALUES
        ('Brannskar', 'Hakon Hauksson', 'male',
         'Protect quarry households from excessive levies while keeping the southern sea lanes open.',
         'Hakon manages the family''s transport agreements and is known for patient bargaining with quarry crews and shipowners.'),
        ('Eirholm', 'Ragnhild Ketilsdottir', 'female',
         'Preserve free navigation while making weir and towpath accounts visible to every affected thing.',
         'Ragnhild studies water levels, toll accounts, and witness testimony before committing herself to a public position.'),
        ('Frostgard', 'Ivar Knutsson', 'male',
         'Keep winter stores and grazing agreements ahead of prestige building or distant war.',
         'Ivar spends much of the year among grazing households and is respected for remembering obligations that richer visitors overlook.'),
        ('Jarnfell', 'Sigrid Arnesdottir', 'female',
         'Bind mine charters to drainage, road repair, and compensation for injured workers.',
         'Sigrid is exacting with ore tallies and skeptical of promises unsupported by timber, labor, or tested metal.'),
        ('Myrholt', 'Torleif Eiriksson', 'male',
         'Defend common reed beds, drainage work, and access across the fen causeways.',
         'Torleif listens longer than most claimants and is slow to forgive anyone who shifts flood risk onto poorer households.'),
        ('Ravnskog', 'Bjorn Stensson', 'male',
         'Limit cutting to marked woodland and make fire control a shared cost of the timber trade.',
         'Bjorn knows the hauling seasons and prefers enforceable cutting plans to speeches about inexhaustible forest.'),
        ('Skeldvik', 'Ragna Torfinnsdottir', 'female',
         'Maintain pilotage, rescue stores, and ship repair before expanding harbor dues.',
         'Ragna has a navigator''s caution and judges policy by whether crews can still return safely in poor weather.'),
        ('Solmark', 'Astrid Gudmundsdottir', 'female',
         'Protect irrigation turns, seed reserves, and public market measures from estate monopolies.',
         'Astrid is an able estate manager who treats reliable weights and water schedules as the basis of political peace.'),
        ('Vardalen', 'Hakon Ragnarsson', 'male',
         'Keep the central roads, bridge accounts, and Great Thing neutral between the provinces.',
         'Hakon is an orderly administrator with a talent for reconciling road obligations across districts that distrust one another.')
    )
    INSERT INTO characters (
      id, world_id, race_id, character_role_id, home_location_id,
      name, gender, title, role, politics, status, social_status, life_stage,
      wealth_band, health, magicka, stamina, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), jarl.world_id, jarl.race_id, role.id, jarl.home_location_id,
      successors.successor_name, successors.gender,
      'Recognized kin of the ' || successors.province_name || ' jarl',
      'Succession claimant', successors.politics, 'alive', 'magnate', 'adult',
      'wealthy', 100, 100, 100, successors.description, NOW(), NOW()
    FROM successors
    JOIN provinces p ON p.name = successors.province_name
    JOIN political_offices office
      ON office.province_id = p.id AND office.office = 'Jarl'
    JOIN characters jarl ON jarl.id = office.character_id
    JOIN character_roles role
      ON role.world_id = jarl.world_id AND role.name = 'Succession Claimant'
    WHERE jarl.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ON CONFLICT (world_id, name) DO UPDATE
    SET politics = EXCLUDED.politics,
        description = EXCLUDED.description,
        home_location_id = EXCLUDED.home_location_id,
        character_role_id = EXCLUDED.character_role_id,
        updated_at = NOW();
    """

    execute """
    WITH successor_names(province_name, successor_name) AS (
      VALUES
        ('Brannskar', 'Hakon Hauksson'),
        ('Eirholm', 'Ragnhild Ketilsdottir'),
        ('Frostgard', 'Ivar Knutsson'),
        ('Jarnfell', 'Sigrid Arnesdottir'),
        ('Myrholt', 'Torleif Eiriksson'),
        ('Ravnskog', 'Bjorn Stensson'),
        ('Skeldvik', 'Ragna Torfinnsdottir'),
        ('Solmark', 'Astrid Gudmundsdottir'),
        ('Vardalen', 'Hakon Ragnarsson')
    ), pairs AS (
      SELECT office.id AS office_id,
             jarl.id AS jarl_id,
             successor.id AS successor_id,
             successor_names.province_name
      FROM successor_names
      JOIN provinces p ON p.name = successor_names.province_name
      JOIN political_offices office
        ON office.province_id = p.id AND office.office = 'Jarl'
      JOIN characters jarl ON jarl.id = office.character_id
      JOIN characters successor
        ON successor.world_id = jarl.world_id AND successor.name = successor_names.successor_name
      WHERE jarl.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    )
    UPDATE political_offices office
    SET designated_successor_id = pairs.successor_id,
        updated_at = NOW()
    FROM pairs
    WHERE office.id = pairs.office_id;
    """

    execute """
    WITH successor_names(province_name, successor_name) AS (
      VALUES
        ('Brannskar', 'Hakon Hauksson'), ('Eirholm', 'Ragnhild Ketilsdottir'),
        ('Frostgard', 'Ivar Knutsson'), ('Jarnfell', 'Sigrid Arnesdottir'),
        ('Myrholt', 'Torleif Eiriksson'), ('Ravnskog', 'Bjorn Stensson'),
        ('Skeldvik', 'Ragna Torfinnsdottir'), ('Solmark', 'Astrid Gudmundsdottir'),
        ('Vardalen', 'Hakon Ragnarsson')
    )
    INSERT INTO household_memberships (
      id, household_id, character_id, role, status, is_primary,
      description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), membership.household_id, successor.id,
      'other_kin', 'active', false,
      successor.name || ' is acknowledged within the ruling household as an adult kinsman or kinswoman with a lawful succession claim.',
      NOW(), NOW()
    FROM successor_names
    JOIN provinces p ON p.name = successor_names.province_name
    JOIN political_offices office ON office.province_id = p.id AND office.office = 'Jarl'
    JOIN household_memberships membership
      ON membership.character_id = office.character_id AND membership.is_primary
    JOIN characters successor
      ON successor.world_id = office.world_id AND successor.name = successor_names.successor_name
    WHERE office.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ON CONFLICT (household_id, character_id) DO UPDATE
    SET role = EXCLUDED.role,
        status = EXCLUDED.status,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    WITH successor_names(province_name, successor_name) AS (
      VALUES
        ('Brannskar', 'Hakon Hauksson'), ('Eirholm', 'Ragnhild Ketilsdottir'),
        ('Frostgard', 'Ivar Knutsson'), ('Jarnfell', 'Sigrid Arnesdottir'),
        ('Myrholt', 'Torleif Eiriksson'), ('Ravnskog', 'Bjorn Stensson'),
        ('Skeldvik', 'Ragna Torfinnsdottir'), ('Solmark', 'Astrid Gudmundsdottir'),
        ('Vardalen', 'Hakon Ragnarsson')
    ), pairs AS (
      SELECT office.world_id,
             CASE WHEN office.character_id::text < successor.id::text
               THEN office.character_id ELSE successor.id END AS character_a_id,
             CASE WHEN office.character_id::text < successor.id::text
               THEN successor.id ELSE office.character_id END AS character_b_id,
             successor_names.province_name
      FROM successor_names
      JOIN provinces p ON p.name = successor_names.province_name
      JOIN political_offices office ON office.province_id = p.id AND office.office = 'Jarl'
      JOIN characters successor
        ON successor.world_id = office.world_id AND successor.name = successor_names.successor_name
      WHERE office.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    )
    INSERT INTO character_relationships (
      id, world_id, character_a_id, character_b_id, relationship_type,
      character_a_role, character_b_role, status, start_date_label,
      description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), pairs.world_id, pairs.character_a_id, pairs.character_b_id,
      'siblings', 'member of the ruling sibling pair', 'member of the ruling sibling pair',
      'active', 'Before the present reckoning',
      'The siblings belong to the leading ' || pairs.province_name ||
        ' lineage. One presently holds the jarldom; the other is an acknowledged claimant whose support remains necessary but does not guarantee succession.',
      NOW(), NOW()
    FROM pairs
    ON CONFLICT (world_id, character_a_id, character_b_id, relationship_type) DO UPDATE
    SET description = EXCLUDED.description, updated_at = NOW();
    """

    execute """
    UPDATE political_offices office
    SET term_started_year = CASE
          WHEN office.office = 'High King' THEN 412
          WHEN office.office = 'Lawspeaker' THEN 416
          WHEN office.office = 'Speaker of Jarls' THEN 418
          WHEN office.office = 'Jarl' THEN CASE (
            SELECT province.name FROM provinces province WHERE province.id = office.province_id
          )
            WHEN 'Brannskar' THEN 404 WHEN 'Eirholm' THEN 397
            WHEN 'Frostgard' THEN 409 WHEN 'Jarnfell' THEN 392
            WHEN 'Myrholt' THEN 413 WHEN 'Ravnskog' THEN 399
            WHEN 'Skeldvik' THEN 406 WHEN 'Solmark' THEN 388
            WHEN 'Vardalen' THEN 401 END
          WHEN office.scope = 'hold' THEN 416 + mod(abs(hashtext(coalesce(
            (SELECT hold.name FROM holds hold WHERE hold.id = office.hold_id),
            office.office
          ))), 3)
          ELSE 409 + mod(abs(hashtext(office.office)), 9) END,
        selection_method = CASE
          WHEN office.office = 'High King' THEN 'Chosen from eligible magnates by the Great Thing after public nomination, negotiation among the provinces, and acclamation by the jarls'
          WHEN office.office = 'Lawspeaker' THEN 'Elected by the Great Thing for a three-year term from candidates able to recite, compare, and explain the public law'
          WHEN office.office = 'Speaker of Jarls' THEN 'Chosen for one year and recallable by the nine provincial jarls'
          WHEN office.office = 'Jarl' THEN 'A recognized adult of the leading lineage presents a claim; the provincial thing confirms the candidate and the High King records the settlement'
          WHEN office.scope = 'hold' THEN 'Chosen at the local thing for a three-year term and confirmed by the provincial jarl'
          ELSE 'Appointed by the High King before council witnesses and answerable for public accounts' END,
        succession_rule = CASE
          WHEN office.office = 'High King' THEN 'A vacancy calls an extraordinary Great Thing. Kinship, wealth, judgment, alliances, and service strengthen a claim, but no child inherits the crown automatically.'
          WHEN office.office = 'Jarl' THEN 'Any recognized adult of the ruling lineage may claim. The provincial thing weighs household leadership, competence, alliances, and lawful conduct; recognition may pass through daughters as well as sons.'
          ELSE office.succession_rule END,
        updated_at = NOW()
    WHERE office.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    """

    execute """
    INSERT INTO assemblies (
      id, world_id, continent_id, location_id, name, scope, status, meeting_cycle,
      membership_rule, jurisdiction, appeal_path, enforcement, description,
      inserted_at, updated_at
    )
    SELECT gen_random_uuid(), c.world_id, c.id, thing.id,
      'Great Thing of Tyrven', 'continent', 'active',
      'The principal assembly meets once each summer; extraordinary sessions require the lawspeaker and at least five provincial delegations.',
      'Free householders may attend and speak through local delegations. Jarls, appointed law-panel members, recognized litigants, witnesses, and petitioners have defined places in the proceedings.',
      'Confirms the High King and lawspeaker, enacts common law, hears disputes between provinces, reviews extraordinary levies, and grants exemptions from common rules.',
      'Local judgments pass to the provincial thing. Matters between provinces, disputed provincial judgments, and questions of common law may reach the Great Thing.',
      'Judgments are enforced by named sureties, property seizure, compensation, outlawry, and the coordinated authority of the provinces; the lawspeaker commands no private army.',
      'Tyrven''s common assembly occupies the Vardalen thing ground near the central roads, where pasture, water, fuel, booths, and guarded storage support a large seasonal gathering.',
      NOW(), NOW()
    FROM continents c
    JOIN provinces p ON p.continent_id = c.id AND p.name = 'Vardalen'
    JOIN holds h ON h.id = p.capital_hold_id
    JOIN locations thing ON thing.hold_id = h.id AND thing.name = 'Vardalen Thing'
    WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ON CONFLICT (world_id, name) DO UPDATE
    SET location_id = EXCLUDED.location_id,
        meeting_cycle = EXCLUDED.meeting_cycle,
        membership_rule = EXCLUDED.membership_rule,
        jurisdiction = EXCLUDED.jurisdiction,
        appeal_path = EXCLUDED.appeal_path,
        enforcement = EXCLUDED.enforcement,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    INSERT INTO assemblies (
      id, world_id, province_id, location_id, name, scope, status, meeting_cycle,
      membership_rule, jurisdiction, appeal_path, enforcement, description,
      inserted_at, updated_at
    )
    SELECT gen_random_uuid(), c.world_id, p.id, thing.id,
      p.name || ' Provincial Thing', 'province', 'active',
      'Meets at the opening of summer and after harvest, with emergency sessions called for invasion, famine, flood, or a disputed succession.',
      'Each hold sends customary delegates chosen at its local thing. Free householders may attend, while litigants, witnesses, law-panel members, the jarl, and the jarl''s steward have formal duties.',
      'Confirms the provincial jarl, hears appeals from local things, coordinates roads and defense, apportions provincial dues, and settles disputes crossing hold boundaries.',
      'Unresolved disputes involving common law, another province, or misconduct by the jarl may be carried to the Great Thing.',
      'Sureties and local officers execute judgments. The jarl supplies force only after a witnessed order or an immediate breach of the peace.',
      'The provincial assembly is held at the principal thing ground of ' || p.name || '.',
      NOW(), NOW()
    FROM provinces p
    JOIN continents c ON c.id = p.continent_id
    JOIN holds capital ON capital.id = p.capital_hold_id
    JOIN locations thing ON thing.hold_id = capital.id
    JOIN location_types lt ON lt.id = thing.location_type_id AND lt.name = 'Thing Site'
    WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ON CONFLICT (world_id, name) DO UPDATE
    SET location_id = EXCLUDED.location_id,
        membership_rule = EXCLUDED.membership_rule,
        jurisdiction = EXCLUDED.jurisdiction,
        appeal_path = EXCLUDED.appeal_path,
        enforcement = EXCLUDED.enforcement,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    INSERT INTO assemblies (
      id, world_id, hold_id, location_id, name, scope, status, meeting_cycle,
      membership_rule, jurisdiction, appeal_path, enforcement, description,
      inserted_at, updated_at
    )
    SELECT gen_random_uuid(), c.world_id, h.id, thing.id,
      h.name || ' Local Thing', 'hold', 'active',
      'Meets at least twice yearly and when urgent disputes, inheritance, boundary work, or communal maintenance require witnesses.',
      'Free householders may attend. Established households select law-panel members and delegates according to local custom; dependents may appear as litigants or witnesses through recognized advocates.',
      'Hears ordinary disputes, witnesses transfers and inheritances, organizes common labor, selects local officers, and records delegates for the provincial thing.',
      'A party may appeal a disputed judgment to the provincial thing after providing surety for attendance and costs.',
      'Named sureties, compensation schedules, distraint, temporary exclusion from common resources, and provincial assistance support enforcement.',
      thing.description,
      NOW(), NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    JOIN locations thing ON thing.hold_id = h.id
    JOIN location_types lt ON lt.id = thing.location_type_id AND lt.name = 'Thing Site'
    WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ON CONFLICT (world_id, name) DO UPDATE
    SET location_id = EXCLUDED.location_id,
        membership_rule = EXCLUDED.membership_rule,
        jurisdiction = EXCLUDED.jurisdiction,
        appeal_path = EXCLUDED.appeal_path,
        enforcement = EXCLUDED.enforcement,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    UPDATE tax_policies policy
    SET effective_from_year = CASE policy.name
          WHEN 'Common Leidang Obligation' THEN 143
          WHEN 'Royal Guesting Due' THEN 173
          WHEN 'Kaldhavn Harbor Due' THEN 367
          WHEN 'Vardborg Bridge Toll' THEN 236
          WHEN 'Eirsund Weir and Channel Due' THEN 237
          ELSE 389 END,
        effective_to_year = NULL,
        description = policy.description || ' Receipts assigned to an office remain public funds recorded before the appropriate thing and may be spent only on the stated service.',
        updated_at = NOW()
    WHERE policy.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    """

    execute """
    UPDATE tax_assessments assessment
    SET assessment_period_label = 'Year 418 ordinary assessment',
        assessed_unit = CASE policy.rate_basis
          WHEN 'percentage' THEN 'pennings of witnessed taxable value'
          ELSE policy.commodity END,
        assessed_unit_count = CASE policy.name
          WHEN 'Royal Guesting Due' THEN 198500
          WHEN 'Common Leidang Obligation' THEN 12000
          WHEN 'Eirsund Weir and Channel Due' THEN 5600
          WHEN 'Kaldhavn Harbor Due' THEN 4100
          WHEN 'Myrholt Causeway Toll' THEN 4300
          WHEN 'Vardborg Bridge Toll' THEN 8500
          ELSE round((assessment.cash_yield / nullif(policy.rate, 0)) * 100, 2) END,
        coverage_percentage = CASE policy.name
          WHEN 'Royal Guesting Due' THEN 75
          WHEN 'Common Leidang Obligation' THEN 92
          ELSE 90 + mod(abs(hashtext(policy.name)), 11) END,
        cash_yield = CASE policy.name
          WHEN 'Royal Guesting Due' THEN 420000
          WHEN 'Common Leidang Obligation' THEN 65000
          ELSE assessment.cash_yield END,
        in_kind_value = CASE policy.name
          WHEN 'Royal Guesting Due' THEN 650000
          WHEN 'Common Leidang Obligation' THEN 130000
          ELSE assessment.in_kind_value END,
        customary_labor_days = CASE policy.name
          WHEN 'Royal Guesting Due' THEN 90000
          WHEN 'Common Leidang Obligation' THEN 240000
          ELSE assessment.customary_labor_days END,
        valuation_basis = CASE policy.rate_basis
          WHEN 'percentage' THEN 'Taxable goods are grouped into witnessed value bands using public weights and seasonal market prices; the percentage is the accounting equivalent of those bands.'
          ELSE 'The count records eligible units observed or apportioned during year 418. Cash, goods, and labor are kept separately and converted only for the public assessment total.' END,
        description = 'Ordinary-year assessment for year 418, recording the eligible base, observed coverage, cash, goods, and customary labor without treating office shares as personal income.',
        updated_at = NOW()
    FROM tax_policies policy
    WHERE assessment.tax_policy_id = policy.id
      AND policy.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    """
  end

  defp repair_religion_water_and_material_culture do
    execute """
    WITH shrine_gods AS (
      SELECT l.id AS location_id,
             g.id AS god_id,
             CASE
               WHEN l.name IN ('South Headland Shrine') THEN 'Saeva'
               WHEN l.name IN ('Shrine Below Stone') THEN 'Keldra'
               ELSE g.name END AS matched_name
      FROM locations l
      JOIN holds h ON h.id = l.hold_id
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      JOIN location_types lt ON lt.id = l.location_type_id AND lt.name = 'Shrine'
      JOIN gods g ON g.world_id = c.world_id
      WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
        AND (
          l.name ILIKE '%' || g.name || '%' OR
          (l.name = 'South Headland Shrine' AND g.name = 'Saeva') OR
          (l.name = 'Shrine Below Stone' AND g.name = 'Keldra')
        )
    )
    INSERT INTO location_gods (
      id, location_id, god_id, role, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), shrine_gods.location_id, shrine_gods.god_id, 'primary',
      'The shrine''s customary observances, upkeep, and seasonal offerings are associated chiefly with ' || shrine_gods.matched_name || '.',
      NOW(), NOW()
    FROM shrine_gods
    ON CONFLICT (location_id, god_id) DO UPDATE
    SET role = EXCLUDED.role,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    WITH measurements(
      name, latitude, longitude, source_latitude, source_longitude,
      mouth_latitude, mouth_longitude, length_km, area_km2,
      drainage_area_km2, source_elevation_m, mean_discharge_m3_s
    ) AS (
      VALUES
        ('Eirwater', 56.0, 10.5, 54.75, 18.96, 50.2, 5.0, 1180, NULL, 168000, 460, 1350),
        ('Hrafn Sea', 70.0, -4.0, NULL, NULL, NULL, NULL, NULL, 690000, NULL, NULL, NULL),
        ('Hrafnsfjord', 68.25, 0.10, NULL, NULL, NULL, NULL, 118, 1250, 9200, NULL, NULL),
        ('Hrim River', 67.9, 11.5, 68.70, 9.30, 68.15, 14.20, 205, NULL, 14700, 620, 96),
        ('Isvatn', 68.70, 9.30, NULL, NULL, NULL, NULL, NULL, 680, 5400, 620, NULL),
        ('Langvatn', 54.75, 18.96, NULL, NULL, NULL, NULL, NULL, 1250, 16400, 145, NULL),
        ('Ravna', 63.3, 13.0, 65.33, 23.10, 60.83, -8.18, 1420, NULL, 112000, 710, 820),
        ('Sivvatn', 54.30, -2.20, NULL, NULL, NULL, NULL, NULL, 420, 7600, 18, NULL),
        ('Skeld Sea', 58.0, -14.5, NULL, NULL, NULL, NULL, NULL, 870000, NULL, NULL, NULL),
        ('Solmark Gulf', 49.7, 5.0, NULL, NULL, NULL, NULL, NULL, 91000, NULL, NULL, NULL),
        ('Steinvik', 62.63, -5.42, NULL, NULL, NULL, NULL, 84, 760, 6900, NULL, NULL),
        ('Svanesund', 61.95, -12.32, NULL, NULL, NULL, NULL, 62, 310, NULL, NULL, NULL),
        ('Ulf Sea', 68.0, 28.0, NULL, NULL, NULL, NULL, NULL, 760000, NULL, NULL, NULL),
        ('Ulf Shelf', 67.0, 22.0, NULL, NULL, NULL, NULL, NULL, 185000, NULL, NULL, NULL),
        ('Varda Estuary', 50.8, 5.4, NULL, NULL, NULL, NULL, 145, 2100, 168000, 0, 1450),
        ('Vikvatn', 57.00, 17.58, NULL, NULL, NULL, NULL, NULL, 540, 6100, 92, NULL),
        ('Vesthavnsund', 57.90, -10.94, NULL, NULL, NULL, NULL, 95, 480, NULL, NULL, NULL)
    )
    UPDATE water_bodies water
    SET latitude = measurements.latitude,
        longitude = measurements.longitude,
        source_latitude = measurements.source_latitude,
        source_longitude = measurements.source_longitude,
        mouth_latitude = measurements.mouth_latitude,
        mouth_longitude = measurements.mouth_longitude,
        length_km = measurements.length_km,
        area_km2 = measurements.area_km2,
        drainage_area_km2 = measurements.drainage_area_km2,
        source_elevation_m = measurements.source_elevation_m,
        mean_discharge_m3_s = measurements.mean_discharge_m3_s,
        updated_at = NOW()
    FROM measurements
    WHERE water.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND water.name = measurements.name;
    """

    execute """
    UPDATE items
    SET period_name = 'Present Tyrven working tradition',
        date_label = 'Made or maintained in the present generation',
        maker = source,
        provenance = 'A representative working object acquired through the trade or workshop named in its source field; no claim of unique antiquity is made.',
        authenticity = 'working',
        updated_at = NOW()
    WHERE world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    """

    execute """
    UPDATE items
    SET kind = 'splitting tool',
        source = 'Ravnskog timber workers',
        maker = 'Ravnskog smiths and timber workers',
        updated_at = NOW()
    WHERE world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND name = 'Splitting Wedges';
    """

    execute """
    WITH historical_items(
      name, category, kind, material, source, description, period_name,
      date_label, maker, provenance, authenticity, location_name, hold_name
    ) AS (
      VALUES
        ('Compact Oath Ring', 'historical object', 'oath ring', 'silver and iron',
         'Great Thing of Tyrven',
         'A heavy ring kept under three seals and displayed when the common compact is renewed. Wear and repairs show prolonged ceremonial handling.',
         'Age of the Nine Provinces', 'Year 1, repaired in years 143 and 347',
         'Original maker unrecorded; later repairs bear Vardalen marks',
         'The ring appears in assembly inventories from year 143 onward and is stored with the lawspeaker''s witnessed regalia.',
         'historic', 'Vardalen Thing', 'Vardborg'),
        ('Flood-Marked Bridge Timber', 'historical object', 'bridge timber', 'water-darkened oak',
         'Vardborg bridge stores',
         'A section of oak beam cut from the bridge works after the Great Eirwater Flood. Notches record peak water and later repair levels.',
         'Age of the Nine Provinces', 'Year 236',
         'Vardborg bridge crews',
         'Removed during the first post-flood rebuilding and retained in the bridge account house as a flood gauge and work record.',
         'historic', 'Great Bridge', 'Vardborg'),
        ('Iron Pass Measure Stone', 'historical object', 'road measure', 'dressed basalt',
         'Iron Pass road wardens',
         'A marked stone used to check cart width, wheel spacing, and the legal load at the opening of the high road.',
         'Age of the Nine Provinces', 'Year 117',
         'Brannskar stonecutters',
         'The stone remains beside the pass road and its dimensions recur in later maintenance accounts.',
         'historic', 'Forge Road Inn', 'Malmberg'),
        ('Western Pilot Board', 'historical object', 'pilotage board', 'oak with iron tally pins',
         'Kaldhavn harbor office',
         'An oak board recording pilot rotations, missing channel marks, rescue stores, and vessels awaiting a safe tide.',
         'Age of the Nine Provinces', 'Year 367',
         'Kaldhavn shipwrights and harbor clerks',
         'Entered in the first inventory made under the Western Harbor Compact and retained after replacement by newer boards.',
         'historic', 'Inner Harbor', 'Kaldhavn'),
        ('Old Reckoning Staff', 'historical object', 'calendar staff', 'ash wood with bronze bands',
         'Lawspeaker''s assembly chest',
         'A carved staff marking the twelve months, court openings, and the seven intercalary feast days adopted in the Reckoning Reform.',
         'Age of the Nine Provinces', 'Year 301',
         'Maker unrecorded; checked by the law panel',
         'Assembly tallies and later copies preserve the same sequence of cuts and bronze separators.',
         'historic', 'Vardalen Thing', 'Vardborg')
    )
    INSERT INTO items (
      id, world_id, find_location_id, name, category, kind, material, source,
      description, period_name, date_label, maker, provenance, authenticity,
      inserted_at, updated_at
    )
    SELECT gen_random_uuid(), c.world_id, l.id, historical_items.name,
      historical_items.category, historical_items.kind, historical_items.material,
      historical_items.source, historical_items.description, historical_items.period_name,
      historical_items.date_label, historical_items.maker, historical_items.provenance,
      historical_items.authenticity, NOW(), NOW()
    FROM historical_items
    JOIN holds h ON h.name = historical_items.hold_name
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    JOIN locations l ON l.hold_id = h.id AND l.name = historical_items.location_name
    WHERE c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
    ON CONFLICT (world_id, name) DO UPDATE
    SET find_location_id = EXCLUDED.find_location_id,
        description = EXCLUDED.description,
        period_name = EXCLUDED.period_name,
        date_label = EXCLUDED.date_label,
        maker = EXCLUDED.maker,
        provenance = EXCLUDED.provenance,
        authenticity = EXCLUDED.authenticity,
        updated_at = NOW();
    """
  end

  defp repair_ecology do
    execute """
    WITH ecology(name, diet, ecological_role, economic_uses, seasonal_pattern) AS (
      VALUES
        ('Beaver',
         'Willow, birch, aspen, aquatic plants, bark, twigs, and stored woody cuttings.',
         'Wetland engineer whose dams retain water, trap sediment, and create ponds used by fish, birds, and grazing animals.',
         'Hide, meat, castoreum, and occasional managed water control; dam removal is regulated where roads or fields are threatened.',
         'Pairs repair dams through the open-water season and store branches before freeze-up; winter activity continues beneath the ice.'),
        ('Brown Bear',
         'Roots, berries, mast, insects, fish, carrion, and occasional young ungulates or livestock.',
         'Large omnivore, scavenger, seed carrier, and intermittent predator at the edge of settled land.',
         'Hide, fat, meat, and protection bounties where repeated livestock losses occur.',
         'Bears feed heavily before winter denning; females emerge later with cubs and avoid busy settlements when possible.'),
        ('Brown Honeybee',
         'Nectar, pollen, stored honey, and water collected within the hive''s forage range.',
         'Managed pollinator of orchards, hay meadows, gardens, and woodland-edge plants.',
         'Honey, wax, orchard pollination, and small traded colonies.',
         'Colonies expand in spring, swarm in early summer, store through bloom, and cluster around reserves during winter.'),
        ('Capercaillie',
         'Pine needles, buds, berries, shoots, seeds, and insects taken especially by growing chicks.',
         'Large forest grouse that consumes woodland plants and supports lynx, foxes, raptors, and human hunters.',
         'Seasonal meat and feathers under local woodland hunting rules.',
         'Males gather at spring display grounds; broods feed on insects in summer and adults rely more heavily on conifer browse in winter.'),
        ('Common Eider',
         'Mussels, clams, snails, small crustaceans, sea urchins, and other shallow-water invertebrates.',
         'Coastal benthic feeder linking shellfish beds with marine predators and nesting-island nutrient cycles.',
         'Down gathered from managed nests after lining is replaced, with limited eggs and birds taken under island custom.',
         'Colonies gather on sheltered islands in spring; females nest close together and flocks move to open feeding water after breeding.'),
        ('Crag Goat',
         'Coarse grass, sedges, dwarf shrubs, browse, hay, and dried leaf fodder.',
         'Domestic browser converting steep and scrubby ground into milk, meat, hide, horn, manure, and limited pack work.',
         'Milk, cheese, meat, hide, horn, hair, manure, and light loads.',
         'Herds climb to summer grazing and return before deep snow; breeding females receive the best stored browse and hay.'),
        ('Eurasian Lynx',
         'Mountain hare, roe-sized deer where present, young reindeer, birds, and occasional small livestock.',
         'Solitary woodland predator regulating hare and small-ungulate populations.',
         'Winter fur and targeted control after repeated losses near settlements.',
         'Ranges widen in winter; females den in secluded rocky or wooded cover and raise kittens through summer.'),
        ('European Eel',
         'Aquatic insects, worms, crustaceans, mollusks, carrion, and small fish.',
         'Migratory nocturnal predator connecting inland food webs with the sea.',
         'Taken in traps and weirs, then eaten fresh, smoked, or salted.',
         'Adults descend toward the sea in autumn; managed bypass channels remain open during peak downstream movement.'),
        ('Farm Dog',
         'Household scraps, offal, porridge, dairy waste, fish remnants, and small prey caught around farms.',
         'Domestic guard, herding aid, vermin hunter, tracker, and companion within settled landscapes.',
         'Herding, guarding, hunting, tracking, alarm, warmth, and companionship.',
         'Dogs work year-round; breeding and training are timed so young animals mature before demanding winter or summer work.'),
        ('Forest Pig',
         'Mast, roots, tubers, fungi, household waste, insects, and occasional carrion.',
         'Domestic woodland forager converting seasonal mast and scraps into meat, fat, bristles, and manure.',
         'Pork, lard, hide, bristles, manure, and waste consumption.',
         'Herds forage in woodland after mast fall and most surplus animals are slaughtered before winter feed becomes scarce.'),
        ('Grey Cod',
         'Small fish, crustaceans, worms, mollusks, and benthic invertebrates.',
         'Demersal marine predator and prey supporting seals, larger fish, seabirds, and coastal fisheries.',
         'Fresh, dried, or salted food; liver oil and offal support household uses.',
         'Inshore availability shifts with spawning, water temperature, and storms; drying is concentrated in cold windy months.'),
        ('Grey Goose',
         'Grass, grain, sedges, aquatic plants, vegetable scraps, and small invertebrates taken while grazing.',
         'Domestic grazer and alarm bird around farmyards, wet meadows, and stubble fields.',
         'Meat, fat, eggs, feathers, down, manure, and household alarm.',
         'Birds graze through the open season; most young are fattened on aftermath and stubble before autumn slaughter.'),
        ('Grey Seal',
         'Cod, herring, flatfish, sand eels, squid, and other available marine prey.',
         'Coastal marine predator influencing fish schools and transferring nutrients onto breeding shores.',
         'Oil, hide, and meat under restricted local harvest; colonies also indicate productive fishing water.',
         'Adults gather at established breeding shores, then disperse to feeding grounds; storms and shore ice change haul-out use.'),
        ('Grey Wolf',
         'Deer, reindeer, moose calves, hare, carrion, and poorly guarded livestock.',
         'Pack predator shaping wild-herd movement and removing vulnerable animals and carrion.',
         'Fur and targeted control near livestock districts; broad eradication is avoided where wild herds depend on predation.',
         'Packs follow wintering herds, den in spring, and range more widely when snow or prey conditions deteriorate.'),
        ('Herring',
         'Plankton, copepods, small crustaceans, fish larvae, and suspended organic matter.',
         'Schooling forage fish supporting cod, seals, seabirds, and coastal communities.',
         'Fresh, smoked, dried, or salted food; oil, bait, and fertilizer from processing remains.',
         'Seasonal schools approach known coasts and sounds; failed runs sharply reduce winter stores and trade.'),
        ('Moose',
         'Willow, birch, rowan, aquatic plants, sedges, bark, and young shoots.',
         'Large browser opening dense regrowth and providing prey and carrion for large predators.',
         'Meat, hide, sinew, antler, bone, and limited protection of crops and hay stores.',
         'Moose use wetlands in summer, browse woody valleys in winter, calve in secluded cover, and gather loosely during the rut.'),
        ('Mountain Hare',
         'Grass, herbs, heather, buds, bark, and twigs, with woody browse dominating under snow.',
         'Small herbivore and major prey for lynx, wolves, raptors, and human hunters.',
         'Meat and winter fur taken with snares under local seasonal rules.',
         'Coat color and range shift with snow cover; repeated litters are possible during the growing season.'),
        ('Northern Pike',
         'Fish, amphibians, aquatic insects, and occasional waterbirds or small mammals.',
         'Ambush predator regulating lake and slow-river fish communities.',
         'Fresh, dried, or smoked food, especially where winter netting is practical.',
         'Pike move into shallow flooded margins to spawn after ice-out and return to weed beds and deeper water afterward.'),
        ('Northern Pony',
         'Grass, sedges, herbs, hay, straw, and limited leaf fodder.',
         'Domestic grazer and transport animal adapted to small loads, rough roads, snow, and sparse forage.',
         'Riding, pack work, light cartage, manure, hair, hide, and emergency meat.',
         'Ponies graze common land through summer; working and breeding animals receive hay while surplus stock is sold or slaughtered before winter.'),
        ('Otter',
         'Fish, crayfish, frogs, aquatic insects, mollusks, and occasional waterbirds.',
         'Semi-aquatic predator indicating connected, productive rivers, lakes, and sheltered coasts.',
         'Fur under restricted trapping and observation of fish movement; excessive harvest is discouraged near breeding holts.',
         'Otters remain active year-round, shifting between open channels, coasts, and ice-free springs as water freezes.'),
        ('Red Deer',
         'Grass, herbs, leaves, shoots, acorns, bark, and winter browse.',
         'Large grazer-browser shaping woodland edges and supporting wolves, lynx, scavengers, and hunters.',
         'Meat, hide, sinew, antler, bone, and ceremonial or household craft material.',
         'Herds move between summer uplands and sheltered winter valleys; the autumn rut concentrates adults.'),
        ('Reindeer',
         'Lichens, sedges, grasses, herbs, dwarf shrubs, fungi, and woody browse.',
         'Cold-country grazer linking tundra plants with wolves, wolverines, scavengers, and northern hunters.',
         'Meat, hide, sinew, antler, bone, and seasonal exchange with northern households.',
         'Herds move between calving, summer insect relief, autumn rutting, and wind-scoured winter feeding grounds.'),
        ('Rock Ptarmigan',
         'Willow and birch buds, leaves, berries, seeds, flowers, and insects taken chiefly by chicks.',
         'Tundra herbivore and prey for raptors, foxes, lynx, and northern hunters.',
         'Seasonal meat and feathers under local hunting limits.',
         'Plumage follows the snow season; birds form winter flocks and separate into breeding territories after thaw.'),
        ('Salmon',
         'Aquatic insects and small crustaceans when young; fish, squid, and marine invertebrates at sea.',
         'Migratory fish carrying marine nutrients into rivers and feeding people, bears, otters, birds, and scavengers.',
         'Fresh, smoked, dried, or salted food and a major seasonal trade catch.',
         'Adults ascend during established runs. Flash-weir bays and bypass channels are opened on scheduled days so breeding fish can pass upstream.'),
        ('Tyrven Cattle',
         'Grass, hay, straw, sedges, leaf fodder, crop residues, and limited grain by-products.',
         'Domestic grazer and draft animal converting meadow and crop residues into milk, meat, traction, hide, horn, and manure.',
         'Milk, butter, cheese, meat, draft work, hide, horn, bone, manure, and household wealth.',
         'Cattle graze through summer; breeding cows and draft oxen receive priority in winter while surplus animals are slaughtered after harvest.'),
        ('Tyrven Short-tail Sheep',
         'Grass, herbs, heather, sedges, hay, and dried leaf fodder.',
         'Domestic grazer converting marginal pasture into wool, milk, meat, hide, and manure.',
         'Wool, cloth, milk, cheese, meat, hide, horn, manure, and portable household wealth.',
         'Flocks move to summer grazing, are shorn before warm weather, breed in autumn, and return to sheltered winter ground.'),
        ('Wild Boar',
         'Acorns, roots, tubers, fungi, grain, fruit, insects, eggs, carrion, and small animals.',
         'Powerful omnivorous forager disturbing soil, dispersing seed, and competing with woodland pigs and farms.',
         'Meat, hide, tusk, bristles, and crop-protection hunting.',
         'Boar range follows mast and crops; winter groups use sheltered woodland while adult males remain more solitary.'),
        ('Wolverine',
         'Carrion, reindeer calves, hare, rodents, birds, eggs, and prey cached under snow or rock.',
         'Wide-ranging northern scavenger and predator that redistributes carrion through harsh uplands.',
         'Dense fur and limited control where repeated losses occur at traps or food caches.',
         'Wolverines range widely in winter, cache food, and use secluded snow dens for young.'),
        ('Yard Hen',
         'Grain, seeds, insects, worms, kitchen scraps, and forage gathered around yards and dung heaps.',
         'Domestic omnivore converting household scraps and invertebrates into eggs, meat, feathers, and manure.',
         'Eggs, meat, feathers, manure, and pest reduction around stored fodder and farmyards.',
         'Laying rises with spring light and forage; households retain breeding birds and slaughter surplus young before winter.')
    )
    UPDATE creatures creature
    SET diet = ecology.diet,
        ecological_role = ecology.ecological_role,
        economic_uses = ecology.economic_uses,
        seasonal_pattern = ecology.seasonal_pattern,
        updated_at = NOW()
    FROM ecology
    WHERE creature.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND creature.name = ecology.name;
    """

    execute """
    INSERT INTO creature_locations (
      id, creature_id, location_id, presence, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), creature.id, location.id,
      CASE creature.name WHEN 'Mountain Hare' THEN 'common' ELSE 'rare' END,
      CASE creature.name
        WHEN 'Mountain Hare' THEN 'Hare occupy scrub, cutover woodland, and the margins of mine and pasture land.'
        ELSE 'Small red-deer groups use the lower wooded valleys and move away from the busiest mining districts.' END,
      NOW(), NOW()
    FROM creatures creature
    JOIN locations location ON true
    JOIN location_types location_type ON location_type.id = location.location_type_id
    JOIN holds h ON h.id = location.hold_id
    JOIN provinces p ON p.id = h.province_id AND p.name = 'Jarnfell'
    JOIN continents c ON c.id = p.continent_id
    WHERE creature.world_id = c.world_id
      AND c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND creature.name IN ('Mountain Hare', 'Red Deer')
      AND location_type.name = 'Forest'
    ON CONFLICT (creature_id, location_id) DO UPDATE
    SET presence = EXCLUDED.presence,
        description = EXCLUDED.description,
        updated_at = NOW();
    """

    execute """
    UPDATE locations l
    SET description = 'The Great Flash Weir uses removable boards to raise navigation depth for shallow barges. During salmon and eel movements, marked bypass bays remain open on scheduled days, and catches above and below the structure are limited by Eirholm custom.',
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    WHERE l.hold_id = h.id
      AND c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND l.name = 'Great Flash Weir';
    """

    execute """
    UPDATE character_occupations assignment
    SET description = 'Supervises removable weir boards, barge passage, fish-bypass openings, tow crews, and witnessed maintenance shifts at the Great Flash Weir.',
        updated_at = NOW()
    FROM characters character
    WHERE assignment.character_id = character.id
      AND character.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND character.name ILIKE 'Ragnvald%';
    """

    execute """
    UPDATE characters
    SET description = regexp_replace(
          regexp_replace(description, 'chief lock keeper', 'senior weir keeper', 'gi'),
          'the main lock', 'the Great Flash Weir', 'gi'
        ),
        updated_at = NOW()
    WHERE world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND name ILIKE 'Ragnvald%';
    """
  end

  defp repair_timeline do
    execute """
    UPDATE timeline_events event
    SET position = event.year,
        updated_at = NOW()
    FROM timelines timeline
    WHERE event.timeline_id = timeline.id
      AND timeline.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    """

    execute """
    WITH timeline AS (
      SELECT timeline.id, era.id AS era_id
      FROM timelines timeline
      JOIN timeline_eras era ON era.timeline_id = timeline.id
      WHERE timeline.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
        AND timeline.name = 'Tyrven Annals'
        AND era.name = 'Age of the Nine Provinces'
      LIMIT 1
    ), events(name, year, description) AS (
      VALUES
        ('Compact of Nine Provinces', 1,
         'Delegates joined an older network of local things to an elective crown. Nine provincial jarls retained regional authority while the lawspeaker and Great Thing received control of common law.'),
        ('First Crown Settlement', 23,
         'The first vacancy proved that the crown was not hereditary. Provincial delegations rejected two close heirs and selected a compromise candidate after sureties were exchanged.'),
        ('Gronvale Fair Charter', 49,
         'Frostgard and Vardalen fixed safe-conduct days, pasture limits, and public measures for the autumn horse and wool fair at Gronvale.'),
        ('Three-Winter Scarcity', 78,
         'Three poor northern harvests reduced herds and emptied several household stores. Provincial relief began with remitted dues, controlled slaughter, and grain purchased from the south.'),
        ('Open-Lineage Judgment', 96,
         'The Great Thing confirmed that a recognized adult of a ruling lineage could present a claim through either parent. Provincial assent, household leadership, and sureties remained decisive.'),
        ('Opening of the Iron Pass', 117,
         'Jarnfell and Vardalen completed the marked high road, shelters, load measures, and customary maintenance shares that made regular iron cartage possible.'),
        ('Termed Service Law', 143,
         'The Great Thing limited hereditary bondage, established witnessed terms for debt service, and required a lawful path to redemption. Unfree service continued but could no longer pass indefinitely without review.'),
        ('Southern Brine Rights', 169,
         'Solmark granted shoreline, coppice, peat, pan-repair, and packing rights to the brine houses above the gulf, securing an internal supply of preserving salt.'),
        ('Frostgard Grazing Compact', 197,
         'Northern holds recorded summer grazing bounds, autumn slaughter dates, hay obligations, and emergency access to sheltered browse after repeated winter disputes.'),
        ('Kaldhavn Harbor Foundation', 214,
         'Skeldvik households consolidated older landing places into a guarded inner harbor with pilotage turns, repair yards, rescue stores, and public quay measures.'),
        ('Great Eirwater Flood', 236,
         'Spring flood carried away bridges and fish weirs across Eirholm. Rebuilding established witnessed toll accounts, fish-bypass days, and common hauling duties.'),
        ('Wolf Winter', 258,
         'Deep snow concentrated deer and livestock in the valleys. Coordinated watches protected herds while the things restricted wasteful den hunting and divided compensation claims.'),
        ('Deep Gallery Charter', 281,
         'Jarnfell required chartered mines to maintain drainage, timber inventories, crew tallies, road shares, and compensation funds before opening deeper galleries.'),
        ('Reckoning Reform', 301,
         'The lawspeaker fixed seven feast days after the final winter month every seventh year, aligning court seasons and household accounts with the observed solar year.'),
        ('Reserve Granary Law', 329,
         'After a thin harvest, the provinces adopted witnessed reserve targets, storage-loss allowances, rotation of old grain, and rules for opening public stores.'),
        ('Provincial Succession Settlement', 347,
         'The Great Thing standardized the hearing of jarldom claims while preserving provincial choice. Recognition by the crown became a record of settlement, not a power to appoint without assent.'),
        ('Western Harbor Compact', 367,
         'Kaldhavn and Vesthavn standardized pilotage, rescue stores, harbor measures, and the public revenue shares used for beacons and breakwaters.'),
        ('Common Weights Register', 389,
         'Market and toll stations received checked copies of standard weights and witnessed value bands. Offices were required to separate public receipts from household income.'),
        ('Thin Harvest of 403', 403,
         'A continent-wide poor harvest triggered reserve releases, reduced brewing, controlled livestock slaughter, and temporary suspension of several dues without exhausting the revised grain stores.'),
        ('Election of Styrkar', 412,
         'The Great Thing chose Styrkar after he assembled a workable coalition on road maintenance, reserve inspection, and limits on provincial military rivalry.'),
        ('Present Reckoning', 418,
         'The current political offices, economic estimates, tax assessments, routes, and public works are recorded in year 418 of the Age of the Nine Provinces.')
    )
    INSERT INTO timeline_events (
      id, timeline_id, timeline_era_id, name, year, position, description,
      inserted_at, updated_at
    )
    SELECT gen_random_uuid(), timeline.id, timeline.era_id,
      events.name, events.year, events.year, events.description, NOW(), NOW()
    FROM timeline
    CROSS JOIN events
    ON CONFLICT (timeline_id, name) DO UPDATE
    SET timeline_era_id = EXCLUDED.timeline_era_id,
        year = EXCLUDED.year,
        position = EXCLUDED.position,
        description = EXCLUDED.description,
        updated_at = NOW();
    """
  end
end
