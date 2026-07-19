defmodule AncientStone.WorldsTest do
  use AncientStone.DataCase, async: true

  alias AncientStone.Worlds
  alias AncientStone.Worlds.Continent
  alias AncientStone.Worlds.Hold
  alias AncientStone.Worlds.Province

  test "creates a world map hierarchy" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})

    assert {:ok, %Continent{} = continent} =
             Worlds.create_continent(world, %{
               name: "Tamriel",
               world_id: Ecto.UUID.generate()
             })

    assert continent.world_id == world.id

    assert {:ok, %Province{} = province} =
             Worlds.create_province(continent, %{
               name: "Skyrim",
               continent_id: Ecto.UUID.generate()
             })

    assert province.continent_id == continent.id

    assert {:ok, %Hold{} = hold} =
             Worlds.create_hold(province, %{
               name: "Whiterun Hold",
               province_id: Ecto.UUID.generate()
             })

    assert hold.province_id == province.id
  end

  test "lists map regions in name order" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})

    {:ok, _rift} = Worlds.create_hold(province, %{name: "The Rift"})
    {:ok, _whiterun} = Worlds.create_hold(province, %{name: "Whiterun Hold"})
    {:ok, _eastmarch} = Worlds.create_hold(province, %{name: "Eastmarch"})

    assert Enum.map(Worlds.list_continents(world), & &1.name) == ["Tamriel"]
    assert Enum.map(Worlds.list_provinces(continent), & &1.name) == ["Skyrim"]

    assert Enum.map(Worlds.list_holds(province), & &1.name) == [
             "Eastmarch",
             "The Rift",
             "Whiterun Hold"
           ]
  end

  test "requires region names to be unique within their parent" do
    {:ok, world} = Worlds.create_world(%{name: "Nirn"})
    {:ok, continent} = Worlds.create_continent(world, %{name: "Tamriel"})
    {:ok, province} = Worlds.create_province(continent, %{name: "Skyrim"})

    assert {:error, continent_changeset} = Worlds.create_continent(world, %{name: "Tamriel"})
    assert %{name: [_]} = errors_on(continent_changeset)

    assert {:error, province_changeset} = Worlds.create_province(continent, %{name: "Skyrim"})
    assert %{name: [_]} = errors_on(province_changeset)

    assert {:ok, _hold} = Worlds.create_hold(province, %{name: "Whiterun Hold"})
    assert {:error, hold_changeset} = Worlds.create_hold(province, %{name: "Whiterun Hold"})
    assert %{name: [_]} = errors_on(hold_changeset)
  end
end
