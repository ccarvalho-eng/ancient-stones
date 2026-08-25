defmodule AncientStones.Repo.Migrations.RepairAudrunCredibilityData do
  use Ecto.Migration

  def up do
    execute """
    DO $audrun$
    DECLARE
      audrun_world_id uuid := '7d897439-8af4-4baf-8617-722959777bdc'::uuid;
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM worlds
        WHERE id = audrun_world_id AND name = 'Audrun'
      ) THEN
        RETURN;
      END IF;
    UPDATE worlds
    SET mass_earths = 1.04,
        surface_gravity_m_s2 = 9.86,
        orbital_distance_au = 1.003,
        orbital_eccentricity = 0.018,
        atmospheric_pressure_atm = 1.02,
        bond_albedo = 0.30,
        ocean_fraction = 0.68,
        star_mass_solar = 1.01,
        star_luminosity_solar = 1.02,
        star_temperature_k = 5785,
        updated_at = NOW()
    WHERE id = audrun_world_id;

    INSERT INTO moons (
      id, world_id, name, description, orbital_period_days, semi_major_axis_km,
      mean_radius_km, mass_lunar, orbital_eccentricity, inclination_degrees,
      tidal_role, inserted_at, updated_at
    )
    SELECT
      gen_random_uuid(), id, 'Mani',
      'A pale, cratered moon whose 26.9-day passage sets the principal coastal tide and provides a dependable count for fishers and navigators.',
      26.89, 387000, 1720, 0.96, 0.045, 5.2,
      'Its regular spring and neap tides govern harbor depths, weir work, coastal departures, and the strongest estuary currents.',
      NOW(), NOW()
    FROM worlds
    WHERE id = audrun_world_id
    ON CONFLICT (world_id, name) DO UPDATE
    SET description = EXCLUDED.description,
        orbital_period_days = EXCLUDED.orbital_period_days,
        semi_major_axis_km = EXCLUDED.semi_major_axis_km,
        mean_radius_km = EXCLUDED.mean_radius_km,
        mass_lunar = EXCLUDED.mass_lunar,
        orbital_eccentricity = EXCLUDED.orbital_eccentricity,
        inclination_degrees = EXCLUDED.inclination_degrees,
        tidal_role = EXCLUDED.tidal_role,
        updated_at = NOW();

    UPDATE calendars ca
    SET intercalation_interval_years = 7,
        intercalary_days = 7,
        intercalation_rule = 'Seven intercalary feast days follow the final winter month every seventh year. Courts suspend ordinary hearings while households settle accounts and renew public oaths.',
        description = 'Tyrven Reckoning divides the ordinary year into twelve named months totaling 364 days. Seven feast days close every seventh year, keeping the calendar aligned with Audrun''s 365-day orbit.',
        updated_at = NOW()
    FROM continents c
    JOIN worlds w ON w.id = c.world_id
    WHERE ca.continent_id = c.id AND w.id = audrun_world_id;

    WITH measurements(name, area_km2, winter_c, summer_c, precipitation_mm, frost_free_days) AS (
      VALUES
        ('Brannskar', 90000::bigint, 2.0, 16.0, 900, 190),
        ('Eirholm', 90000::bigint, -3.0, 16.0, 720, 170),
        ('Frostgard', 180000::bigint, -12.0, 11.0, 520, 80),
        ('Jarnfell', 110000::bigint, -9.0, 12.0, 580, 105),
        ('Myrholt', 90000::bigint, -2.0, 15.0, 850, 155),
        ('Ravnskog', 130000::bigint, -7.0, 15.0, 650, 130),
        ('Skeldvik', 120000::bigint, -1.0, 13.0, 1200, 160),
        ('Solmark', 120000::bigint, 1.0, 19.0, 650, 210),
        ('Vardalen', 150000::bigint, -4.0, 18.0, 620, 180)
    )
    UPDATE provinces p
    SET area_km2 = m.area_km2,
        latitude = c.north_latitude - (p.map_y::numeric / 1000) * (c.north_latitude - c.south_latitude),
        longitude = c.west_longitude + (p.map_x::numeric / 1000) * (c.east_longitude - c.west_longitude),
        mean_winter_temperature_c = m.winter_c,
        mean_summer_temperature_c = m.summer_c,
        annual_precipitation_mm = m.precipitation_mm,
        frost_free_days = m.frost_free_days,
        climate_zone = regexp_replace(p.climate_zone, ',?\\s+rather than\\s+[^.]+', '', 'gi'),
        updated_at = NOW()
    FROM measurements m, continents c, worlds w
    WHERE p.name = m.name AND p.continent_id = c.id AND c.world_id = w.id AND w.id = audrun_world_id;

    WITH measured_holds AS (
      SELECT
        h.id,
        p.area_km2,
        p.mean_winter_temperature_c AS province_winter,
        p.mean_summer_temperature_c AS province_summer,
        p.annual_precipitation_mm AS province_precipitation,
        p.frost_free_days AS province_frost_free,
        c.north_latitude,
        c.south_latitude,
        c.west_longitude,
        c.east_longitude,
        count(*) OVER (PARTITION BY p.id) AS hold_count,
        row_number() OVER (PARTITION BY p.id ORDER BY h.name) AS hold_number
      FROM holds h
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      JOIN worlds w ON w.id = c.world_id
      WHERE w.id = audrun_world_id
    )
    UPDATE holds h
    SET area_km2 = floor(m.area_km2::numeric / m.hold_count)::bigint +
          CASE WHEN m.hold_number <= (m.area_km2 % m.hold_count) THEN 1 ELSE 0 END,
        latitude = m.north_latitude - (h.map_y::numeric / 1000) * (m.north_latitude - m.south_latitude),
        longitude = m.west_longitude + (h.map_x::numeric / 1000) * (m.east_longitude - m.west_longitude),
        mean_winter_temperature_c = m.province_winter + CASE
          WHEN h.terrain IN ('mountain', 'highlands') THEN -3
          WHEN h.terrain = 'tundra' THEN -4
          WHEN h.terrain = 'coast' THEN 2
          ELSE 0 END,
        mean_summer_temperature_c = m.province_summer + CASE
          WHEN h.terrain IN ('mountain', 'highlands') THEN -3
          WHEN h.terrain = 'tundra' THEN -4
          WHEN h.terrain IN ('coast', 'wetlands', 'marsh') THEN -1
          ELSE 0 END,
        annual_precipitation_mm = round(m.province_precipitation * CASE
          WHEN h.terrain = 'coast' THEN 1.15
          WHEN h.terrain IN ('mountain', 'highlands') THEN 1.25
          WHEN h.terrain IN ('wetlands', 'marsh') THEN 1.15
          WHEN h.terrain = 'plains' THEN 0.90
          ELSE 1.0 END),
        frost_free_days = greatest(20, least(260, m.province_frost_free + CASE
          WHEN h.terrain = 'coast' THEN 10
          WHEN h.terrain = 'plains' THEN 10
          WHEN h.terrain IN ('mountain', 'highlands') THEN -25
          WHEN h.terrain = 'tundra' THEN -35
          WHEN h.terrain IN ('wetlands', 'marsh') THEN -5
          ELSE 0 END)),
        updated_at = NOW()
    FROM measured_holds m
    WHERE h.id = m.id;

    UPDATE locations l
    SET latitude = h.latitude + ((abs(hashtext(l.name)) % 1001) - 500)::numeric / 100000,
        longitude = h.longitude + ((abs(hashtext(l.name || h.name)) % 1001) - 500)::numeric / 100000,
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    JOIN worlds w ON w.id = c.world_id
    WHERE l.hold_id = h.id AND w.id = audrun_world_id;

    UPDATE households
    SET resident_count = CASE household_type
          WHEN 'royal_household' THEN 34
          WHEN 'magnate_household' THEN 18
          WHEN 'merchant_household' THEN 9
          WHEN 'craft_household' THEN 7
          WHEN 'farmstead' THEN 9
          WHEN 'fishing_household' THEN 8
          WHEN 'religious_household' THEN 6
          ELSE 7 END,
        dependent_count = CASE household_type
          WHEN 'royal_household' THEN 12
          WHEN 'magnate_household' THEN 6
          WHEN 'merchant_household' THEN 3
          WHEN 'craft_household' THEN 3
          WHEN 'farmstead' THEN 4
          WHEN 'fishing_household' THEN 3
          WHEN 'religious_household' THEN 2
          ELSE 2 END,
        servant_count = CASE household_type
          WHEN 'royal_household' THEN 14
          WHEN 'magnate_household' THEN 5
          WHEN 'merchant_household' THEN 1
          WHEN 'craft_household' THEN 1
          WHEN 'farmstead' THEN 1
          ELSE 0 END,
        updated_at = NOW()
    WHERE world_id = audrun_world_id;

    UPDATE political_offices
    SET selection_method = CASE
          WHEN office = 'High King' THEN 'Elected from eligible magnates by the Great Thing and acclaimed by the provincial jarls'
          WHEN office = 'Lawspeaker' THEN 'Elected by the Great Thing for a three-year term'
          WHEN office = 'Speaker of Jarls' THEN 'Chosen and recallable by the nine provincial jarls'
          WHEN office = 'Jarl' THEN 'A leading provincial lineage presents a successor for confirmation by the provincial thing'
          WHEN scope = 'hold' THEN 'Chosen at the local thing and confirmed by the provincial jarl'
          ELSE 'Appointed by the High King with council witnesses' END,
        succession_rule = CASE
          WHEN office = 'High King' THEN 'A vacancy calls an extraordinary Great Thing. Kinship supports a claim but gives no automatic right to the crown.'
          WHEN office = 'Lawspeaker' THEN 'The Great Thing elects a successor at the first lawful assembly after a vacancy.'
          WHEN office = 'Speaker of Jarls' THEN 'The jarls may replace the speaker whenever their common mandate is withdrawn.'
          WHEN office = 'Jarl' THEN 'The strongest customary heir must secure the provincial thing''s assent and the High King''s recognition.'
          WHEN scope = 'hold' THEN 'The local thing fills a vacancy; the jarl may reject a candidate only for a stated breach of law or fitness.'
          ELSE 'The appointing authority names a successor before witnesses and records the transfer at the next assembly.' END,
        term_started_year = 418,
        term_length_years = CASE
          WHEN office = 'Lawspeaker' OR scope = 'hold' THEN 3
          WHEN office = 'Speaker of Jarls' THEN 1
          ELSE NULL END,
        updated_at = NOW()
    WHERE world_id = audrun_world_id;

    UPDATE gods SET description = CASE name
      WHEN 'Haldren' THEN 'Haldren presides over sworn law, public witness, and judgments spoken before the thing.'
      WHEN 'Morna' THEN 'Morna is invoked at burial mounds and family graves, where households keep names, inheritance, and obligations to the dead.'
      WHEN 'Saeva' THEN 'Saeva guards coastal households, fishers, safe landfall, and the customary sharing of a catch after a dangerous voyage.'
      ELSE regexp_replace(description, ',?\\s+rather than\\s+[^.]+', '', 'gi') END,
      updated_at = NOW()
    WHERE world_id = audrun_world_id;

    UPDATE races
    SET description = regexp_replace(description, ',?\\s+rather than\\s+[^.]+', '', 'gi'),
        updated_at = NOW()
    WHERE world_id = audrun_world_id;

    UPDATE tax_policies
    SET description = regexp_replace(description, ',?\\s+rather than\\s+[^.]+', '', 'gi'),
        updated_at = NOW()
    WHERE world_id = audrun_world_id;

    UPDATE tax_exemptions te
    SET description = regexp_replace(te.description, ',?\\s+rather than\\s+[^.]+', '', 'gi'),
        updated_at = NOW()
    FROM tax_policies tp
    WHERE te.tax_policy_id = tp.id
      AND tp.world_id = audrun_world_id;

    UPDATE trade_flows tf
    SET description = regexp_replace(tf.description, ',?\\s+rather than\\s+[^.]+', '', 'gi'),
        updated_at = NOW()
    FROM trade_routes tr
    WHERE tf.trade_route_id = tr.id
      AND tr.world_id = audrun_world_id;

    UPDATE water_body_connections wc
    SET description = regexp_replace(wc.description, ',?\\s+rather than\\s+[^.]+', '', 'gi'),
        updated_at = NOW()
    FROM water_bodies wb
    WHERE wc.origin_water_body_id = wb.id
      AND wb.world_id = audrun_world_id;

    UPDATE hold_commerce_entries e
    SET description = regexp_replace(e.description, ',?\\s+rather than\\s+[^.]+', '', 'gi'),
        frequency = CASE
          WHEN e.category IN ('agriculture', 'produce', 'livestock') THEN 'annual'
          WHEN e.category IN ('fishing', 'forestry', 'herbalism', 'fuel') THEN 'seasonal'
          ELSE e.frequency END,
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    JOIN worlds w ON w.id = c.world_id
    WHERE e.hold_id = h.id AND w.id = audrun_world_id;

    UPDATE trade_routes
    SET risk = CASE name
          WHEN 'Brannskar Coastal Run' THEN 'high'
          WHEN 'Eirwater Passage' THEN 'moderate'
          WHEN 'Raven Timber Run' THEN 'high'
          WHEN 'Skeldvik Coastal Road' THEN 'high'
          WHEN 'South Grain Road' THEN 'moderate'
          WHEN 'Western Sea Lane' THEN 'high'
          ELSE risk END,
        transport_mode = CASE WHEN name = 'Frost Road' THEN 'road' ELSE transport_mode END,
        description = CASE name
          WHEN 'Frost Road' THEN 'A guarded chain of pack trails, bridge crossings, and maintained road stages links Frostgard with the central basin. Furs and hides travel south; compact loads of salt, ironwork, and official supplies move north. Bulk grain reaches Frostgard mainly by the coastal passage.'
          WHEN 'Raven Timber Run' THEN 'A river-and-coastal route timed to spring and early-summer water. Marked logs are floated down the Ravna and assembled into rafts; tar and resin travel by cart and boat. At the river mouth, harbor craft tow timber along sheltered water to Kaldhavn. Salt and iron tools return to the forest settlements.'
          WHEN 'Skeldvik Coastal Road' THEN 'A coastal sailing and inland road corridor between Kaldhavn and Vardborg. Coasters carry preserved fish and fittings between the western harbors; carts take the cargo inland from Vesthavn. Grain and flour return to the port.'
          ELSE regexp_replace(description, ',?\\s+rather than\\s+[^.]+', '', 'gi') END,
        updated_at = NOW()
    WHERE world_id = audrun_world_id;

    UPDATE trade_route_legs l
    SET transport_mode = 'mixed',
        description = 'Rafts descend the lower Ravna before sheltered harbor craft tow the timber along the coast to Kaldhavn.',
        handling_notes = 'Rafts are broken into towable strings at the river mouth; exposed departures wait for a fair tide and wind.',
        updated_at = NOW()
    FROM trade_routes tr
    WHERE l.trade_route_id = tr.id AND tr.name = 'Raven Timber Run' AND l.position = 3
      AND tr.world_id = audrun_world_id;

    UPDATE trade_route_legs l
    SET transport_mode = 'sea',
        water_body_id = (SELECT id FROM water_bodies WHERE name = 'Skeld Sea' AND world_id = tr.world_id),
        description = 'Coasters follow the sheltered western inlets from Kaldhavn to Vesthavn.',
        updated_at = NOW()
    FROM trade_routes tr
    WHERE l.trade_route_id = tr.id AND tr.name = 'Skeldvik Coastal Road' AND l.position = 1
      AND tr.world_id = audrun_world_id;

    INSERT INTO trade_route_leg_waters (
      id, trade_route_leg_id, water_body_id, position, distance_km, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), l.id, wb.id, path.position, path.distance_km,
           'Recorded water stage for the corrected route geometry.', NOW(), NOW()
    FROM trade_route_legs l
    JOIN trade_routes tr ON tr.id = l.trade_route_id
    JOIN LATERAL (
      VALUES
        (1, 1, 'Ravna'::text, 150::numeric),
        (1, 2, 'Skeld Sea'::text, 70::numeric)
    ) AS path(leg_position, position, water_name, distance_km) ON path.leg_position = l.position
    JOIN water_bodies wb ON wb.world_id = tr.world_id AND wb.name = path.water_name
    WHERE tr.name = 'Raven Timber Run' AND l.position = 3
      AND tr.world_id = audrun_world_id
    ON CONFLICT DO NOTHING;

    INSERT INTO trade_route_leg_waters (
      id, trade_route_leg_id, water_body_id, position, distance_km, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), l.id, wb.id, path.position, path.distance_km,
           'Recorded coastal stage for the corrected route geometry.', NOW(), NOW()
    FROM trade_route_legs l
    JOIN trade_routes tr ON tr.id = l.trade_route_id
    JOIN LATERAL (
      VALUES
        (1, 'Skeld Sea'::text, 85::numeric),
        (2, 'Vesthavn Sound'::text, 65::numeric)
    ) AS path(position, water_name, distance_km) ON true
    JOIN water_bodies wb ON wb.world_id = tr.world_id AND wb.name = path.water_name
    WHERE tr.name = 'Skeldvik Coastal Road' AND l.position = 1
      AND tr.world_id = audrun_world_id
    ON CONFLICT DO NOTHING;

    UPDATE location_types
    SET name = 'Hewing Yard',
        description = 'An open timber-working ground where trunks are split with wedges, hewn with axes and adzes, and dressed into beams or boards.',
        updated_at = NOW()
    WHERE name = 'Sawpit' AND world_id = audrun_world_id;

    UPDATE locations l
    SET name = replace(l.name, 'Sawpit', 'Hewing Yard'),
        description = replace(replace(l.description, 'hand-sawing', 'timber-hewing'), 'hand-sawn', 'split and hewn'),
        updated_at = NOW()
    FROM location_types lt
    WHERE l.location_type_id = lt.id AND lt.name = 'Hewing Yard'
      AND lt.world_id = audrun_world_id;

    UPDATE occupations
    SET name = 'Timber Hewyer',
        description = 'Splits trunks along the grain with wedges, squares beams with a broad axe, and dresses boards with axes, adzes, and planes.',
        updated_at = NOW()
    WHERE name = 'Sawyer' AND world_id = audrun_world_id;

    UPDATE items
    SET name = 'Splitting Wedges',
        material = 'iron',
        description = 'A graduated set of iron wedges used with wooden mauls to split straight-grained trunks into boards and structural timber.',
        updated_at = NOW()
    WHERE name = 'Frame Saw' AND world_id = audrun_world_id;

    UPDATE items
    SET material = 'yew and linen',
        description = 'A yew self bow with a linen string for deer and smaller game; arrows are matched to the draw.',
        updated_at = NOW()
    WHERE name = 'Hunting Bow' AND world_id = audrun_world_id;

    UPDATE creatures
    SET danger_level = 'low', updated_at = NOW()
    WHERE name = 'Capercaillie' AND world_id = audrun_world_id;

    UPDATE creatures
    SET population_status = CASE
          WHEN name IN ('Brown Honeybee', 'Common Eider') THEN 'managed'
          WHEN name IN ('Crag Goat', 'Farm Dog', 'Forest Pig', 'Grey Goose', 'Northern Pony', 'Tyrven Cattle', 'Tyrven Short-tail Sheep', 'Yard Hen') THEN 'domestic'
          ELSE 'wild' END,
        diet = CASE
          WHEN name IN ('Grey Cod', 'Herring', 'Northern Pike', 'Salmon') THEN 'Fish, crustaceans, invertebrates, or smaller aquatic prey according to species and age.'
          WHEN name IN ('Brown Bear', 'Forest Pig', 'Wild Boar') THEN 'Seasonal roots, mast, berries, invertebrates, carrion, and animal matter.'
          WHEN name IN ('Grey Wolf', 'Eurasian Lynx', 'Wolverine') THEN 'Wild ungulates, hare, carrion, and other available animal prey.'
          WHEN name IN ('Crag Goat', 'Moose', 'Northern Pony', 'Red Deer', 'Reindeer', 'Tyrven Cattle', 'Tyrven Short-tail Sheep') THEN 'Grass, sedges, browse, hay, and leaf fodder according to season.'
          WHEN name = 'Brown Honeybee' THEN 'Nectar, pollen, and stored honey.'
          ELSE 'Seeds, vegetation, insects, scraps, or small prey suited to its habitat.' END,
        ecological_role = CASE
          WHEN name IN ('Grey Cod', 'Herring', 'Northern Pike', 'Salmon') THEN 'Aquatic consumer and prey supporting river, lake, and coastal food webs.'
          WHEN name IN ('Grey Wolf', 'Eurasian Lynx', 'Wolverine', 'Brown Bear') THEN 'Wide-ranging predator or scavenger influencing wild herds and carrion use.'
          WHEN name IN ('Crag Goat', 'Northern Pony', 'Tyrven Cattle', 'Tyrven Short-tail Sheep') THEN 'Domestic grazer and converter of pasture or winter fodder into food, fiber, manure, and work.'
          WHEN name = 'Brown Honeybee' THEN 'Pollinator of orchards, meadows, and woodland-edge plants.'
          ELSE 'Forager, browser, grazer, predator, or prey within its recorded habitat.' END,
        economic_uses = CASE
          WHEN name IN ('Grey Cod', 'Herring', 'Northern Pike', 'Salmon') THEN 'Fresh, dried, smoked, or salted food; surplus enters regional trade.'
          WHEN name IN ('Crag Goat', 'Forest Pig', 'Grey Goose', 'Northern Pony', 'Tyrven Cattle', 'Tyrven Short-tail Sheep', 'Yard Hen') THEN 'Food, fiber, hide, horn, feathers, manure, transport, or draft work according to species.'
          WHEN name = 'Brown Honeybee' THEN 'Honey, wax, and orchard pollination.'
          WHEN name IN ('Brown Bear', 'Eurasian Lynx', 'Grey Wolf', 'Wolverine', 'Red Deer', 'Reindeer', 'Moose', 'Mountain Hare') THEN 'Hunted or managed for meat, hide, fur, antler, or protection of livestock and crops.'
          ELSE 'Local food, feathers, down, hide, observation, or pest control where customary.' END,
        seasonal_pattern = CASE
          WHEN name IN ('Herring', 'Salmon') THEN 'Seasonal runs concentrate harvest and preservation; poor runs quickly reduce trade and winter stores.'
          WHEN name IN ('Brown Bear', 'Wolverine') THEN 'Activity and range change sharply with snow cover, denning, and winter carrion.'
          WHEN name IN ('Reindeer', 'Red Deer', 'Moose') THEN 'Seasonal movement follows forage, snow depth, calving ground, and the autumn rut.'
          WHEN name IN ('Crag Goat', 'Northern Pony', 'Tyrven Cattle', 'Tyrven Short-tail Sheep') THEN 'Herds use open grazing in summer and stored hay, leaf fodder, or sheltered browse through winter.'
          ELSE 'Breeding, feeding, movement, and harvest follow the local sequence of thaw, summer growth, autumn stores, and winter scarcity.' END,
        updated_at = NOW()
    WHERE world_id = audrun_world_id;

    INSERT INTO creatures (
      id, world_id, creature_type_id, name, habitat, temperament, danger_level,
      population_status, diet, ecological_role, economic_uses, seasonal_pattern,
      description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), w.id, ct.id, 'European Eel',
      'Slow rivers, connected lakes, marsh channels, and estuaries', 'neutral', 'low',
      'wild', 'Aquatic invertebrates, small fish, carrion, and other available prey.',
      'Migratory predator linking inland waters with the sea.',
      'Taken in traps and weirs, then eaten fresh, smoked, or salted.',
      'Adults descend toward the sea in autumn; inland catches vary with water level, barriers, and migration.',
      'A long-bodied migratory fish of connected lowland waters. Eels move through wet grass and shallow channels during damp nights and gather at managed passages.',
      NOW(), NOW()
    FROM worlds w
    JOIN creature_types ct ON ct.world_id = w.id AND ct.name = 'Fish'
    WHERE w.id = audrun_world_id
    ON CONFLICT (world_id, name) DO UPDATE
    SET habitat = EXCLUDED.habitat, population_status = EXCLUDED.population_status,
        diet = EXCLUDED.diet, ecological_role = EXCLUDED.ecological_role,
        economic_uses = EXCLUDED.economic_uses, seasonal_pattern = EXCLUDED.seasonal_pattern,
        description = EXCLUDED.description, updated_at = NOW();

    INSERT INTO creature_locations (
      id, creature_id, location_id, presence, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), cr.id, l.id, 'common',
      'Recorded in connected lowland water and harvested during seasonal movement.', NOW(), NOW()
    FROM creatures cr
    JOIN worlds w ON w.id = cr.world_id AND w.id = audrun_world_id
    JOIN locations l ON true
    JOIN holds h ON h.id = l.hold_id
    JOIN provinces p ON p.id = h.province_id AND p.name IN ('Myrholt', 'Eirholm')
    JOIN location_types lt ON lt.id = l.location_type_id AND lt.name IN ('Fishery', 'Lake', 'Flash Weir')
    WHERE cr.name = 'European Eel'
    ON CONFLICT (creature_id, location_id) DO NOTHING;

    UPDATE landholdings lh
    SET size_hectares = COALESCE(lh.size_hectares, CASE lh.primary_use
          WHEN 'farming' THEN 24
          WHEN 'pasture' THEN 46
          WHEN 'woodland' THEN 32
          WHEN 'fishing' THEN 8
          WHEN 'mining' THEN 5
          WHEN 'workshop' THEN 2
          WHEN 'trade' THEN 1
          ELSE 12 END),
        tenure_type = CASE
          WHEN lh.status = 'disputed' THEN 'disputed'
          WHEN hh.household_type IN ('royal_household', 'magnate_household') THEN 'granted'
          WHEN lh.primary_use IN ('fishing', 'woodland', 'pasture') THEN 'communal_right'
          WHEN hh.household_type IN ('merchant_household', 'craft_household') THEN 'leasehold'
          ELSE 'allodial' END,
        updated_at = NOW()
    FROM households hh
    WHERE lh.household_id = hh.id AND hh.world_id = audrun_world_id;

    INSERT INTO landholdings (
      id, household_id, location_id, name, tenure_type, primary_use, size_hectares,
      status, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), hh.id, hh.home_location_id,
      replace(hh.name, 'Household of ', '') || ' holding',
      CASE
        WHEN hh.household_type IN ('royal_household', 'magnate_household') THEN 'granted'
        WHEN hh.household_type IN ('merchant_household', 'craft_household') THEN 'leasehold'
        WHEN hh.household_type = 'fishing_household' THEN 'communal_right'
        ELSE 'allodial' END,
      CASE hh.household_type
        WHEN 'merchant_household' THEN 'trade'
        WHEN 'craft_household' THEN 'workshop'
        WHEN 'fishing_household' THEN 'fishing'
        WHEN 'religious_household' THEN 'ritual'
        WHEN 'magnate_household' THEN 'mixed'
        WHEN 'royal_household' THEN 'mixed'
        ELSE 'farming' END,
      CASE hh.household_type
        WHEN 'royal_household' THEN 85
        WHEN 'magnate_household' THEN 55
        WHEN 'merchant_household' THEN 1.5
        WHEN 'craft_household' THEN 1.2
        WHEN 'religious_household' THEN 4
        ELSE 18 END,
      'active',
      'The recorded right includes the household''s dwelling, working ground, access, and customary obligations at its usual settlement.',
      NOW(), NOW()
    FROM households hh
    LEFT JOIN landholdings existing ON existing.household_id = hh.id
    WHERE hh.world_id = audrun_world_id
      AND hh.home_location_id IS NOT NULL AND existing.id IS NULL
    ON CONFLICT (household_id, name) DO NOTHING;

    INSERT INTO character_relationships (
      id, world_id, character_a_id, character_b_id, relationship_type,
      character_a_role, character_b_role, status, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), w.id,
      LEAST(mother.id::text, daughter.id::text)::uuid,
      GREATEST(mother.id::text, daughter.id::text)::uuid,
      'parent_child',
      CASE WHEN mother.id::text < daughter.id::text THEN 'mother' ELSE 'daughter' END,
      CASE WHEN mother.id::text < daughter.id::text THEN 'daughter' ELSE 'mother' END,
      'active',
      'Tove is Alfhild''s mother. They share a household network in Gronvale and retain separate public duties.',
      NOW(), NOW()
    FROM worlds w
    JOIN characters mother ON mother.world_id = w.id AND mother.name = 'Tove Arnesdottir'
    JOIN characters daughter ON daughter.world_id = w.id AND daughter.name = 'Alfhild Tovesdottir'
    WHERE w.id = audrun_world_id
    ON CONFLICT DO NOTHING;

    INSERT INTO skill_levels (id, skill_id, name, rank, minimum_value, description, inserted_at, updated_at)
    SELECT gen_random_uuid(), s.id, levels.name, levels.rank, levels.minimum_value, levels.description, NOW(), NOW()
    FROM skills s
    JOIN worlds w ON w.id = s.world_id AND w.id = audrun_world_id
    CROSS JOIN (VALUES
      ('Familiar', 1, 0, 'Can assist safely with ordinary work under direction.'),
      ('Practiced', 2, 25, 'Can complete routine work independently in familiar conditions.'),
      ('Skilled', 3, 50, 'Handles difficult work, judges quality, and teaches established practice.'),
      ('Master', 4, 75, 'Recognized for exceptional judgment across unusual or high-stakes work.')
    ) AS levels(name, rank, minimum_value, description)
    ON CONFLICT DO NOTHING;

    WITH ranked AS (
      SELECT cs.id, row_number() OVER (PARTITION BY cs.skill_id ORDER BY cs.character_id) AS position
      FROM character_skills cs
      JOIN skills s ON s.id = cs.skill_id
      WHERE s.world_id = audrun_world_id
    )
    UPDATE character_skills cs
    SET level = CASE
          WHEN ranked.position % 10 = 0 THEN 'master'
          WHEN ranked.position % 3 = 0 THEN 'skilled'
          WHEN ranked.position % 2 = 0 THEN 'practiced'
          ELSE 'familiar' END,
        updated_at = NOW()
    FROM ranked
    WHERE cs.id = ranked.id;

    INSERT INTO occupations (id, world_id, name, category, description, inserted_at, updated_at)
    SELECT gen_random_uuid(), w.id, occupation.name, occupation.category, occupation.description, NOW(), NOW()
    FROM worlds w
    CROSS JOIN (VALUES
      ('Farmer', 'agriculture', 'Manages fields, livestock, manure, seed, hay, and the household labor calendar.'),
      ('Weaver', 'textile', 'Turns spun wool or flax into cloth and judges sett, tension, finishing, and repair.'),
      ('Tanner', 'leatherwork', 'Cures hides with bark, fat, smoke, and careful washing for shoes, harness, bags, and clothing.'),
      ('Potter', 'craft', 'Shapes and fires household vessels, storage jars, lamps, and coarse industrial ware.'),
      ('Brewer', 'food', 'Malts grain, manages fermentation, and supplies ale for households, inns, feasts, and labor crews.'),
      ('Cooper', 'woodworking', 'Makes and repairs staved tubs, buckets, churns, casks, and fish barrels.'),
      ('Wheelwright', 'woodworking', 'Builds wheels, axles, carts, and sled fittings suited to local roads and loads.')
    ) AS occupation(name, category, description)
    WHERE w.id = audrun_world_id
    ON CONFLICT (world_id, name) DO NOTHING;

    WITH eligible AS (
      SELECT ch.id, row_number() OVER (ORDER BY ch.name) AS position
      FROM characters ch
      JOIN household_memberships hm ON hm.character_id = ch.id AND hm.is_primary
      JOIN households hh ON hh.id = hm.household_id
      WHERE ch.world_id = audrun_world_id
        AND hh.household_type IN ('farmstead', 'craft_household', 'merchant_household', 'fishing_household')
    ), numbered_occupations AS (
      SELECT o.id, o.name, row_number() OVER (ORDER BY o.name) AS position
      FROM occupations o
      WHERE o.world_id = audrun_world_id
        AND o.name IN ('Farmer', 'Weaver', 'Tanner', 'Potter', 'Brewer', 'Cooper', 'Wheelwright')
    )
    INSERT INTO character_occupations (
      id, character_id, occupation_id, rank, "primary", description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), e.id, o.id, 'practiced', false,
      'A regular household craft or seasonal occupation recorded alongside public duties.', NOW(), NOW()
    FROM eligible e
    JOIN numbered_occupations o ON o.position = e.position
    WHERE e.position <= 7
    ON CONFLICT DO NOTHING;

    INSERT INTO commodity_balances (
      id, hold_id, commodity, category, unit, annual_output, annual_local_need,
      stored_reserve, bad_year_output_percentage, storage_loss_percentage,
      status, description, inserted_at, updated_at
    )
    SELECT gen_random_uuid(), h.id, commodity.name, commodity.category, commodity.unit,
      round(profile.population_estimate * commodity.output_rate * commodity.regional_factor, 1),
      round(profile.population_estimate * commodity.need_rate, 1),
      round(profile.population_estimate * commodity.need_rate * commodity.reserve_rate, 1),
      commodity.bad_year_percentage, commodity.storage_loss_percentage, 'provisional',
      commodity.description || ' Estimate for ' || h.name || ' in ' || p.name || '.', NOW(), NOW()
    FROM hold_economic_profiles profile
    JOIN holds h ON h.id = profile.hold_id
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    JOIN worlds w ON w.id = c.world_id AND w.id = audrun_world_id
    CROSS JOIN LATERAL (VALUES
      ('Preserved fish', 'protein food', 'tonnes', 0.010::numeric, 0.012::numeric,
       CASE WHEN p.name IN ('Skeldvik', 'Frostgard', 'Eirholm', 'Myrholt', 'Brannskar') THEN 2.6 ELSE 0.45 END,
       0.18::numeric, 70::numeric, 12::numeric,
       'Edible fish landed or taken inland, expressed after ordinary curing losses.'),
      ('Livestock food products', 'protein and fat', 'tonnes', 0.021::numeric, 0.018::numeric,
       CASE WHEN p.name IN ('Frostgard', 'Vardalen', 'Solmark', 'Ravnskog') THEN 1.25 ELSE 0.85 END,
       0.12::numeric, 78::numeric, 10::numeric,
       'Milk products and slaughter yield available to households after breeding stock is retained.'),
      ('Winter fodder', 'feed', 'tonnes dry matter', 0.42::numeric, 0.38::numeric,
       CASE WHEN p.name IN ('Solmark', 'Vardalen', 'Eirholm') THEN 1.15 WHEN p.name = 'Frostgard' THEN 0.72 ELSE 0.95 END,
       0.10::numeric, 72::numeric, 14::numeric,
       'Hay, straw, sedges, and leaf fodder stored for working and breeding animals through winter.')
    ) AS commodity(name, category, unit, output_rate, need_rate, regional_factor,
                   reserve_rate, bad_year_percentage, storage_loss_percentage, description)
    ON CONFLICT (hold_id, commodity, unit) DO UPDATE
    SET annual_output = EXCLUDED.annual_output,
        annual_local_need = EXCLUDED.annual_local_need,
        stored_reserve = EXCLUDED.stored_reserve,
        bad_year_output_percentage = EXCLUDED.bad_year_output_percentage,
        storage_loss_percentage = EXCLUDED.storage_loss_percentage,
        status = EXCLUDED.status,
        description = EXCLUDED.description,
        updated_at = NOW();

    WITH duplicates AS (
      SELECT l.description
      FROM locations l
      JOIN holds h ON h.id = l.hold_id
      JOIN provinces p ON p.id = h.province_id
      JOIN continents c ON c.id = p.continent_id
      JOIN worlds w ON w.id = c.world_id
      WHERE w.id = audrun_world_id
      GROUP BY l.description
      HAVING count(*) > 1
    )
    UPDATE locations l
    SET description = CASE lt.name
          WHEN 'Farmstead' THEN l.name || ' is a working farm in ' || h.name || ', with dwelling rooms, byres, barns, fenced plots, and winter stores suited to ' || lower(p.name) || ' conditions.'
          WHEN 'Thing Site' THEN l.name || ' is ' || h.name || '''s public assembly ground, with a law stone, witness space, tethering ground, and room for seasonal booths.'
          WHEN 'River Crossing' THEN l.name || ' carries the customary road across local water near ' || h.name || '; markers show the safest ford or maintained landing at ordinary flow.'
          WHEN 'Forest' THEN l.name || ' is a named woodland of ' || h.name || ', used under local rules for fuel, timber, grazing, forage, and hunting.'
          WHEN 'Fortified Hall' THEN l.name || ' is the principal defended hall of ' || h.name || ', combining residence, stores, guest benches, stable space, and a protected yard.'
          WHEN 'Inn' THEN l.name || ' serves travelers in ' || h.name || ' with food, shared lodging, stabling, news, and witnessed exchange.'
          WHEN 'Seasonal Camp' THEN l.name || ' is used from ' || h.name || ' during the working season for herding, fishing, hunting, gathering, or route maintenance.'
          WHEN 'Trail Shelter' THEN l.name || ' is a simple public refuge on the approaches to ' || h.name || ', stocked with a hearth, sleeping benches, and emergency fuel.'
          ELSE l.name || ' is a recognized ' || lower(lt.name) || ' within ' || h.name || ' in ' || p.name || ', maintained under local custom and used according to the surrounding terrain.' END,
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    JOIN worlds w ON w.id = c.world_id
    CROSS JOIN location_types lt
    WHERE l.hold_id = h.id
      AND lt.id = l.location_type_id
      AND w.id = audrun_world_id
      AND l.description IN (SELECT description FROM duplicates);

    UPDATE hold_economic_profiles profile
    SET description = h.name || ' supports about ' || profile.population_estimate || ' people in ' || profile.household_estimate ||
          ' households. Approximately ' || profile.arable_hectares_estimate || ' hectares are arable and ' ||
          profile.pasture_hectares_estimate || ' hectares are managed pasture; recorded staple reserves cover ' ||
          profile.staple_reserve_months || ' months under ordinary conditions.',
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    JOIN worlds w ON w.id = c.world_id
    WHERE profile.hold_id = h.id AND w.id = audrun_world_id;

    WITH world AS (SELECT audrun_world_id AS id),
    timeline AS (
      INSERT INTO timelines (id, world_id, name, description, inserted_at, updated_at)
      SELECT gen_random_uuid(), world.id, 'Tyrven Annals',
        'A working chronology used by assemblies, households, and later compilers to place settlements, laws, disasters, and public works.',
        NOW(), NOW() FROM world
      ON CONFLICT (world_id, name) DO UPDATE SET description = EXCLUDED.description, updated_at = NOW()
      RETURNING id
    ), timeline_id AS (
      SELECT id FROM timeline UNION ALL
      SELECT t.id FROM timelines t JOIN world ON t.world_id = world.id WHERE t.name = 'Tyrven Annals' LIMIT 1
    ), era AS (
      INSERT INTO timeline_eras (id, timeline_id, name, abbreviation, position, starts_at_year, description, inserted_at, updated_at)
      SELECT gen_random_uuid(), timeline_id.id, 'Age of the Nine Provinces', 'NP', 1, 1,
        'The era begins with the compact that fixed the duties of the Great Thing, the provincial jarls, and the elective crown.',
        NOW(), NOW() FROM timeline_id
      ON CONFLICT (timeline_id, name) DO UPDATE SET description = EXCLUDED.description, updated_at = NOW()
      RETURNING id, timeline_id
    ), era_id AS (
      SELECT id, timeline_id FROM era UNION ALL
      SELECT e.id, e.timeline_id FROM timeline_eras e JOIN timeline_id t ON t.id = e.timeline_id WHERE e.name = 'Age of the Nine Provinces' LIMIT 1
    )
    INSERT INTO timeline_events (id, timeline_id, timeline_era_id, name, year, position, description, inserted_at, updated_at)
    SELECT gen_random_uuid(), era_id.timeline_id, era_id.id, event.name, event.year, event.position, event.description, NOW(), NOW()
    FROM era_id
    CROSS JOIN (VALUES
      ('Compact of Nine Provinces', 1, 1, 'The Great Thing recognized nine provincial jurisdictions, an elective High King, and the separate authority of the lawspeaker.'),
      ('Opening of the Iron Pass', 117, 2, 'Jarnfell and Vardalen completed the marked high road, shelters, and customary maintenance shares that made regular iron cartage possible.'),
      ('Great Eirwater Flood', 236, 3, 'Spring flood carried away bridges and fish weirs across Eirholm. Rebuilding established witnessed toll accounts and common hauling duties.'),
      ('Reckoning Reform', 301, 4, 'The lawspeaker fixed seven feast days after the final winter month every seventh year to keep assemblies aligned with the observed seasons.'),
      ('Western Harbor Compact', 367, 5, 'Kaldhavn and Vesthavn standardized pilotage, rescue stores, harbor measures, and the revenue share used for beacons and breakwaters.'),
      ('Present Reckoning', 418, 6, 'The current officers and economic assessments are recorded in year 418 of the Age of the Nine Provinces.')
    ) AS event(name, year, position, description)
    ON CONFLICT (timeline_id, name) DO UPDATE
    SET year = EXCLUDED.year, position = EXCLUDED.position, description = EXCLUDED.description, updated_at = NOW();

    UPDATE water_bodies
    SET name = CASE name
          WHEN 'Hrafn Fjord' THEN 'Hrafnsfjord'
          WHEN 'Stone Bay' THEN 'Steinvik'
          WHEN 'Icewater Lake' THEN 'Isvatn'
          WHEN 'Long Lake' THEN 'Langvatn'
          WHEN 'Siv Lake' THEN 'Sivvatn'
          WHEN 'Swan Sound' THEN 'Svanesund'
          WHEN 'Vesthavn Sound' THEN 'Vesthavnsund'
          ELSE name END,
        updated_at = NOW()
    WHERE world_id = audrun_world_id
      AND name IN (
        'Hrafn Fjord', 'Stone Bay', 'Icewater Lake', 'Long Lake',
        'Siv Lake', 'Swan Sound', 'Vesthavn Sound'
      );
    END
    $audrun$;
    """
  end

  def down do
    :ok
  end
end
