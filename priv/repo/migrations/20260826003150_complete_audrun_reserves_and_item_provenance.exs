defmodule AncientStones.Repo.Migrations.CompleteAudrunReservesAndItemProvenance do
  use Ecto.Migration

  def up do
    execute """
    UPDATE commodity_balances balance
    SET stored_reserve = round(greatest(
          balance.stored_reserve,
          balance.annual_local_need * 1.10 -
            balance.annual_output * balance.bad_year_output_percentage / 100.0
        ), 1),
        description = 'Cleaned grain equivalent available to households after seed retention and ordinary milling losses. Local, estate, and public stores together cover one widespread poor harvest with a modest handling and rationing margin; consecutive failures require interprovincial relief.',
        updated_at = NOW()
    FROM holds h
    JOIN provinces p ON p.id = h.province_id
    JOIN continents c ON c.id = p.continent_id
    WHERE balance.hold_id = h.id
      AND c.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND balance.commodity = 'Staple grain equivalent';
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
    INSERT INTO items (
      id, world_id, find_location_id, name, category, kind, material, source,
      description, period_name, date_label, maker, provenance, authenticity,
      inserted_at, updated_at
    )
    SELECT gen_random_uuid(), continent.world_id, location.id,
      'Iron Pass Measure Stone', 'historical object', 'road measure', 'dressed basalt',
      'Iron Pass road wardens',
      'A marked stone used to check cart width, wheel spacing, and the legal load at the opening of the high road.',
      'Age of the Nine Provinces', 'Year 117', 'Brannskar stonecutters',
      'The stone remains beside the Ore Pass road and its dimensions recur in later maintenance accounts.',
      'historic', NOW(), NOW()
    FROM locations location
    JOIN holds hold ON hold.id = location.hold_id
    JOIN provinces province ON province.id = hold.province_id
    JOIN continents continent ON continent.id = province.continent_id
    WHERE continent.world_id = '7d897439-8af4-4baf-8617-722959777bdc'::uuid
      AND hold.name = 'Malmberg'
      AND location.name = 'Ore Pass'
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

  def down do
    :ok
  end
end
