defmodule AncientStones.AudrunTemplateTest do
  use AncientStones.DataCase, async: true

  import Ecto.Query

  alias AncientStones.Repo
  alias AncientStones.Templates
  alias AncientStones.Worlds

  alias AncientStones.Worlds.{
    Assembly,
    Character,
    CharacterLocation,
    CharacterRelationship,
    CharacterSkill,
    Continent,
    CreatureLocation,
    Hold,
    Item,
    Location,
    LocationGod,
    Province,
    TradeRoute,
    World
  }

  test "recreates the reviewed Audrun world graph" do
    assert {"Audrun", "audrun"} in Templates.options()

    assert {:ok, %World{} = world} =
             Worlds.create_world_from_template(:audrun, %{name: "Audrun Recreated"})

    assert world.galaxy.name == "Elvstjerne"
    assert world.galaxy.description =~ "barred spiral galaxy"
    assert world.galaxy.description =~ "interstellar dust"
    assert world.primary_star_name == "Eldvar"
    assert world.orbital_period_days == 365
    assert Decimal.equal?(world.day_length_hours, Decimal.new("24.0"))
    assert Decimal.equal?(world.surface_gravity_m_s2, Decimal.new("9.86"))

    continent_ids = ids_for(Continent, :world_id, [world.id])
    province_ids = ids_for(Province, :continent_id, continent_ids)
    hold_ids = ids_for(Hold, :province_id, province_ids)
    location_ids = ids_for(Location, :hold_id, hold_ids)
    character_ids = ids_for(Character, :world_id, [world.id])

    assert length(continent_ids) == 1
    assert length(province_ids) == 9
    assert length(hold_ids) == 54
    assert length(location_ids) == 372
    assert count(Assembly, :world_id, [world.id]) == 64
    assert count(TradeRoute, :world_id, [world.id]) == 40
    assert length(character_ids) == 64
    assert count(CreatureLocation, :location_id, location_ids) == 173
    assert count(CharacterLocation, :character_id, character_ids) == 94
    assert count(CharacterSkill, :character_id, character_ids) == 101
    assert count(CharacterRelationship, :world_id, [world.id]) == 10
    assert count(LocationGod, :location_id, location_ids) == 18
    assert count(Item, :world_id, [world.id]) == 66

    assert Repo.aggregate(
             from(item in Item,
               where: item.world_id == ^world.id and item.authenticity == :historic
             ),
             :count
           ) == 5

    refute Repo.exists?(
             from(character in Character,
               where: character.world_id == ^world.id and character.name in ["Eirik", "Maren"]
             )
           )
  end

  defp ids_for(_schema, _field, []), do: []

  defp ids_for(schema, field_name, values) do
    schema
    |> where([record], field(record, ^field_name) in ^values)
    |> select([record], record.id)
    |> Repo.all()
  end

  defp count(_schema, _field, []), do: 0

  defp count(schema, field_name, values) do
    Repo.aggregate(from(record in schema, where: field(record, ^field_name) in ^values), :count)
  end
end
