defmodule AncientStones.Worlds do
  @moduledoc """
  Geography workspace operations for worlds, regions, holds, location types,
  and locations.
  """

  import Ecto.Query

  alias AncientStones.Galaxies
  alias AncientStones.Repo
  alias AncientStones.Worlds.Assembly
  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.CalendarMonth
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CharacterInventoryCategory
  alias AncientStones.Worlds.CharacterInventoryItem
  alias AncientStones.Worlds.CharacterLocation
  alias AncientStones.Worlds.CharacterOccupation
  alias AncientStones.Worlds.CharacterRelationship
  alias AncientStones.Worlds.CharacterRole
  alias AncientStones.Worlds.CharacterSkill
  alias AncientStones.Worlds.CharacterSpellbookEntry
  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.CivilizationLocation
  alias AncientStones.Worlds.CivilizationRace
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.ContinentCurrency
  alias AncientStones.Worlds.CommodityBalance
  alias AncientStones.Worlds.CommercialVenture
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.CreatureLocation
  alias AncientStones.Worlds.CreatureType
  alias AncientStones.Worlds.Document
  alias AncientStones.Worlds.Effect
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.GuildInfluence
  alias AncientStones.Worlds.GuildMembership
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.HoldCommerceEntry
  alias AncientStones.Worlds.HoldEconomicProfile
  alias AncientStones.Worlds.Household
  alias AncientStones.Worlds.HouseholdMembership
  alias AncientStones.Worlds.Item
  alias AncientStones.Worlds.ItemEffect
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.LocationGod
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.Landholding
  alias AncientStones.Worlds.Moon
  alias AncientStones.Worlds.Occupation
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.ProvinceWaterBody
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.RaceTrait
  alias AncientStones.Worlds.TaxExemption
  alias AncientStones.Worlds.TaxAssessment
  alias AncientStones.Worlds.TaxPolicy
  alias AncientStones.Worlds.TaxRevenueShare
  alias AncientStones.Worlds.TradeFlow
  alias AncientStones.Worlds.TradeRoute
  alias AncientStones.Worlds.TradeRouteLeg
  alias AncientStones.Worlds.TradeRouteLegWater
  alias AncientStones.Worlds.TradeRouteStop
  alias AncientStones.Worlds.VentureMembership
  alias AncientStones.Worlds.VentureTradeRoute
  alias AncientStones.Worlds.LoreConnection
  alias AncientStones.Worlds.Skill
  alias AncientStones.Worlds.SkillLevel
  alias AncientStones.Worlds.SkillTree
  alias AncientStones.Worlds.SkillTreePerk
  alias AncientStones.Worlds.Spell
  alias AncientStones.Templates
  alias AncientStones.Worlds.Timeline
  alias AncientStones.Worlds.TimelineEra
  alias AncientStones.Worlds.TimelineEvent
  alias AncientStones.Worlds.World
  alias AncientStones.Worlds.WaterBody
  alias AncientStones.Worlds.WaterBodyConnection

  @earth_gravitational_parameter_km3_s2 398_600.4418
  @lunar_mass_earths 0.0123000371
  @seconds_per_day 86_400.0
  @max_world_mass_earths "99999.99999"
  @max_moon_mass_lunar "9999.999999"
  @max_bigint "9223372036854775807"

  @doc "Lists worlds alphabetically for the geography workspace."
  def list_worlds do
    World
    |> order_by([world], asc: world.name)
    |> Repo.all()
    |> Repo.preload(:galaxy)
  end

  @doc "Lists worlds that are not nested under a galaxy."
  def list_worlds_without_galaxy do
    World
    |> where([world], is_nil(world.galaxy_id))
    |> order_by([world], asc: world.name)
    |> Repo.all()
    |> Repo.preload(:galaxy)
  end

  @doc "Returns compact record counts for the builder console inventory."
  def geography_inventory do
    %{
      worlds: Repo.aggregate(World, :count),
      holds: Repo.aggregate(Hold, :count),
      location_types: Repo.aggregate(LocationType, :count),
      locations: Repo.aggregate(Location, :count)
    }
  end

  @doc "Returns geography counts keyed by world id."
  def world_geography_counts(world_ids) do
    world_ids = List.wrap(world_ids)

    base_counts =
      Map.new(world_ids, fn world_id ->
        {world_id, %{holds: 0, location_types: 0, locations: 0}}
      end)

    base_counts
    |> merge_count(:holds, hold_counts_by_world(world_ids))
    |> merge_count(:location_types, location_type_counts_by_world(world_ids))
    |> merge_count(:locations, location_counts_by_world(world_ids))
  end

  def get_world!(id) do
    World
    |> Repo.get!(id)
    |> Repo.preload([:galaxy, :moons])
  end

  @doc "Loads a world with the geography associations needed by the dashboard."
  def get_world_dashboard!(id) do
    World
    |> Repo.get!(id)
    |> Repo.preload(
      assemblies: [:continent, :province, :hold, :location],
      characters: [
        :character_role,
        :race,
        :guild,
        :home_location,
        guild_memberships: [:guild],
        inventory_categories: [],
        inventory_items: [:item, :inventory_category],
        character_occupations: [:occupation],
        character_skills: [:skill],
        spellbook_entries: [:spell],
        venture_memberships: [:commercial_venture]
      ],
      character_roles: [],
      civilizations: [
        :timeline_era,
        civilization_locations: [:location],
        civilization_races: [:race]
      ],
      continents: [
        :currency,
        :assemblies,
        calendars: [:months],
        provinces: [
          :capital_hold,
          :assemblies,
          political_offices: [:character, :designated_successor],
          holds: [
            :assemblies,
            :capital_location,
            :commerce_entries,
            :economic_profile,
            :commodity_balances,
            political_offices: [:character, :designated_successor],
            locations: [
              :gods,
              :location_type,
              :location_gods,
              :water_body,
              character_locations: [:character],
              creature_locations: [creature: [:creature_type]],
              child_locations: [
                :gods,
                :location_gods,
                :location_type,
                :water_body,
                character_locations: [:character]
              ]
            ]
          ]
        ]
      ],
      creature_types: [],
      creatures: [:creature_type, creature_locations: [:location]],
      documents: [
        :author_character,
        :location,
        :guild,
        :god,
        :race,
        :civilization
      ],
      galaxy: [:worlds],
      gods: [],
      guilds: [
        guild_influences: [:god, :character],
        guild_memberships: [:character]
      ],
      effects: [],
      items: [:find_location, item_effects: [:effect]],
      location_types: [:children],
      moons: [],
      occupations: [],
      political_offices: [
        :character,
        :designated_successor,
        :continent,
        :province,
        :hold
      ],
      races: [:traits, civilization_races: [:civilization]],
      lore_connections: [
        :source_character,
        :source_guild,
        :source_god,
        :source_race,
        :source_civilization,
        :source_location,
        :source_hold,
        :source_province,
        :source_continent,
        :target_character,
        :target_guild,
        :target_god,
        :target_race,
        :target_civilization,
        :target_location,
        :target_hold,
        :target_province,
        :target_continent
      ],
      skills: [:levels, skill_tree: [:perks]],
      skill_trees: [:skills, :perks],
      spells: [],
      timelines: [:events, eras: [:events]]
    )
  end

  def change_world(%World{} = world, attrs \\ %{}) do
    World.changeset(world, attrs)
  end

  def change_new_world(attrs \\ %{}) do
    attrs = prepare_world_creation_attrs(attrs)

    %World{moons: []}
    |> World.creation_changeset(attrs)
  end

  def create_world(attrs) do
    attrs = prepare_world_creation_attrs(attrs)

    %World{moons: []}
    |> World.creation_changeset(attrs)
    |> Repo.insert()
  end

  def update_world(%World{} = world, attrs) do
    world
    |> World.changeset(attrs)
    |> Repo.update()
  end

  def update_world(%World{} = world, attrs, refs) do
    world
    |> World.changeset(attrs)
    |> put_ref(:galaxy_id, refs[:galaxy])
    |> Repo.update()
  end

  def update_world_with_moons(%World{} = world, attrs) do
    world = Repo.preload(world, :moons, force: true)
    attrs = prepare_world_moon_attrs(attrs, world.mass_earths)

    world
    |> World.update_with_moons_changeset(attrs)
    |> Repo.update()
  end

  def update_world_with_moons(%World{} = world, attrs, refs) do
    world = Repo.preload(world, :moons, force: true)
    attrs = prepare_world_moon_attrs(attrs, world.mass_earths)

    world
    |> World.update_with_moons_changeset(attrs)
    |> put_ref(:galaxy_id, refs[:galaxy])
    |> Repo.update()
  end

  def create_world(attrs, refs) do
    attrs = prepare_world_creation_attrs(attrs)

    %World{moons: []}
    |> World.creation_changeset(attrs)
    |> put_optional_ref(:galaxy_id, refs[:galaxy])
    |> Repo.insert()
  end

  @doc "Deletes a world and its geography graph in dependency order."
  def delete_world(%World{id: world_id} = world) do
    Repo.transaction(fn ->
      continent_ids = continent_ids_for_world(world_id)
      province_ids = province_ids_for_continents(continent_ids)
      hold_ids = hold_ids_for_provinces(province_ids)

      delete_tax_assessments_for_world(world_id)
      delete_commercial_venture_graph_for_world(world_id)
      delete_waterway_graph_for_world(world_id)
      delete_landholdings_for_world(world_id)
      delete_character_relationships_for_world(world_id)
      delete_household_memberships_for_world(world_id)
      delete_locations_for_holds(hold_ids)
      delete_location_types_for_world(world_id)
      delete_holds_by_ids(hold_ids)
      delete_provinces_by_ids(province_ids)
      delete_continents_by_ids(continent_ids)

      world
      |> Repo.delete()
      |> unwrap_transaction!()
    end)
  end

  @doc "Creates a world and starter geography from a named template."
  def create_world_from_template(template, attrs, refs \\ %{}) do
    case Templates.get(template) do
      {:ok, template_data} ->
        attrs = merge_template_attrs(template_data, attrs)

        Repo.transaction(fn ->
          galaxy_by_name = ensure_template_galaxies!(Map.get(template_data, :galaxies, []))

          galaxy =
            refs[:galaxy] ||
              Map.get(galaxy_by_name, template_data[:galaxy])

          world =
            attrs
            |> create_world(galaxy: galaxy)
            |> unwrap_transaction!()

          build_template_world!(world, template_data)
        end)

      :error ->
        {:error, :unknown_template}
    end
  end

  def list_continents(%World{id: world_id}) do
    Continent
    |> where([continent], continent.world_id == ^world_id)
    |> order_by([continent], asc: continent.name)
    |> Repo.all()
  end

  def get_continent!(id) do
    Repo.get!(Continent, id)
  end

  def change_continent(%Continent{} = continent, attrs \\ %{}) do
    Continent.changeset(continent, attrs)
  end

  def create_continent(%World{id: world_id}, attrs) do
    %Continent{world_id: world_id}
    |> Continent.changeset(attrs)
    |> Repo.insert()
  end

  def update_continent(%Continent{} = continent, attrs) do
    continent
    |> Continent.changeset(attrs)
    |> Repo.update()
  end

  def put_continent_currency(%Continent{id: continent_id} = continent, attrs) do
    case normalized_currency_attrs(attrs) do
      nil ->
        delete_continent_currency(continent)

      currency_attrs ->
        continent
        |> Repo.preload(:currency)
        |> Map.get(:currency)
        |> case do
          nil ->
            %ContinentCurrency{continent_id: continent_id}

          currency ->
            currency
        end
        |> ContinentCurrency.changeset(currency_attrs)
        |> Repo.insert_or_update()
    end
  end

  defp normalized_currency_attrs(attrs) do
    name =
      attrs
      |> Map.get("name", Map.get(attrs, :name))
      |> blank_to_nil()

    description =
      attrs
      |> Map.get("description", Map.get(attrs, :description))
      |> blank_to_nil()

    if name do
      %{
        "name" => name,
        "description" => description,
        "value_per_unit" => Map.get(attrs, "value_per_unit", Map.get(attrs, :value_per_unit)),
        "value_basis" => Map.get(attrs, "value_basis", Map.get(attrs, :value_basis))
      }
    end
  end

  defp delete_continent_currency(%Continent{} = continent) do
    continent
    |> Repo.preload(:currency)
    |> Map.get(:currency)
    |> case do
      nil -> {:ok, nil}
      currency -> Repo.delete(currency)
    end
  end

  defp blank_to_nil(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp blank_to_nil(value) do
    value
  end

  def create_timeline(%World{id: world_id}, attrs) do
    %Timeline{world_id: world_id}
    |> Timeline.changeset(attrs)
    |> Repo.insert()
  end

  def get_timeline!(id) do
    Timeline
    |> Repo.get!(id)
    |> Repo.preload([:events, eras: [:events]])
  end

  def delete_timeline(%Timeline{} = timeline) do
    Repo.delete(timeline)
  end

  def create_timeline_era(%Timeline{id: timeline_id}, attrs) do
    %TimelineEra{timeline_id: timeline_id}
    |> TimelineEra.changeset(attrs)
    |> Repo.insert()
  end

  def get_timeline_era!(id) do
    TimelineEra
    |> Repo.get!(id)
    |> Repo.preload([:events, :timeline])
  end

  def delete_timeline_era(%TimelineEra{} = timeline_era) do
    Repo.delete(timeline_era)
  end

  def create_timeline_event(%Timeline{id: timeline_id} = timeline, attrs, refs \\ %{}) do
    with {:ok, timeline_era} <- timeline_event_era(timeline, refs[:timeline_era]) do
      %TimelineEvent{timeline_id: timeline_id}
      |> TimelineEvent.changeset(attrs)
      |> put_optional_ref(:timeline_era_id, timeline_era)
      |> Repo.insert()
    end
  end

  def get_timeline_event!(id) do
    TimelineEvent
    |> Repo.get!(id)
    |> Repo.preload([:timeline, :timeline_era])
  end

  def delete_timeline_event(%TimelineEvent{} = timeline_event) do
    Repo.delete(timeline_event)
  end

  def create_civilization(%World{id: world_id}, attrs, refs \\ %{}) do
    %Civilization{world_id: world_id}
    |> Civilization.changeset(attrs)
    |> put_optional_ref(:timeline_era_id, refs[:timeline_era])
    |> Repo.insert()
  end

  def get_civilization!(id) do
    Civilization
    |> Repo.get!(id)
    |> Repo.preload([
      :timeline_era,
      civilization_locations: [:location],
      civilization_races: [:race]
    ])
  end

  def delete_civilization(%Civilization{} = civilization) do
    Repo.delete(civilization)
  end

  def create_civilization_race(
        %Civilization{id: civilization_id},
        %Race{id: race_id},
        attrs
      ) do
    %CivilizationRace{civilization_id: civilization_id, race_id: race_id}
    |> CivilizationRace.changeset(attrs)
    |> Repo.insert()
  end

  def create_civilization_location(
        %Civilization{id: civilization_id},
        %Location{id: location_id},
        attrs
      ) do
    %CivilizationLocation{civilization_id: civilization_id, location_id: location_id}
    |> CivilizationLocation.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Deletes a continent and all nested provinces, holds, and locations."
  def delete_continent(%Continent{id: continent_id} = continent) do
    province_ids = province_ids_for_continents([continent_id])
    hold_ids = hold_ids_for_provinces(province_ids)

    Repo.transaction(fn ->
      lock_continents([continent_id])
      lock_provinces(province_ids)
      lock_geography_holds(hold_ids)

      cond do
        landholdings_for_hold_ids?(hold_ids) ->
          Repo.rollback(:geography_has_landholdings)

        trade_route_stops_for_hold_ids?(hold_ids) ->
          Repo.rollback(:geography_has_trade_route_stops)

        true ->
          delete_locations_for_holds(hold_ids)
          delete_holds_by_ids(hold_ids)
          delete_provinces_by_ids(province_ids)

          continent
          |> Repo.delete()
          |> unwrap_transaction!()
      end
    end)
  end

  def list_provinces(%Continent{id: continent_id}) do
    Province
    |> where([province], province.continent_id == ^continent_id)
    |> order_by([province], asc: province.name)
    |> Repo.all()
  end

  def get_province!(id) do
    Repo.get!(Province, id)
  end

  def change_province(%Province{} = province, attrs \\ %{}) do
    Province.changeset(province, attrs)
  end

  def create_province(%Continent{id: continent_id}, attrs) do
    %Province{continent_id: continent_id}
    |> Province.changeset(attrs)
    |> Repo.insert()
  end

  def update_province(%Province{} = province, %Continent{id: continent_id}, attrs) do
    province
    |> Province.changeset(attrs)
    |> Ecto.Changeset.put_change(:continent_id, continent_id)
    |> Repo.update()
  end

  @doc "Deletes a province and all nested holds and locations."
  def delete_province(%Province{id: province_id} = province) do
    hold_ids = hold_ids_for_provinces([province_id])

    Repo.transaction(fn ->
      lock_provinces([province_id])
      lock_geography_holds(hold_ids)

      cond do
        landholdings_for_hold_ids?(hold_ids) ->
          Repo.rollback(:geography_has_landholdings)

        trade_route_stops_for_hold_ids?(hold_ids) ->
          Repo.rollback(:geography_has_trade_route_stops)

        true ->
          delete_locations_for_holds(hold_ids)
          delete_holds_by_ids(hold_ids)

          province
          |> Repo.delete()
          |> unwrap_transaction!()
      end
    end)
  end

  def list_holds(%Province{id: province_id}) do
    Hold
    |> where([hold], hold.province_id == ^province_id)
    |> order_by([hold], asc: hold.name)
    |> Repo.all()
  end

  def get_hold!(id) do
    Repo.get!(Hold, id)
  end

  def change_hold(%Hold{} = hold, attrs \\ %{}) do
    Hold.changeset(hold, attrs)
  end

  def create_hold(%Province{id: province_id}, attrs) do
    %Hold{province_id: province_id}
    |> Hold.changeset(attrs)
    |> Repo.insert()
  end

  def update_hold(%Hold{} = hold, %Province{id: province_id}, attrs, opts \\ []) do
    capital_location = Keyword.get(opts, :capital_location, :unchanged)
    province_capital? = Keyword.get(opts, :province_capital, false)

    with :ok <- validate_hold_capital_location(hold, capital_location) do
      Repo.transaction(fn ->
        updated_hold =
          hold
          |> Hold.changeset(attrs)
          |> Ecto.Changeset.put_change(:province_id, province_id)
          |> maybe_put_capital_location(capital_location)
          |> Repo.update()
          |> unwrap_transaction!()

        sync_province_capital_hold(hold, updated_hold, province_capital?)

        updated_hold
      end)
    end
  end

  @doc "Deletes a hold and all locations inside it."
  def delete_hold(%Hold{id: hold_id} = hold) do
    Repo.transaction(fn ->
      lock_geography_holds([hold_id])

      cond do
        landholdings_for_hold_ids?([hold_id]) ->
          Repo.rollback(:geography_has_landholdings)

        trade_route_stops_for_hold_ids?([hold_id]) ->
          Repo.rollback(:geography_has_trade_route_stops)

        true ->
          delete_locations_for_holds([hold_id])

          hold
          |> Repo.delete()
          |> unwrap_transaction!()
      end
    end)
  end

  def list_guilds(%World{id: world_id}) do
    Guild
    |> where([guild], guild.world_id == ^world_id)
    |> order_by([guild], asc: guild.name)
    |> Repo.all()
  end

  def get_guild!(id) do
    Guild
    |> Repo.get!(id)
    |> Repo.preload(
      guild_influences: [:god, :character],
      guild_memberships: [:character]
    )
  end

  def change_guild(%Guild{} = guild, attrs \\ %{}) do
    Guild.changeset(guild, attrs)
  end

  def create_guild(%World{id: world_id}, attrs) do
    %Guild{world_id: world_id}
    |> Guild.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Deletes a guild from a world."
  def delete_guild(%Guild{} = guild) do
    Repo.delete(guild)
  end

  def create_guild_influence(%Guild{id: guild_id}, attrs, refs \\ %{}) do
    %GuildInfluence{guild_id: guild_id}
    |> GuildInfluence.changeset(attrs)
    |> put_optional_ref(:god_id, refs[:god])
    |> put_optional_ref(:character_id, refs[:character])
    |> Repo.insert()
  end

  def get_guild_influence!(id) do
    GuildInfluence
    |> Repo.get!(id)
    |> Repo.preload([:guild, :god, :character])
  end

  @doc "Deletes a guild influence relationship."
  def delete_guild_influence(%GuildInfluence{} = guild_influence) do
    Repo.delete(guild_influence)
  end

  def get_guild_membership!(%World{id: world_id}, id) do
    GuildMembership
    |> join(:inner, [membership], guild in assoc(membership, :guild))
    |> where([_membership, guild], guild.world_id == ^world_id)
    |> where([membership], membership.id == ^id)
    |> preload([:guild, :character])
    |> Repo.one!()
  end

  def create_guild_membership(%World{id: world_id}, attrs) do
    changeset = GuildMembership.changeset(%GuildMembership{}, attrs)

    with %Guild{} = guild <- Repo.get_by(Guild, id: attrs["guild_id"], world_id: world_id),
         %Character{} = character <-
           Repo.get_by(Character, id: attrs["character_id"], world_id: world_id) do
      Repo.transaction(fn ->
        changeset =
          changeset
          |> Ecto.Changeset.put_change(:guild_id, guild.id)
          |> Ecto.Changeset.put_change(:character_id, character.id)
          |> default_first_membership_to_primary(character.id)

        if Ecto.Changeset.get_field(changeset, :is_primary) do
          clear_primary_membership(character.id)
        end

        membership =
          changeset
          |> Repo.insert()
          |> unwrap_transaction!()

        sync_character_primary_guild(character.id)
        sync_guild_leader(guild.id)
        Repo.preload(membership, [:guild, :character])
      end)
    else
      nil ->
        {:error,
         Ecto.Changeset.add_error(
           changeset,
           :character_id,
           "must identify a character and guild from this world"
         )}
    end
  end

  def update_guild_membership(%GuildMembership{} = membership, attrs) do
    Repo.transaction(fn ->
      changeset = GuildMembership.changeset(membership, attrs)

      if Ecto.Changeset.get_field(changeset, :is_primary) do
        clear_primary_membership(membership.character_id, membership.id)
      end

      updated_membership =
        changeset
        |> Repo.update()
        |> unwrap_transaction!()

      ensure_primary_membership(membership.character_id)
      sync_character_primary_guild(membership.character_id)
      sync_guild_leader(membership.guild_id)
      Repo.preload(updated_membership, [:guild, :character])
    end)
  end

  def delete_guild_membership(%GuildMembership{} = membership) do
    Repo.transaction(fn ->
      deleted_membership =
        membership
        |> Repo.delete()
        |> unwrap_transaction!()

      ensure_primary_membership(membership.character_id)
      sync_character_primary_guild(membership.character_id)
      sync_guild_leader(membership.guild_id)
      deleted_membership
    end)
  end

  def list_gods(%World{id: world_id}) do
    God
    |> where([god], god.world_id == ^world_id)
    |> order_by([god], asc: god.name)
    |> Repo.all()
  end

  def get_god!(id) do
    Repo.get!(God, id)
  end

  def create_god(%World{id: world_id}, attrs) do
    %God{world_id: world_id}
    |> God.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Deletes a god from a world."
  def delete_god(%God{} = god) do
    Repo.delete(god)
  end

  def list_location_gods(%World{id: world_id}) do
    LocationGod
    |> join(:inner, [link], god in assoc(link, :god))
    |> where([_link, god], god.world_id == ^world_id)
    |> order_by([link], asc: link.role)
    |> Repo.all()
    |> Repo.preload([:location, :god])
  end

  def create_location_god(
        %World{id: world_id},
        %Location{id: location_id},
        %God{id: god_id, world_id: god_world_id},
        attrs
      ) do
    if god_world_id == world_id and location_in_world?(location_id, world_id) do
      %LocationGod{}
      |> LocationGod.changeset(attrs, %{location_id: location_id, god_id: god_id})
      |> Repo.insert()
    else
      {:error, :reference_outside_world}
    end
  end

  def delete_location_god(%LocationGod{} = location_god) do
    Repo.delete(location_god)
  end

  def create_document(%World{id: world_id}, attrs, refs \\ %{}) do
    %Document{world_id: world_id}
    |> Document.changeset(attrs)
    |> put_document_refs(refs)
    |> Repo.insert()
  end

  def get_document!(id) do
    Document
    |> Repo.get!(id)
    |> Repo.preload([:author_character, :location, :guild, :god, :race, :civilization])
  end

  def update_document(%Document{} = document, attrs, refs \\ %{}) do
    document
    |> Document.changeset(attrs)
    |> put_document_refs(refs)
    |> Repo.update()
  end

  def delete_document(%Document{} = document) do
    Repo.delete(document)
  end

  def create_lore_connection(%World{id: world_id}, attrs, refs) do
    %LoreConnection{world_id: world_id}
    |> LoreConnection.changeset(attrs)
    |> put_lore_connection_refs(refs)
    |> Repo.insert()
  end

  def get_lore_connection!(id) do
    LoreConnection
    |> Repo.get!(id)
    |> Repo.preload(lore_connection_preloads())
  end

  def update_lore_connection(%LoreConnection{} = lore_connection, attrs, refs) do
    lore_connection
    |> LoreConnection.changeset(attrs)
    |> clear_lore_connection_refs()
    |> put_lore_connection_refs(refs)
    |> Repo.update()
  end

  def delete_lore_connection(%LoreConnection{} = lore_connection) do
    Repo.delete(lore_connection)
  end

  def list_characters(%World{id: world_id}) do
    Character
    |> where([character], character.world_id == ^world_id)
    |> order_by([character], asc: character.name)
    |> Repo.all()
    |> Repo.preload([
      :character_role,
      :race,
      :guild,
      :home_location,
      guild_memberships: [:guild],
      character_occupations: [:occupation],
      character_skills: [:skill]
    ])
  end

  def get_character!(id) do
    Character
    |> Repo.get!(id)
    |> Repo.preload([
      :character_role,
      :race,
      :guild,
      :home_location,
      guild_memberships: [:guild],
      character_occupations: [:occupation],
      character_skills: [:skill]
    ])
  end

  def create_character(%World{id: world_id}, attrs, refs \\ %{}) do
    Repo.transaction(fn ->
      character =
        %Character{world_id: world_id}
        |> Character.changeset(attrs)
        |> put_optional_ref(:character_role_id, refs[:character_role])
        |> put_optional_ref(:race_id, refs[:race])
        |> put_optional_ref(:guild_id, refs[:guild])
        |> put_optional_ref(:home_location_id, refs[:home_location])
        |> Repo.insert()
        |> unwrap_transaction!()

      sync_legacy_character_membership(character)

      if occupation = refs[:occupation] do
        unwrap_transaction!(create_character_occupation(character, occupation, %{primary: true}))
      end

      if skill = refs[:skill] do
        unwrap_transaction!(create_character_skill(character, skill, %{}))
      end

      character
    end)
  end

  def update_character(%Character{} = character, attrs, refs \\ %{}) do
    Repo.transaction(fn ->
      updated_character =
        character
        |> Character.changeset(attrs)
        |> put_ref(:character_role_id, refs[:character_role])
        |> put_ref(:race_id, refs[:race])
        |> put_ref(:guild_id, refs[:guild])
        |> put_ref(:home_location_id, refs[:home_location])
        |> Repo.update()
        |> unwrap_transaction!()

      sync_legacy_character_membership(updated_character)
    end)
  end

  @doc "Lists households in a world without expanding the main dashboard preload."
  def list_households(%World{id: world_id}, search \\ "") do
    Household
    |> where([household], household.world_id == ^world_id)
    |> maybe_search_households(search)
    |> order_by([household], asc: household.name)
    |> Repo.all()
    |> Repo.preload(household_preloads())
  end

  def get_household!(%World{id: world_id}, id) do
    Household
    |> where([household], household.world_id == ^world_id and household.id == ^id)
    |> Repo.one!()
    |> Repo.preload(household_preloads())
  end

  def get_household(%World{}, id) when id in [nil, ""], do: nil

  def get_household(%World{id: world_id}, id) do
    Household
    |> where([household], household.world_id == ^world_id and household.id == ^id)
    |> Repo.one()
    |> case do
      nil -> nil
      household -> Repo.preload(household, household_preloads())
    end
  end

  def change_household(%Household{} = household, attrs \\ %{}) do
    Household.changeset(household, attrs)
  end

  def create_household(%World{id: world_id} = world, attrs, refs \\ []) do
    home_location = Keyword.get(refs, :home_location)
    head_character = Keyword.get(refs, :head_character)

    with :ok <- validate_optional_location_world(home_location, world_id, :home_location),
         :ok <- validate_optional_character_world(head_character, world_id) do
      changeset =
        %Household{world_id: world_id}
        |> Household.changeset(attrs)
        |> put_optional_ref(:home_location_id, home_location)

      Ecto.Multi.new()
      |> Ecto.Multi.insert(:household, changeset)
      |> maybe_add_household_head(head_character)
      |> Repo.transact()
      |> case do
        {:ok, %{household: household}} -> {:ok, get_household!(world, household.id)}
        {:error, _operation, reason, _changes} -> {:error, reason}
      end
    end
  end

  def update_household(%Household{} = household, attrs, refs \\ []) do
    home_location = Keyword.get(refs, :home_location)

    with :ok <-
           validate_optional_location_world(home_location, household.world_id, :home_location) do
      household
      |> Household.changeset(attrs)
      |> put_ref(:home_location_id, home_location)
      |> Repo.update()
    end
  end

  def delete_household(%Household{id: household_id} = household) do
    cond do
      Repo.exists?(from holding in Landholding, where: holding.household_id == ^household_id) ->
        {:error, :household_has_landholdings}

      Repo.exists?(
        from membership in VentureMembership,
          where: membership.household_id == ^household_id
      ) ->
        {:error, :household_has_venture_history}

      true ->
        household
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.no_assoc_constraint(:venture_memberships)
        |> Repo.delete()
    end
  end

  def create_household_membership(
        %Household{} = household,
        %Character{} = character,
        attrs
      ) do
    with :ok <- validate_character_world(character, household.world_id) do
      %HouseholdMembership{household_id: household.id, character_id: character.id}
      |> HouseholdMembership.changeset(attrs)
      |> Repo.insert()
    end
  end

  def list_household_memberships(%Household{id: household_id}) do
    HouseholdMembership
    |> where([membership], membership.household_id == ^household_id)
    |> order_by([membership], desc: membership.is_primary, asc: membership.inserted_at)
    |> Repo.all()
    |> Repo.preload([:character, household: [:home_location]])
  end

  def get_household_membership!(%World{id: world_id}, id) do
    HouseholdMembership
    |> join(:inner, [membership], household in assoc(membership, :household))
    |> where([membership, household], membership.id == ^id and household.world_id == ^world_id)
    |> Repo.one!()
    |> Repo.preload([:character, household: [:home_location]])
  end

  def change_household_membership(%HouseholdMembership{} = membership, attrs \\ %{}) do
    HouseholdMembership.changeset(membership, attrs)
  end

  def update_household_membership(%HouseholdMembership{} = membership, attrs) do
    membership
    |> HouseholdMembership.changeset(attrs)
    |> Repo.update()
  end

  def delete_household_membership(%HouseholdMembership{} = membership) do
    Repo.delete(membership)
  end

  @doc "Lists kinship, marriage, fosterage, and guardianship ties for one world."
  def list_character_relationships(%World{id: world_id}, search \\ "") do
    CharacterRelationship
    |> where([relationship], relationship.world_id == ^world_id)
    |> join(:inner, [relationship], character_a in assoc(relationship, :character_a))
    |> join(
      :inner,
      [relationship, _character_a],
      character_b in assoc(relationship, :character_b)
    )
    |> maybe_search_character_relationships(search)
    |> order_by([relationship, character_a, character_b],
      asc: character_a.name,
      asc: character_b.name
    )
    |> preload([_relationship, character_a, character_b],
      character_a: character_a,
      character_b: character_b
    )
    |> Repo.all()
  end

  def get_character_relationship!(%World{id: world_id}, id) do
    CharacterRelationship
    |> where([relationship], relationship.world_id == ^world_id and relationship.id == ^id)
    |> Repo.one!()
    |> Repo.preload([:character_a, :character_b])
  end

  def change_character_relationship(%CharacterRelationship{} = relationship, attrs \\ %{}) do
    CharacterRelationship.changeset(relationship, attrs)
  end

  def create_character_relationship(
        %World{id: world_id},
        %Character{} = character_a,
        %Character{} = character_b,
        attrs
      ) do
    with :ok <- validate_character_world(character_a, world_id),
         :ok <- validate_character_world(character_b, world_id),
         :ok <- validate_distinct_characters(character_a, character_b) do
      {canonical_a, canonical_b, canonical_attrs} =
        canonical_relationship(character_a, character_b, default_relationship_roles(attrs))

      %CharacterRelationship{
        world_id: world_id,
        character_a_id: canonical_a.id,
        character_b_id: canonical_b.id
      }
      |> CharacterRelationship.changeset(canonical_attrs)
      |> Repo.insert()
    end
  end

  def update_character_relationship(%CharacterRelationship{} = relationship, attrs) do
    relationship
    |> CharacterRelationship.changeset(attrs)
    |> Repo.update()
  end

  def update_character_relationship(
        %CharacterRelationship{} = relationship,
        %Character{} = character_a,
        %Character{} = character_b,
        attrs
      ) do
    with :ok <- validate_character_world(character_a, relationship.world_id),
         :ok <- validate_character_world(character_b, relationship.world_id),
         :ok <- validate_distinct_characters(character_a, character_b) do
      {canonical_a, canonical_b, canonical_attrs} =
        canonical_relationship(character_a, character_b, default_relationship_roles(attrs))

      relationship
      |> CharacterRelationship.changeset(canonical_attrs)
      |> Ecto.Changeset.put_change(:character_a_id, canonical_a.id)
      |> Ecto.Changeset.put_change(:character_b_id, canonical_b.id)
      |> Repo.update()
    end
  end

  def delete_character_relationship(%CharacterRelationship{} = relationship) do
    Repo.delete(relationship)
  end

  @doc "Lists household tenure and use records within one world."
  def list_landholdings(%World{id: world_id}, search \\ "") do
    Landholding
    |> join(:inner, [holding], household in assoc(holding, :household))
    |> where([_holding, household], household.world_id == ^world_id)
    |> maybe_search_landholdings(search)
    |> order_by([holding, household], asc: household.name, asc: holding.name)
    |> Repo.all()
    |> Repo.preload([:hold, :location, household: [:home_location]])
  end

  def get_landholding!(%World{id: world_id}, id) do
    Landholding
    |> join(:inner, [holding], household in assoc(holding, :household))
    |> where([holding, household], holding.id == ^id and household.world_id == ^world_id)
    |> Repo.one!()
    |> Repo.preload([:hold, :location, household: [:home_location]])
  end

  def change_landholding(%Landholding{} = landholding, attrs \\ %{}) do
    Landholding.changeset(landholding, attrs)
  end

  def create_landholding(%Household{} = household, attrs, refs) do
    hold = Keyword.get(refs, :hold)
    location = Keyword.get(refs, :location)

    with :ok <- validate_single_landholding_scope(hold, location),
         :ok <- validate_optional_hold_world(hold, household.world_id),
         :ok <- validate_optional_location_world(location, household.world_id, :landholding) do
      %Landholding{
        household_id: household.id,
        hold_id: ref_id(hold),
        location_id: ref_id(location)
      }
      |> Landholding.changeset(attrs)
      |> Repo.insert()
    end
  end

  def update_landholding(%Landholding{} = holding, attrs, refs) do
    household = Repo.get!(Household, holding.household_id)
    hold = Keyword.get(refs, :hold)
    location = Keyword.get(refs, :location)

    with :ok <- validate_single_landholding_scope(hold, location),
         :ok <- validate_optional_hold_world(hold, household.world_id),
         :ok <- validate_optional_location_world(location, household.world_id, :landholding) do
      holding
      |> Landholding.changeset(attrs)
      |> Ecto.Changeset.put_change(:hold_id, ref_id(hold))
      |> Ecto.Changeset.put_change(:location_id, ref_id(location))
      |> Repo.update()
    end
  end

  def delete_landholding(%Landholding{} = landholding) do
    Repo.delete(landholding)
  end

  @doc "Loads the household, relationship, and tenure records shown on one character detail."
  def get_character_society(%World{id: world_id}, %Character{id: character_id}) do
    memberships =
      HouseholdMembership
      |> join(:inner, [membership], household in assoc(membership, :household))
      |> where(
        [membership, household],
        membership.character_id == ^character_id and household.world_id == ^world_id
      )
      |> order_by([membership, household], desc: membership.is_primary, asc: household.name)
      |> Repo.all()
      |> Repo.preload(household: [:home_location, landholdings: [:hold, :location]])

    relationships =
      CharacterRelationship
      |> where(
        [relationship],
        relationship.world_id == ^world_id and
          (relationship.character_a_id == ^character_id or
             relationship.character_b_id == ^character_id)
      )
      |> order_by([relationship], asc: relationship.relationship_type)
      |> Repo.all()
      |> Repo.preload([:character_a, :character_b])

    landholdings =
      memberships
      |> Enum.flat_map(& &1.household.landholdings)
      |> Enum.uniq_by(& &1.id)
      |> Enum.sort_by(& &1.name)

    %{memberships: memberships, relationships: relationships, landholdings: landholdings}
  end

  def create_character_role(%World{id: world_id}, attrs) do
    %CharacterRole{world_id: world_id}
    |> CharacterRole.changeset(attrs)
    |> Repo.insert()
  end

  def get_character_role!(id) do
    Repo.get!(CharacterRole, id)
  end

  def delete_character_role(%CharacterRole{} = character_role) do
    Repo.delete(character_role)
  end

  def create_creature_type(%World{id: world_id}, attrs) do
    %CreatureType{world_id: world_id}
    |> CreatureType.changeset(attrs)
    |> Repo.insert()
  end

  def get_creature_type!(id) do
    CreatureType
    |> Repo.get!(id)
    |> Repo.preload(:creatures)
  end

  def update_creature_type(%CreatureType{} = creature_type, attrs) do
    creature_type
    |> CreatureType.changeset(attrs)
    |> Repo.update()
  end

  def delete_creature_type(%CreatureType{} = creature_type) do
    Repo.delete(creature_type)
  end

  def create_creature(%World{id: world_id}, attrs, refs \\ %{}) do
    %Creature{world_id: world_id}
    |> Creature.changeset(attrs)
    |> put_optional_ref(:creature_type_id, refs[:creature_type])
    |> Repo.insert()
  end

  def get_creature!(id) do
    Creature
    |> Repo.get!(id)
    |> Repo.preload([:creature_type, creature_locations: [:location]])
  end

  def update_creature(%Creature{} = creature, attrs, refs \\ %{}) do
    creature
    |> Creature.changeset(attrs)
    |> put_optional_ref(:creature_type_id, refs[:creature_type])
    |> Repo.update()
  end

  def delete_creature(%Creature{} = creature) do
    Repo.delete(creature)
  end

  def create_creature_location(%Creature{id: creature_id}, %Location{id: location_id}, attrs) do
    %CreatureLocation{creature_id: creature_id, location_id: location_id}
    |> CreatureLocation.changeset(attrs)
    |> Repo.insert()
  end

  def get_creature_location!(id) do
    CreatureLocation
    |> Repo.get!(id)
    |> Repo.preload([:creature, :location])
  end

  def delete_creature_location(%CreatureLocation{} = creature_location) do
    Repo.delete(creature_location)
  end

  def list_moons(%World{id: world_id}) do
    Moon
    |> where([moon], moon.world_id == ^world_id)
    |> order_by([moon], asc: moon.name)
    |> Repo.all()
  end

  def get_moon!(id) do
    Repo.get!(Moon, id)
  end

  def change_moon(%Moon{} = moon, attrs \\ %{}) do
    Moon.changeset(moon, attrs)
  end

  def create_moon(%World{id: world_id}, attrs) do
    %Moon{world_id: world_id}
    |> Moon.changeset(attrs)
    |> Repo.insert()
  end

  def update_moon(%Moon{} = moon, attrs) do
    moon
    |> Moon.changeset(attrs)
    |> Repo.update()
  end

  def delete_moon(%Moon{} = moon) do
    Repo.delete(moon)
  end

  def create_spell(%World{id: world_id}, attrs) do
    %Spell{world_id: world_id}
    |> Spell.changeset(attrs)
    |> Repo.insert()
  end

  def get_spell!(id) do
    Repo.get!(Spell, id)
  end

  def update_spell(%Spell{} = spell, attrs) do
    spell
    |> Spell.changeset(attrs)
    |> Repo.update()
  end

  def delete_spell(%Spell{} = spell) do
    Repo.delete(spell)
  end

  def create_item(%World{id: world_id}, attrs, refs \\ %{}) do
    %Item{world_id: world_id}
    |> Item.changeset(attrs)
    |> put_optional_ref(:find_location_id, refs[:find_location])
    |> Repo.insert()
  end

  def get_item!(id) do
    Item
    |> Repo.get!(id)
    |> Repo.preload([:find_location, item_effects: [:effect]])
  end

  def update_item(%Item{} = item, attrs, refs \\ %{}) do
    item
    |> Item.changeset(attrs)
    |> put_ref_from_refs(refs, :find_location, :find_location_id)
    |> Repo.update()
  end

  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  def create_effect(%World{id: world_id}, attrs) do
    %Effect{world_id: world_id}
    |> Effect.changeset(attrs)
    |> Repo.insert()
  end

  def get_effect!(id) do
    Repo.get!(Effect, id)
  end

  def delete_effect(%Effect{} = effect) do
    Repo.delete(effect)
  end

  def create_item_effect(%Item{id: item_id}, %Effect{id: effect_id}, attrs) do
    %ItemEffect{item_id: item_id, effect_id: effect_id}
    |> ItemEffect.changeset(attrs)
    |> Repo.insert()
  end

  def get_item_effect!(id) do
    ItemEffect
    |> Repo.get!(id)
    |> Repo.preload([:item, :effect])
  end

  def delete_item_effect(%ItemEffect{} = item_effect) do
    Repo.delete(item_effect)
  end

  @doc "Deletes a character from a world."
  def delete_character(%Character{id: character_id} = character) do
    membership_exists? =
      Repo.exists?(
        from membership in HouseholdMembership,
          where: membership.character_id == ^character_id
      )

    relationship_exists? =
      Repo.exists?(
        from relationship in CharacterRelationship,
          where:
            relationship.character_a_id == ^character_id or
              relationship.character_b_id == ^character_id
      )

    venture_membership_exists? =
      Repo.exists?(
        from membership in VentureMembership,
          where: membership.character_id == ^character_id
      )

    if membership_exists? or relationship_exists? or venture_membership_exists? do
      {:error, :character_has_society_history}
    else
      character
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.no_assoc_constraint(:venture_memberships)
      |> Repo.delete()
    end
  end

  def create_occupation(%World{id: world_id}, attrs) do
    %Occupation{world_id: world_id}
    |> Occupation.changeset(attrs)
    |> Repo.insert()
  end

  def get_occupation!(id) do
    Repo.get!(Occupation, id)
  end

  def create_character_occupation(
        %Character{id: character_id},
        %Occupation{id: occupation_id},
        attrs
      ) do
    %CharacterOccupation{character_id: character_id, occupation_id: occupation_id}
    |> CharacterOccupation.changeset(attrs)
    |> Repo.insert()
  end

  def create_skill(%World{id: world_id}, attrs) do
    %Skill{world_id: world_id}
    |> Skill.changeset(attrs)
    |> Repo.insert()
  end

  def create_skill(%World{id: world_id}, attrs, refs) do
    %Skill{world_id: world_id}
    |> Skill.changeset(attrs)
    |> put_optional_ref(:skill_tree_id, refs[:skill_tree])
    |> Repo.insert()
  end

  def create_skill_with_tree(%World{} = world, attrs) do
    Repo.transaction(fn ->
      skill_tree =
        world
        |> create_skill_tree(skill_tree_attrs(attrs))
        |> unwrap_transaction!()

      world
      |> create_skill(attrs, skill_tree: skill_tree)
      |> unwrap_transaction!()
    end)
  end

  def get_skill!(id) do
    Skill
    |> Repo.get!(id)
    |> Repo.preload([:levels, skill_tree: [:perks]])
  end

  def update_skill(%Skill{} = skill, attrs) do
    skill
    |> Skill.changeset(attrs)
    |> Repo.update()
  end

  def delete_skill(%Skill{} = skill) do
    Repo.delete(skill)
  end

  def create_character_skill(%Character{id: character_id}, %Skill{id: skill_id}, attrs) do
    %CharacterSkill{character_id: character_id, skill_id: skill_id}
    |> CharacterSkill.changeset(attrs)
    |> Repo.insert()
  end

  def create_skill_tree(%World{id: world_id}, attrs) do
    %SkillTree{world_id: world_id}
    |> SkillTree.changeset(attrs)
    |> Repo.insert()
  end

  def get_skill_tree!(id) do
    SkillTree
    |> Repo.get!(id)
    |> Repo.preload([:skills, :perks])
  end

  def create_skill_tree_perk(%SkillTree{id: skill_tree_id}, attrs) do
    %SkillTreePerk{skill_tree_id: skill_tree_id}
    |> SkillTreePerk.changeset(attrs)
    |> Repo.insert()
  end

  def get_skill_tree_perk!(id) do
    SkillTreePerk
    |> Repo.get!(id)
    |> Repo.preload(:skill_tree)
  end

  def update_skill_tree_perk(%SkillTreePerk{} = skill_tree_perk, attrs) do
    skill_tree_perk
    |> SkillTreePerk.changeset(attrs)
    |> Repo.update()
  end

  def delete_skill_tree_perk(%SkillTreePerk{} = skill_tree_perk) do
    Repo.delete(skill_tree_perk)
  end

  def create_skill_level(%Skill{id: skill_id}, attrs) do
    %SkillLevel{skill_id: skill_id}
    |> SkillLevel.changeset(attrs)
    |> Repo.insert()
  end

  def get_skill_level!(id) do
    SkillLevel
    |> Repo.get!(id)
    |> Repo.preload(:skill)
  end

  def update_skill_level(%SkillLevel{} = skill_level, attrs) do
    skill_level
    |> SkillLevel.changeset(attrs)
    |> Repo.update()
  end

  def delete_skill_level(%SkillLevel{} = skill_level) do
    Repo.delete(skill_level)
  end

  def create_hold_commerce_entry(%Hold{id: hold_id}, attrs) do
    %HoldCommerceEntry{hold_id: hold_id}
    |> HoldCommerceEntry.changeset(attrs)
    |> Repo.insert()
  end

  def get_hold_commerce_entry!(id) do
    HoldCommerceEntry
    |> Repo.get!(id)
    |> Repo.preload(:hold)
  end

  def update_hold_commerce_entry(%HoldCommerceEntry{} = hold_commerce_entry, attrs) do
    hold_commerce_entry
    |> HoldCommerceEntry.changeset(attrs)
    |> Repo.update()
  end

  def delete_hold_commerce_entry(%HoldCommerceEntry{} = hold_commerce_entry) do
    Repo.delete(hold_commerce_entry)
  end

  def list_hold_economic_profiles(%World{id: world_id}, search \\ nil) do
    HoldEconomicProfile
    |> join(:inner, [profile], hold in assoc(profile, :hold))
    |> join(:inner, [_profile, hold], province in assoc(hold, :province))
    |> join(:inner, [_profile, _hold, province], continent in assoc(province, :continent))
    |> where([_profile, _hold, _province, continent], continent.world_id == ^world_id)
    |> maybe_search_hold_economic_profiles(search)
    |> order_by([_profile, hold], asc: hold.name)
    |> Repo.all()
    |> Repo.preload(hold: :province)
  end

  def get_hold_economic_profile!(id) do
    HoldEconomicProfile
    |> Repo.get!(id)
    |> Repo.preload(hold: :province)
  end

  def change_hold_economic_profile(%HoldEconomicProfile{} = profile, attrs \\ %{}) do
    HoldEconomicProfile.changeset(profile, attrs)
  end

  def create_hold_economic_profile(%Hold{id: hold_id}, attrs) do
    %HoldEconomicProfile{hold_id: hold_id}
    |> HoldEconomicProfile.changeset(attrs)
    |> Repo.insert()
  end

  def update_hold_economic_profile(%HoldEconomicProfile{} = profile, attrs) do
    profile
    |> HoldEconomicProfile.changeset(attrs)
    |> Repo.update()
  end

  def delete_hold_economic_profile(%HoldEconomicProfile{} = profile) do
    Repo.delete(profile)
  end

  def list_commodity_balances(%World{id: world_id}, search \\ nil) do
    CommodityBalance
    |> join(:inner, [balance], hold in assoc(balance, :hold))
    |> join(:inner, [_balance, hold], province in assoc(hold, :province))
    |> join(:inner, [_balance, _hold, province], continent in assoc(province, :continent))
    |> where([_balance, _hold, _province, continent], continent.world_id == ^world_id)
    |> maybe_search_commodity_balances(search)
    |> order_by([balance, hold], asc: hold.name, asc: balance.commodity)
    |> Repo.all()
    |> Repo.preload(hold: :province)
  end

  def get_commodity_balance!(id) do
    CommodityBalance
    |> Repo.get!(id)
    |> Repo.preload(hold: :province)
  end

  def change_commodity_balance(%CommodityBalance{} = balance, attrs \\ %{}) do
    CommodityBalance.changeset(balance, attrs)
  end

  def create_commodity_balance(%Hold{id: hold_id}, attrs) do
    %CommodityBalance{hold_id: hold_id}
    |> CommodityBalance.changeset(attrs)
    |> Repo.insert()
  end

  def update_commodity_balance(%CommodityBalance{} = balance, attrs) do
    balance
    |> CommodityBalance.changeset(attrs)
    |> Repo.update()
  end

  def delete_commodity_balance(%CommodityBalance{} = balance) do
    Repo.delete(balance)
  end

  def create_inventory_category(%Character{id: character_id}, attrs) do
    %CharacterInventoryCategory{character_id: character_id}
    |> CharacterInventoryCategory.changeset(attrs)
    |> Repo.insert()
  end

  def get_inventory_category!(id) do
    CharacterInventoryCategory
    |> Repo.get!(id)
    |> Repo.preload(:character)
  end

  def delete_inventory_category(%CharacterInventoryCategory{} = inventory_category) do
    Repo.delete(inventory_category)
  end

  def create_inventory_item(%Character{id: character_id}, attrs, refs \\ %{}) do
    %CharacterInventoryItem{character_id: character_id}
    |> CharacterInventoryItem.changeset(attrs)
    |> put_optional_ref(:inventory_category_id, refs[:inventory_category])
    |> put_optional_ref(:item_id, refs[:item])
    |> Repo.insert()
  end

  def get_inventory_item!(id) do
    CharacterInventoryItem
    |> Repo.get!(id)
    |> Repo.preload([:character, :inventory_category, :item])
  end

  def delete_inventory_item(%CharacterInventoryItem{} = inventory_item) do
    Repo.delete(inventory_item)
  end

  def create_spellbook_entry(%Character{id: character_id}, %Spell{id: spell_id}, attrs) do
    %CharacterSpellbookEntry{character_id: character_id, spell_id: spell_id}
    |> CharacterSpellbookEntry.changeset(attrs)
    |> Repo.insert()
  end

  def create_political_office(%World{id: world_id}, attrs, refs \\ %{}) do
    %PoliticalOffice{world_id: world_id}
    |> PoliticalOffice.changeset(attrs)
    |> put_optional_ref(:continent_id, refs[:continent])
    |> put_optional_ref(:province_id, refs[:province])
    |> put_optional_ref(:hold_id, refs[:hold])
    |> put_optional_ref(:character_id, refs[:character])
    |> put_optional_ref(:designated_successor_id, refs[:designated_successor])
    |> Repo.insert()
  end

  def get_political_office!(id) do
    PoliticalOffice
    |> Repo.get!(id)
    |> Repo.preload([:character, :designated_successor, :continent, :province, :hold])
  end

  def update_political_office(%PoliticalOffice{} = political_office, attrs, refs \\ %{}) do
    political_office
    |> PoliticalOffice.changeset(attrs)
    |> put_ref_from_refs(refs, :character, :character_id)
    |> put_ref_from_refs(refs, :designated_successor, :designated_successor_id)
    |> Repo.update()
  end

  def delete_political_office(%PoliticalOffice{} = political_office) do
    Repo.delete(political_office)
  end

  def list_assemblies(%World{id: world_id}) do
    Assembly
    |> where([assembly], assembly.world_id == ^world_id)
    |> order_by([assembly], asc: assembly.scope, asc: assembly.name)
    |> Repo.all()
    |> Repo.preload([:continent, :province, :hold, :location])
  end

  def get_assembly!(id) do
    Assembly
    |> Repo.get!(id)
    |> Repo.preload([:world, :continent, :province, :hold, :location])
  end

  def change_assembly(%Assembly{} = assembly, attrs \\ %{}) do
    Assembly.changeset(assembly, attrs)
  end

  def create_assembly(%World{id: world_id}, attrs, refs) do
    refs = assembly_ref_ids(refs, world_id)

    %Assembly{}
    |> Assembly.changeset(attrs, refs)
    |> validate_assembly_refs(world_id)
    |> Repo.insert()
  end

  def update_assembly(%Assembly{world_id: world_id} = assembly, attrs, refs) do
    refs = assembly_ref_ids(refs, world_id)

    assembly
    |> Assembly.changeset(attrs, refs)
    |> validate_assembly_refs(world_id)
    |> Repo.update()
  end

  def delete_assembly(%Assembly{} = assembly) do
    Repo.delete(assembly)
  end

  def list_calendars(%Continent{id: continent_id}) do
    Calendar
    |> where([calendar], calendar.continent_id == ^continent_id)
    |> order_by([calendar], asc: calendar.name)
    |> Repo.all()
    |> Repo.preload(:months)
  end

  def get_calendar!(id) do
    Calendar
    |> Repo.get!(id)
    |> Repo.preload(:months)
  end

  def create_calendar(%Continent{id: continent_id}, attrs) do
    %Calendar{continent_id: continent_id}
    |> Calendar.changeset(attrs)
    |> Repo.insert()
  end

  def update_calendar(%Calendar{} = calendar, attrs) do
    calendar
    |> Calendar.changeset(attrs)
    |> Repo.update()
  end

  def create_calendar_month(%Calendar{id: calendar_id}, attrs) do
    %CalendarMonth{calendar_id: calendar_id}
    |> CalendarMonth.changeset(attrs)
    |> Repo.insert()
  end

  def update_calendar_month(%CalendarMonth{} = calendar_month, attrs) do
    calendar_month
    |> CalendarMonth.changeset(attrs)
    |> Repo.update()
  end

  def get_calendar_month!(id) do
    Repo.get!(CalendarMonth, id)
  end

  @doc "Deletes a month from a calendar."
  def delete_calendar_month(%CalendarMonth{} = calendar_month) do
    Repo.delete(calendar_month)
  end

  @doc "Deletes a calendar and its months."
  def delete_calendar(%Calendar{} = calendar) do
    Repo.delete(calendar)
  end

  def list_water_bodies(%World{id: world_id}, search \\ nil) do
    WaterBody
    |> where([water], water.world_id == ^world_id)
    |> maybe_search_water_bodies(search)
    |> order_by([water], asc: water.name)
    |> Repo.all()
    |> Repo.preload(:parent_water_body)
  end

  def get_water_body!(id) do
    WaterBody
    |> Repo.get!(id)
    |> Repo.preload([:parent_water_body, province_links: :province])
  end

  def change_water_body(%WaterBody{} = water_body, attrs \\ %{}) do
    WaterBody.changeset(water_body, attrs)
  end

  def create_water_body(%World{id: world_id}, attrs, refs \\ %{}) do
    %WaterBody{world_id: world_id}
    |> WaterBody.changeset(
      attrs,
      economic_ref_ids(refs, parent_water_body: :parent_water_body_id)
    )
    |> validate_water_body_parent(world_id)
    |> Repo.insert()
  end

  def update_water_body(%WaterBody{world_id: world_id} = water_body, attrs, refs \\ %{}) do
    Repo.transaction(fn ->
      lock_world_waters(world_id)

      changeset =
        water_body
        |> WaterBody.changeset(
          attrs,
          economic_ref_ids(refs, parent_water_body: :parent_water_body_id)
        )
        |> validate_water_body_parent(world_id)
        |> validate_water_body_cycle()

      changeset
      |> Repo.update()
      |> unwrap_transaction!()
      |> refresh_world_water_paths!()
    end)
  end

  def delete_water_body(%WaterBody{} = water_body) do
    water_body
    |> WaterBody.delete_changeset()
    |> Repo.delete()
  end

  def list_water_body_connections(%World{id: world_id}) do
    WaterBodyConnection
    |> join(:inner, [connection], origin in assoc(connection, :origin_water_body))
    |> where([_connection, origin], origin.world_id == ^world_id)
    |> order_by([connection], asc: connection.connection_type)
    |> Repo.all()
    |> Repo.preload([:origin_water_body, :destination_water_body])
  end

  def get_water_body_connection!(id) do
    WaterBodyConnection
    |> Repo.get!(id)
    |> Repo.preload([:origin_water_body, :destination_water_body])
  end

  def change_water_body_connection(%WaterBodyConnection{} = connection, attrs \\ %{}) do
    WaterBodyConnection.changeset(connection, attrs)
  end

  def create_water_body_connection(%World{id: world_id}, attrs, refs) do
    Repo.transaction(fn ->
      lock_world_water_connections(world_id)

      %WaterBodyConnection{}
      |> WaterBodyConnection.changeset(attrs, water_connection_ref_ids(refs))
      |> validate_water_connection_refs(world_id)
      |> Repo.insert()
      |> unwrap_transaction!()
      |> refresh_world_water_paths!()
    end)
  end

  def update_water_body_connection(%WaterBodyConnection{} = connection, attrs, refs \\ %{}) do
    connection = Repo.preload(connection, :origin_water_body)

    Repo.transaction(fn ->
      world_id = connection.origin_water_body.world_id
      lock_world_water_connections(world_id)

      connection
      |> WaterBodyConnection.changeset(attrs, water_connection_ref_ids(refs))
      |> validate_water_connection_refs(world_id)
      |> Repo.update()
      |> unwrap_transaction!()
      |> refresh_world_water_paths!()
    end)
  end

  def delete_water_body_connection(%WaterBodyConnection{} = connection) do
    connection = Repo.preload(connection, :origin_water_body)

    Repo.transaction(fn ->
      world_id = connection.origin_water_body.world_id
      lock_world_water_connections(world_id)

      connection
      |> Repo.delete()
      |> unwrap_transaction!()

      refresh_world_water_paths!(%World{id: world_id})
      connection
    end)
  end

  def list_province_water_bodies(%World{id: world_id}) do
    ProvinceWaterBody
    |> join(:inner, [link], province in assoc(link, :province))
    |> join(:inner, [_link, province], continent in assoc(province, :continent))
    |> where([_link, _province, continent], continent.world_id == ^world_id)
    |> order_by([link], asc: link.relationship)
    |> Repo.all()
    |> Repo.preload([:province, :water_body])
  end

  def create_province_water_body(%Province{} = province, %WaterBody{} = water_body, attrs) do
    %ProvinceWaterBody{}
    |> ProvinceWaterBody.changeset(attrs, %{
      province_id: province.id,
      water_body_id: water_body.id
    })
    |> validate_world_ref(
      :water_body_id,
      water_body.id,
      &province_and_water_share_world?(province, &1)
    )
    |> Repo.insert()
  end

  def update_province_water_body(
        %ProvinceWaterBody{} = link,
        %Province{} = province,
        %WaterBody{} = water_body,
        attrs
      ) do
    changeset =
      link
      |> ProvinceWaterBody.changeset(attrs, %{
        province_id: province.id,
        water_body_id: water_body.id
      })
      |> validate_world_ref(
        :water_body_id,
        water_body.id,
        &province_and_water_share_world?(province, &1)
      )

    Repo.transaction(fn ->
      lock_province_water_link(link.id)

      if province_water_link_in_use?(link) and
           (link.province_id != province.id or link.water_body_id != water_body.id) do
        changeset
        |> Ecto.Changeset.add_error(:water_body_id, "is used by waterfront locations")
        |> Repo.rollback()
      else
        changeset
        |> Repo.update()
        |> unwrap_transaction!()
      end
    end)
  end

  def delete_province_water_body(%ProvinceWaterBody{} = link) do
    Repo.transaction(fn ->
      lock_province_water_link(link.id)

      if province_water_link_in_use?(link) do
        Repo.rollback(:province_water_has_locations)
      else
        link
        |> Repo.delete()
        |> unwrap_transaction!()
      end
    end)
  end

  def set_location_water_body(%World{id: world_id}, %Location{} = location, water_body) do
    cond do
      not location_in_world?(location.id, world_id) ->
        {:error, :reference_outside_world}

      water_body && not water_body_in_world?(water_body.id, world_id) ->
        {:error, :reference_outside_world}

      true ->
        Repo.transaction(fn ->
          if water_body &&
               not lock_location_province_water_link(location.id, water_body.id) do
            Repo.rollback(:water_not_linked_to_location_province)
          end

          updated_location =
            location
            |> Ecto.Changeset.change(water_body_id: water_body && water_body.id)
            |> Ecto.Changeset.foreign_key_constraint(:water_body_id)
            |> Repo.update()
            |> unwrap_transaction!()

          refresh_world_water_paths!(%World{id: world_id})
          updated_location
        end)
    end
  end

  def list_trade_route_stops(%TradeRoute{id: route_id}) do
    TradeRouteStop
    |> where([stop], stop.trade_route_id == ^route_id)
    |> order_by([stop], asc: stop.position)
    |> Repo.all()
    |> Repo.preload(location: :hold)
  end

  def get_trade_route_stop!(id) do
    TradeRouteStop
    |> Repo.get!(id)
    |> Repo.preload([:trade_route, location: :hold])
  end

  def change_trade_route_stop(%TradeRouteStop{} = stop, attrs \\ %{}) do
    TradeRouteStop.changeset(stop, attrs)
  end

  def create_trade_route_stop(
        %TradeRoute{id: route_id, world_id: world_id},
        %Location{} = location,
        attrs
      ) do
    Repo.transaction(fn ->
      lock_trade_route(route_id)

      %TradeRouteStop{trade_route_id: route_id}
      |> TradeRouteStop.changeset(attrs, %{location_id: location.id})
      |> validate_world_ref(:location_id, location.id, &location_in_world?(&1, world_id))
      |> validate_trade_route_stop_position(route_id, nil)
      |> Repo.insert()
      |> unwrap_transaction!()
    end)
  end

  def update_trade_route_stop(%TradeRouteStop{} = stop, attrs, refs \\ %{}) do
    stop = Repo.preload(stop, :trade_route)

    Repo.transaction(fn ->
      lock_trade_route(stop.trade_route_id)

      updated_stop =
        stop
        |> TradeRouteStop.changeset(attrs, economic_ref_ids(refs, location: :location_id))
        |> validate_route_stop_location(stop.trade_route.world_id)
        |> validate_trade_route_stop_position(stop.trade_route_id, stop)
        |> Repo.update()
        |> unwrap_transaction!()

      refresh_route_water_paths!(stop.trade_route_id)
      validate_route_topology!(stop.trade_route_id, updated_stop)
      updated_stop
    end)
  end

  def delete_trade_route_stop(%TradeRouteStop{} = stop) do
    Repo.transaction(fn ->
      lock_trade_route(stop.trade_route_id)

      stop
      |> validate_trade_route_stop_deletion()
      |> Repo.delete()
      |> unwrap_transaction!()
    end)
  end

  def list_trade_route_legs(%TradeRoute{id: route_id}) do
    TradeRouteLeg
    |> where([leg], leg.trade_route_id == ^route_id)
    |> order_by([leg], asc: leg.position)
    |> Repo.all()
    |> Repo.preload([
      :water_body,
      water_traversals: :water_body,
      origin_stop: [location: :hold],
      destination_stop: [location: :hold]
    ])
  end

  def get_trade_route_leg!(id) do
    TradeRouteLeg
    |> Repo.get!(id)
    |> Repo.preload([
      :trade_route,
      :water_body,
      water_traversals: :water_body,
      origin_stop: [location: :hold],
      destination_stop: [location: :hold]
    ])
  end

  def change_trade_route_leg(%TradeRouteLeg{} = leg, attrs \\ %{}) do
    TradeRouteLeg.changeset(leg, attrs)
  end

  def create_trade_route_leg(%TradeRoute{id: route_id, world_id: world_id}, attrs, refs) do
    Repo.transaction(fn ->
      lock_trade_route(route_id)

      leg =
        %TradeRouteLeg{trade_route_id: route_id}
        |> TradeRouteLeg.changeset(attrs, trade_route_leg_ref_ids(refs))
        |> validate_trade_route_leg_refs(route_id, world_id)
        |> validate_trade_route_leg_position(route_id, nil)
        |> Repo.insert()
        |> unwrap_transaction!()
        |> sync_trade_route_leg_water_path!()

      validate_route_topology!(route_id, leg)
      leg
    end)
  end

  def update_trade_route_leg(%TradeRouteLeg{} = leg, attrs, refs \\ %{}) do
    leg = Repo.preload(leg, :trade_route)

    Repo.transaction(fn ->
      lock_trade_route(leg.trade_route_id)

      updated_leg =
        leg
        |> TradeRouteLeg.changeset(attrs, trade_route_leg_ref_ids(refs))
        |> validate_trade_route_leg_refs(leg.trade_route_id, leg.trade_route.world_id)
        |> validate_trade_route_leg_position(leg.trade_route_id, leg)
        |> Repo.update()
        |> unwrap_transaction!()
        |> sync_trade_route_leg_water_path!()

      validate_route_topology!(leg.trade_route_id, updated_leg)
      updated_leg
    end)
  end

  def delete_trade_route_leg(%TradeRouteLeg{} = leg) do
    Repo.transaction(fn ->
      lock_trade_route(leg.trade_route_id)

      leg
      |> validate_trade_route_leg_deletion()
      |> Repo.delete()
      |> unwrap_transaction!()
    end)
  end

  def list_trade_routes(%World{id: world_id}) do
    TradeRoute
    |> where([route], route.world_id == ^world_id)
    |> order_by([route], asc: route.name)
    |> Repo.all()
    |> Repo.preload([:origin_hold, :destination_hold, :origin_location, :destination_location])
  end

  def get_trade_route!(id) do
    TradeRoute
    |> Repo.get!(id)
    |> Repo.preload([:origin_hold, :destination_hold, :origin_location, :destination_location])
  end

  def change_trade_route(%TradeRoute{} = route, attrs \\ %{}) do
    TradeRoute.changeset(route, attrs)
  end

  def create_trade_route(%World{id: world_id}, attrs, refs) do
    %TradeRoute{world_id: world_id}
    |> TradeRoute.changeset(attrs, economic_ref_ids(refs, route_ref_fields()))
    |> validate_trade_route_refs(world_id)
    |> Repo.insert()
  end

  def update_trade_route(%TradeRoute{world_id: world_id} = route, attrs, refs \\ %{}) do
    Repo.transaction(fn ->
      lock_trade_route(route.id)

      updated_route =
        route
        |> TradeRoute.changeset(attrs, economic_ref_ids(refs, route_ref_fields()))
        |> validate_trade_route_refs(world_id)
        |> Repo.update()
        |> unwrap_transaction!()

      refresh_route_water_paths!(route.id)
      validate_route_topology!(route.id, updated_route)
      updated_route
    end)
  end

  def delete_trade_route(%TradeRoute{} = route), do: Repo.delete(route)

  def list_trade_flows(%World{id: world_id}) do
    TradeFlow
    |> join(:inner, [flow], route in assoc(flow, :trade_route))
    |> where([_flow, route], route.world_id == ^world_id)
    |> order_by([flow], asc: flow.commodity)
    |> Repo.all()
    |> Repo.preload([:currency, trade_route: [:origin_hold, :destination_hold]])
  end

  def get_trade_flow!(id) do
    TradeFlow
    |> Repo.get!(id)
    |> Repo.preload([:currency, trade_route: [:origin_hold, :destination_hold]])
  end

  def change_trade_flow(%TradeFlow{} = flow, attrs \\ %{}), do: TradeFlow.changeset(flow, attrs)

  def create_trade_flow(%TradeRoute{id: route_id, world_id: world_id}, attrs, refs \\ %{}) do
    %TradeFlow{trade_route_id: route_id}
    |> TradeFlow.changeset(attrs, economic_ref_ids(refs, currency: :currency_id))
    |> validate_currency_ref(world_id)
    |> Repo.insert()
  end

  def update_trade_flow(%TradeFlow{} = flow, attrs, refs \\ %{}) do
    flow = Repo.preload(flow, :trade_route)

    flow
    |> TradeFlow.changeset(attrs, economic_ref_ids(refs, currency: :currency_id))
    |> validate_currency_ref(flow.trade_route.world_id)
    |> Repo.update()
  end

  def delete_trade_flow(%TradeFlow{} = flow), do: Repo.delete(flow)

  def list_commercial_ventures(%World{id: world_id}, search \\ nil) do
    CommercialVenture
    |> where([venture], venture.world_id == ^world_id)
    |> maybe_search_commercial_ventures(search)
    |> order_by([venture], asc: venture.name)
    |> Repo.all()
    |> Repo.preload(commercial_venture_preloads())
  end

  def get_commercial_venture!(%World{id: world_id}, id) do
    CommercialVenture
    |> where([venture], venture.world_id == ^world_id and venture.id == ^id)
    |> Repo.one!()
    |> Repo.preload(commercial_venture_preloads())
  end

  def change_commercial_venture(%CommercialVenture{} = venture, attrs \\ %{}) do
    CommercialVenture.changeset(venture, attrs)
  end

  def create_commercial_venture(%World{id: world_id}, attrs, refs \\ %{}) do
    %CommercialVenture{world_id: world_id}
    |> CommercialVenture.changeset(
      attrs,
      economic_ref_ids(refs, home_location: :home_location_id)
    )
    |> validate_commercial_venture_refs(world_id)
    |> Repo.insert()
  end

  def update_commercial_venture(
        %CommercialVenture{world_id: world_id} = venture,
        attrs,
        refs \\ %{}
      ) do
    venture
    |> CommercialVenture.changeset(
      attrs,
      economic_ref_ids(refs, home_location: :home_location_id)
    )
    |> validate_commercial_venture_refs(world_id)
    |> Repo.update()
  end

  def delete_commercial_venture(%CommercialVenture{} = venture) do
    Repo.delete(venture)
  end

  def list_venture_memberships(%CommercialVenture{id: venture_id}) do
    VentureMembership
    |> where([membership], membership.commercial_venture_id == ^venture_id)
    |> order_by([membership], asc: membership.role)
    |> Repo.all()
    |> Repo.preload([:household, :character])
  end

  def list_character_venture_memberships(%Character{id: character_id}) do
    VentureMembership
    |> where([membership], membership.character_id == ^character_id)
    |> order_by([membership], asc: membership.role)
    |> Repo.all()
    |> Repo.preload(:commercial_venture)
  end

  def list_household_venture_memberships(%Household{id: household_id}) do
    VentureMembership
    |> where([membership], membership.household_id == ^household_id)
    |> order_by([membership], asc: membership.role)
    |> Repo.all()
    |> Repo.preload(:commercial_venture)
  end

  def get_venture_membership!(id) do
    VentureMembership
    |> Repo.get!(id)
    |> Repo.preload([:commercial_venture, :household, :character])
  end

  def change_venture_membership(%VentureMembership{} = membership, attrs \\ %{}) do
    VentureMembership.changeset(membership, attrs)
  end

  def create_venture_membership(
        %CommercialVenture{} = venture,
        attrs,
        refs
      ) do
    %VentureMembership{commercial_venture_id: venture.id}
    |> VentureMembership.changeset(attrs, venture_membership_ref_ids(refs))
    |> validate_venture_membership_refs(venture.world_id)
    |> persist_venture_membership(venture.id)
  end

  def update_venture_membership(%VentureMembership{} = membership, attrs, refs \\ %{}) do
    membership = Repo.preload(membership, :commercial_venture)

    membership
    |> VentureMembership.changeset(attrs, venture_membership_ref_ids(refs))
    |> validate_venture_membership_refs(membership.commercial_venture.world_id)
    |> persist_venture_membership(membership.commercial_venture_id, membership.id)
  end

  def delete_venture_membership(%VentureMembership{} = membership) do
    Repo.delete(membership)
  end

  def list_venture_trade_routes(%CommercialVenture{id: venture_id}) do
    VentureTradeRoute
    |> where([link], link.commercial_venture_id == ^venture_id)
    |> order_by([link], asc: link.role)
    |> Repo.all()
    |> Repo.preload(:trade_route)
  end

  def get_venture_trade_route!(id) do
    VentureTradeRoute
    |> Repo.get!(id)
    |> Repo.preload([:commercial_venture, :trade_route])
  end

  def change_venture_trade_route(%VentureTradeRoute{} = link, attrs \\ %{}) do
    VentureTradeRoute.changeset(link, attrs)
  end

  def create_venture_trade_route(
        %CommercialVenture{} = venture,
        %TradeRoute{} = route,
        attrs
      ) do
    %VentureTradeRoute{}
    |> VentureTradeRoute.changeset(attrs, %{
      commercial_venture_id: venture.id,
      trade_route_id: route.id
    })
    |> validate_world_ref(
      :trade_route_id,
      route.id,
      &trade_route_in_world?(&1, venture.world_id)
    )
    |> Repo.insert()
  end

  def update_venture_trade_route(
        %VentureTradeRoute{} = link,
        %TradeRoute{} = route,
        attrs
      ) do
    link = Repo.preload(link, :commercial_venture)

    link
    |> VentureTradeRoute.changeset(attrs, %{trade_route_id: route.id})
    |> validate_world_ref(
      :trade_route_id,
      route.id,
      &trade_route_in_world?(&1, link.commercial_venture.world_id)
    )
    |> Repo.update()
  end

  def delete_venture_trade_route(%VentureTradeRoute{} = link) do
    Repo.delete(link)
  end

  def list_tax_policies(%World{id: world_id}) do
    TaxPolicy
    |> where([policy], policy.world_id == ^world_id)
    |> order_by([policy], asc: policy.name)
    |> Repo.all()
    |> Repo.preload([:continent, :province, :hold, :collecting_office, :currency])
  end

  def get_tax_policy!(id) do
    TaxPolicy
    |> Repo.get!(id)
    |> Repo.preload([
      :continent,
      :province,
      :hold,
      :collecting_office,
      :currency,
      tax_exemptions: [:guild, :trade_route, :continent, :province, :hold],
      revenue_shares: [:political_office]
    ])
  end

  def change_tax_policy(%TaxPolicy{} = policy, attrs \\ %{}),
    do: TaxPolicy.changeset(policy, attrs)

  def create_tax_policy(%World{id: world_id}, attrs, refs) do
    %TaxPolicy{world_id: world_id}
    |> TaxPolicy.changeset(attrs, economic_ref_ids(refs, policy_ref_fields()))
    |> validate_tax_policy_refs(world_id)
    |> Repo.insert()
  end

  def update_tax_policy(%TaxPolicy{world_id: world_id} = policy, attrs, refs \\ %{}) do
    policy
    |> TaxPolicy.changeset(attrs, economic_ref_ids(refs, policy_ref_fields()))
    |> validate_tax_policy_refs(world_id)
    |> Repo.update()
  end

  def delete_tax_policy(%TaxPolicy{} = policy), do: Repo.delete(policy)

  def list_tax_assessments(%World{id: world_id}, search \\ nil) do
    TaxAssessment
    |> join(:inner, [assessment], policy in assoc(assessment, :tax_policy))
    |> where([_assessment, policy], policy.world_id == ^world_id)
    |> maybe_search_tax_assessments(search)
    |> order_by([assessment, policy], asc: policy.name, desc: assessment.assessment_period_label)
    |> Repo.all()
    |> Repo.preload([:currency, tax_policy: [:continent, :province, :hold]])
  end

  def get_tax_assessment!(id) do
    TaxAssessment
    |> Repo.get!(id)
    |> Repo.preload([:currency, tax_policy: [:continent, :province, :hold]])
  end

  def change_tax_assessment(%TaxAssessment{} = assessment, attrs \\ %{}) do
    TaxAssessment.changeset(assessment, attrs)
  end

  def create_tax_assessment(%TaxPolicy{id: policy_id, world_id: world_id}, attrs, refs) do
    %TaxAssessment{tax_policy_id: policy_id}
    |> TaxAssessment.changeset(attrs, economic_ref_ids(refs, currency: :currency_id))
    |> validate_currency_ref(world_id)
    |> Repo.insert()
  end

  def update_tax_assessment(%TaxAssessment{} = assessment, attrs, refs \\ %{}) do
    assessment = Repo.preload(assessment, :tax_policy)

    assessment
    |> TaxAssessment.changeset(attrs, economic_ref_ids(refs, currency: :currency_id))
    |> validate_currency_ref(assessment.tax_policy.world_id)
    |> Repo.update()
  end

  def delete_tax_assessment(%TaxAssessment{} = assessment) do
    Repo.delete(assessment)
  end

  def list_tax_exemptions(%World{id: world_id}) do
    TaxExemption
    |> join(:inner, [exemption], policy in assoc(exemption, :tax_policy))
    |> where([_exemption, policy], policy.world_id == ^world_id)
    |> order_by([exemption], asc: exemption.name)
    |> Repo.all()
    |> Repo.preload([:tax_policy, :guild, :trade_route, :continent, :province, :hold])
  end

  def change_tax_exemption(%TaxExemption{} = exemption, attrs \\ %{}) do
    TaxExemption.changeset(exemption, attrs)
  end

  def create_tax_exemption(%TaxPolicy{id: policy_id, world_id: world_id}, attrs, refs) do
    %TaxExemption{tax_policy_id: policy_id}
    |> TaxExemption.changeset(attrs, economic_ref_ids(refs, exemption_ref_fields()))
    |> validate_tax_exemption_refs(world_id)
    |> Repo.insert()
  end

  def update_tax_exemption(%TaxExemption{} = exemption, attrs, refs \\ %{}) do
    exemption = Repo.preload(exemption, :tax_policy)

    exemption
    |> TaxExemption.changeset(attrs, economic_ref_ids(refs, exemption_ref_fields()))
    |> validate_tax_exemption_refs(exemption.tax_policy.world_id)
    |> Repo.update()
  end

  def delete_tax_exemption(%TaxExemption{} = exemption), do: Repo.delete(exemption)

  def list_tax_revenue_shares(%TaxPolicy{id: policy_id}) do
    TaxRevenueShare
    |> where([share], share.tax_policy_id == ^policy_id)
    |> order_by([share], asc: share.percentage)
    |> Repo.all()
    |> Repo.preload(:political_office)
  end

  def change_tax_revenue_share(%TaxRevenueShare{} = share, attrs \\ %{}) do
    TaxRevenueShare.changeset(share, attrs)
  end

  def create_tax_revenue_share(%TaxPolicy{} = policy, attrs, %{political_office: office}) do
    persist_tax_revenue_share(policy, %TaxRevenueShare{}, attrs, office)
  end

  def update_tax_revenue_share(%TaxRevenueShare{} = share, attrs, %{political_office: office}) do
    share = Repo.preload(share, :tax_policy)
    persist_tax_revenue_share(share.tax_policy, share, attrs, office)
  end

  def delete_tax_revenue_share(%TaxRevenueShare{} = share), do: Repo.delete(share)

  defp skill_tree_attrs(attrs) do
    %{
      name: attrs[:name] || attrs["name"],
      category: attrs[:category] || attrs["category"],
      description: attrs[:description] || attrs["description"]
    }
  end

  defp put_optional_ref(changeset, _field, nil) do
    changeset
  end

  defp put_optional_ref(changeset, field, %{id: id}) do
    Ecto.Changeset.put_change(changeset, field, id)
  end

  defp put_ref_from_refs(changeset, refs, key, field) do
    refs = Map.new(refs)

    if Map.has_key?(refs, key) do
      put_ref(changeset, field, Map.get(refs, key))
    else
      changeset
    end
  end

  defp put_document_refs(changeset, refs) do
    changeset
    |> put_ref(:author_character_id, refs[:author_character])
    |> put_ref(:location_id, refs[:location])
    |> put_ref(:guild_id, refs[:guild])
    |> put_ref(:god_id, refs[:god])
    |> put_ref(:race_id, refs[:race])
    |> put_ref(:civilization_id, refs[:civilization])
  end

  defp put_lore_connection_refs(changeset, refs) do
    changeset
    |> put_lore_connection_endpoint(:source, refs[:source])
    |> put_lore_connection_endpoint(:target, refs[:target])
  end

  defp put_lore_connection_endpoint(changeset, _side, nil) do
    changeset
  end

  defp put_lore_connection_endpoint(changeset, _side, {_kind, nil}) do
    changeset
  end

  defp put_lore_connection_endpoint(changeset, side, {kind, %{id: id}})
       when kind in [
              :character,
              :guild,
              :god,
              :race,
              :civilization,
              :location,
              :hold,
              :province,
              :continent
            ] do
    Ecto.Changeset.put_change(changeset, lore_connection_field(side, kind), id)
  end

  defp clear_lore_connection_refs(changeset) do
    Enum.reduce(lore_connection_ref_fields(), changeset, fn field, changeset ->
      Ecto.Changeset.put_change(changeset, field, nil)
    end)
  end

  defp lore_connection_field(side, kind) do
    :"#{side}_#{kind}_id"
  end

  defp lore_connection_ref_fields do
    for side <- [:source, :target],
        kind <- [
          :character,
          :guild,
          :god,
          :race,
          :civilization,
          :location,
          :hold,
          :province,
          :continent
        ] do
      lore_connection_field(side, kind)
    end
  end

  defp lore_connection_preloads do
    [
      :source_character,
      :source_guild,
      :source_god,
      :source_race,
      :source_civilization,
      :source_location,
      :source_hold,
      :source_province,
      :source_continent,
      :target_character,
      :target_guild,
      :target_god,
      :target_race,
      :target_civilization,
      :target_location,
      :target_hold,
      :target_province,
      :target_continent
    ]
  end

  defp put_ref(changeset, field, nil) do
    Ecto.Changeset.put_change(changeset, field, nil)
  end

  defp put_ref(changeset, field, %{id: id}) do
    Ecto.Changeset.put_change(changeset, field, id)
  end

  def list_races(%World{id: world_id}) do
    Race
    |> where([race], race.world_id == ^world_id)
    |> order_by([race], asc: race.name)
    |> Repo.all()
  end

  def get_race!(id) do
    Repo.get!(Race, id)
  end

  def change_race(%Race{} = race, attrs \\ %{}) do
    Race.changeset(race, attrs)
  end

  def create_race(%World{id: world_id}, attrs, refs \\ %{}) do
    Repo.transaction(fn ->
      race =
        %Race{world_id: world_id}
        |> Race.changeset(attrs)
        |> Repo.insert()
        |> unwrap_transaction!()

      if refs[:civilization] do
        refs[:civilization]
        |> create_civilization_race(race, %{})
        |> unwrap_transaction!()
      end

      attrs
      |> race_traits_from_attrs()
      |> Enum.each(fn trait_attrs ->
        race
        |> create_race_trait(trait_attrs)
        |> unwrap_transaction!()
      end)

      race
    end)
  end

  def create_race_trait(%Race{id: race_id}, attrs) do
    %RaceTrait{race_id: race_id}
    |> RaceTrait.changeset(attrs)
    |> Repo.insert()
  end

  defp race_traits_from_attrs(attrs) do
    case attr_value(attrs, "traits") do
      nil ->
        legacy_race_traits_from_attrs(attrs)

      traits ->
        traits
        |> normalize_trait_params()
        |> Enum.map(&trait_attrs_from_param/1)
        |> Enum.reject(&is_nil/1)
    end
  end

  defp legacy_race_traits_from_attrs(attrs) do
    power_traits = legacy_trait_attrs_from_names(:power, attr_value(attrs, "power_names"))
    perk_traits = legacy_trait_attrs_from_names(:perk, attr_value(attrs, "perk_names"))

    power_traits ++ perk_traits
  end

  defp legacy_trait_attrs_from_names(category, names) do
    names
    |> List.wrap()
    |> Enum.flat_map(&String.split(&1, "\n"))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn name -> %{category: category, name: name} end)
  end

  defp normalize_trait_params(traits) when is_list(traits) do
    traits
  end

  defp normalize_trait_params(traits) when is_map(traits) do
    traits
    |> Enum.sort_by(fn {index, _attrs} -> sortable_index(index) end)
    |> Enum.map(fn {_index, attrs} -> attrs end)
  end

  defp normalize_trait_params(_traits) do
    []
  end

  defp trait_attrs_from_param(attrs) when is_map(attrs) do
    category = attr_value(attrs, "category")
    name = attr_value(attrs, "name")

    if category in [nil, ""] || name in [nil, ""] do
      nil
    else
      %{
        category: category,
        name: name,
        description: attr_value(attrs, "description")
      }
    end
  end

  defp trait_attrs_from_param(_attrs) do
    nil
  end

  defp attr_value(attrs, "traits") do
    Map.get(attrs, "traits", Map.get(attrs, :traits))
  end

  defp attr_value(attrs, "power_names") do
    attrs
    |> Map.get("power_names", Map.get(attrs, :power_names) || Map.get(attrs, "power_name"))
    |> case do
      nil ->
        Map.get(attrs, :power_name)

      value ->
        value
    end
    |> normalize_attr_value()
  end

  defp attr_value(attrs, "perk_names") do
    attrs
    |> Map.get("perk_names", Map.get(attrs, :perk_names))
    |> normalize_attr_value()
  end

  defp attr_value(attrs, "category") do
    attrs
    |> Map.get("category", Map.get(attrs, :category))
    |> normalize_attr_value()
  end

  defp attr_value(attrs, "name") do
    attrs
    |> Map.get("name", Map.get(attrs, :name))
    |> normalize_attr_value()
  end

  defp attr_value(attrs, "description") do
    attrs
    |> Map.get("description", Map.get(attrs, :description))
    |> normalize_attr_value()
  end

  defp normalize_attr_value(value) when is_binary(value) do
    value = String.trim(value)

    if value == "" do
      nil
    else
      value
    end
  end

  defp normalize_attr_value(value) do
    value
  end

  defp sortable_index(index) do
    index = to_string(index)

    case Integer.parse(index) do
      {number, ""} -> {0, number}
      _other -> {1, index}
    end
  end

  @doc "Deletes a race from a world."
  def delete_race(%Race{} = race) do
    Repo.delete(race)
  end

  def get_location_type!(id) do
    Repo.get!(LocationType, id)
  end

  @doc "Marks a location inside a hold as that hold's capital."
  def set_hold_capital(
        %Hold{id: hold_id, capital_location_id: capital_location_id} = hold,
        %Location{hold_id: location_hold_id} = location
      )
      when hold_id == location_hold_id do
    cond do
      is_nil(capital_location_id) ->
        hold
        |> Ecto.Changeset.change(capital_location_id: location.id)
        |> Repo.update()

      capital_location_id == location.id ->
        {:ok, hold}

      true ->
        {:error, :capital_already_set}
    end
  end

  def set_hold_capital(%Hold{}, %Location{}) do
    {:error, :capital_location_outside_hold}
  end

  def list_location_types(%World{id: world_id}) do
    LocationType
    |> where([location_type], location_type.world_id == ^world_id)
    |> order_by([location_type], asc: location_type.name)
    |> Repo.all()
  end

  def change_location_type(%LocationType{} = location_type, attrs \\ %{}) do
    LocationType.changeset(location_type, attrs)
  end

  def create_location_type(%World{id: world_id}, attrs) do
    %LocationType{world_id: world_id}
    |> LocationType.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Creates a child location type under an existing type in the same world."
  def create_location_type(%LocationType{world_id: world_id, id: parent_id}, attrs) do
    %LocationType{world_id: world_id, parent_id: parent_id}
    |> LocationType.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Deletes a location type, its child types, and locations using those types."
  def delete_location_type(%LocationType{} = location_type) do
    location_type_ids = location_type_ids_with_descendants(location_type)

    location_ids =
      Location
      |> where([location], location.location_type_id in ^location_type_ids)
      |> select([location], location.id)
      |> Repo.all()

    Repo.transaction(fn ->
      lock_location_types(location_type_ids)
      lock_locations(location_ids)

      cond do
        landholdings_for_location_ids?(location_ids) ->
          Repo.rollback(:geography_has_landholdings)

        trade_route_stops_for_location_ids?(location_ids) ->
          Repo.rollback(:geography_has_trade_route_stops)

        true ->
          clear_capitals_for_locations(location_ids)

          Location
          |> where([location], location.location_type_id in ^location_type_ids)
          |> Repo.delete_all()

          LocationType
          |> where([location_type], location_type.id in ^location_type_ids)
          |> Repo.delete_all()

          location_type
      end
    end)
  end

  def list_locations(%Hold{id: hold_id}) do
    Location
    |> where([location], location.hold_id == ^hold_id)
    |> where([location], is_nil(location.parent_location_id))
    |> order_by([location], asc: location.name)
    |> Repo.all()
  end

  def get_location!(id) do
    Repo.get!(Location, id)
  end

  def change_location(%Location{} = location, attrs \\ %{}) do
    Location.changeset(location, attrs)
  end

  def create_location(
        %Hold{id: hold_id} = hold,
        %LocationType{id: location_type_id} = location_type,
        attrs
      ) do
    with :ok <- validate_location_type_world(hold, location_type) do
      %Location{hold_id: hold_id, location_type_id: location_type_id}
      |> Location.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc "Creates a location and optionally marks it as the hold capital in one transaction."
  def create_location_in_hold(%Hold{} = hold, %LocationType{} = location_type, attrs, opts \\ []) do
    parent_location = Keyword.get(opts, :parent_location)
    capital? = Keyword.get(opts, :capital, false)

    Repo.transaction(fn ->
      location =
        hold
        |> create_location_for_parent(location_type, attrs, parent_location)
        |> unwrap_transaction!()

      if capital? do
        hold
        |> Repo.reload()
        |> set_hold_capital(location)
        |> unwrap_transaction!()
      end

      location
    end)
  end

  @doc "Updates a location's editable fields and synchronizes its capital status."
  def update_location_in_hold(
        %Location{} = location,
        %LocationType{} = location_type,
        attrs,
        opts \\ []
      ) do
    capital? = Keyword.get(opts, :capital, false)
    hold = Repo.get!(Hold, location.hold_id)

    with :ok <- validate_location_type_world(hold, location_type) do
      Repo.transaction(fn ->
        location =
          location
          |> Location.changeset(attrs)
          |> Ecto.Changeset.put_change(:location_type_id, location_type.id)
          |> Repo.update()
          |> unwrap_transaction!()

        hold
        |> Repo.reload()
        |> sync_location_capital(location, capital?)
        |> unwrap_transaction!()

        location
      end)
    end
  end

  @doc "Deletes a location and nested child locations."
  def delete_location(%Location{} = location) do
    location_ids = location_ids_with_descendants(location)

    Repo.transaction(fn ->
      lock_locations(location_ids)

      cond do
        landholdings_for_location_ids?(location_ids) ->
          Repo.rollback(:geography_has_landholdings)

        trade_route_stops_for_location_ids?(location_ids) ->
          Repo.rollback(:geography_has_trade_route_stops)

        true ->
          clear_capitals_for_locations(location_ids)

          Location
          |> where([location], location.id in ^location_ids)
          |> Repo.delete_all()

          location
      end
    end)
  end

  @doc "Creates a nested location inside an existing location while keeping it in the same hold."
  def create_child_location(
        %Location{hold_id: hold_id, id: parent_location_id},
        %LocationType{id: location_type_id} = location_type,
        attrs
      ) do
    hold = Repo.get!(Hold, hold_id)

    with :ok <- validate_location_type_world(hold, location_type) do
      %Location{
        hold_id: hold_id,
        parent_location_id: parent_location_id,
        location_type_id: location_type_id
      }
      |> Location.changeset(attrs)
      |> Repo.insert()
    end
  end

  defp create_location_for_parent(hold, location_type, attrs, nil) do
    create_location(hold, location_type, attrs)
  end

  defp create_location_for_parent(
         %Hold{id: hold_id},
         location_type,
         attrs,
         %Location{hold_id: parent_hold_id} = parent_location
       )
       when hold_id == parent_hold_id do
    create_child_location(parent_location, location_type, attrs)
  end

  defp create_location_for_parent(%Hold{}, _location_type, _attrs, %Location{}) do
    {:error, :parent_location_outside_hold}
  end

  defp sync_location_capital(%Hold{} = hold, %Location{} = location, true) do
    set_hold_capital(hold, location)
  end

  defp sync_location_capital(
         %Hold{capital_location_id: location_id},
         %Location{id: location_id},
         false
       ) do
    clear_capitals_for_locations([location_id])
    {:ok, :capital_cleared}
  end

  defp sync_location_capital(%Hold{}, %Location{}, false) do
    {:ok, :capital_unchanged}
  end

  defp sync_province_capital_hold(
         %Hold{id: hold_id},
         %Hold{province_id: province_id},
         true
       ) do
    Province
    |> where([province], province.capital_hold_id == ^hold_id and province.id != ^province_id)
    |> Repo.update_all(set: [capital_hold_id: nil])

    Province
    |> where([province], province.id == ^province_id)
    |> Repo.update_all(set: [capital_hold_id: hold_id])

    :ok
  end

  defp sync_province_capital_hold(%Hold{id: hold_id}, %Hold{}, false) do
    Province
    |> where([province], province.capital_hold_id == ^hold_id)
    |> Repo.update_all(set: [capital_hold_id: nil])

    :ok
  end

  defp maybe_put_capital_location(changeset, :unchanged) do
    changeset
  end

  defp maybe_put_capital_location(changeset, nil) do
    Ecto.Changeset.put_change(changeset, :capital_location_id, nil)
  end

  defp maybe_put_capital_location(changeset, %Location{id: location_id}) do
    Ecto.Changeset.put_change(changeset, :capital_location_id, location_id)
  end

  defp validate_hold_capital_location(_hold, :unchanged) do
    :ok
  end

  defp validate_hold_capital_location(_hold, nil) do
    :ok
  end

  defp validate_hold_capital_location(%Hold{id: hold_id}, %Location{hold_id: hold_id}) do
    :ok
  end

  defp validate_hold_capital_location(%Hold{}, %Location{}) do
    {:error, :capital_location_outside_hold}
  end

  defp validate_location_type_world(%Hold{} = hold, %LocationType{
         world_id: location_type_world_id
       }) do
    case hold_world_id(hold) do
      ^location_type_world_id ->
        :ok

      _other_world_id ->
        {:error, :location_type_outside_world}
    end
  end

  defp hold_world_id(%Hold{id: hold_id}) do
    Hold
    |> join(:inner, [hold], province in Province, on: province.id == hold.province_id)
    |> join(:inner, [_hold, province], continent in Continent,
      on: continent.id == province.continent_id
    )
    |> where([hold, _province, _continent], hold.id == ^hold_id)
    |> select([_hold, _province, continent], continent.world_id)
    |> Repo.one()
  end

  defp continent_ids_for_world(world_id) do
    Continent
    |> where([continent], continent.world_id == ^world_id)
    |> select([continent], continent.id)
    |> Repo.all()
  end

  defp hold_counts_by_world([]) do
    %{}
  end

  defp hold_counts_by_world(world_ids) do
    Continent
    |> join(:inner, [continent], province in Province, on: province.continent_id == continent.id)
    |> join(:inner, [_continent, province], hold in Hold, on: hold.province_id == province.id)
    |> where([continent, _province, _hold], continent.world_id in ^world_ids)
    |> group_by([continent, _province, _hold], continent.world_id)
    |> select([continent, _province, hold], {continent.world_id, count(hold.id)})
    |> Repo.all()
    |> Map.new()
  end

  defp location_type_counts_by_world([]) do
    %{}
  end

  defp location_type_counts_by_world(world_ids) do
    LocationType
    |> where([location_type], location_type.world_id in ^world_ids)
    |> group_by([location_type], location_type.world_id)
    |> select([location_type], {location_type.world_id, count(location_type.id)})
    |> Repo.all()
    |> Map.new()
  end

  defp location_counts_by_world([]) do
    %{}
  end

  defp location_counts_by_world(world_ids) do
    Continent
    |> join(:inner, [continent], province in Province, on: province.continent_id == continent.id)
    |> join(:inner, [_continent, province], hold in Hold, on: hold.province_id == province.id)
    |> join(:inner, [_continent, _province, hold], location in Location,
      on: location.hold_id == hold.id
    )
    |> where([continent, _province, _hold, _location], continent.world_id in ^world_ids)
    |> group_by([continent, _province, _hold, _location], continent.world_id)
    |> select([continent, _province, _hold, location], {continent.world_id, count(location.id)})
    |> Repo.all()
    |> Map.new()
  end

  defp merge_count(counts, key, values_by_world) do
    Map.new(counts, fn {world_id, values} ->
      {world_id, Map.put(values, key, Map.get(values_by_world, world_id, 0))}
    end)
  end

  defp province_ids_for_continents([]) do
    []
  end

  defp province_ids_for_continents(continent_ids) do
    Province
    |> where([province], province.continent_id in ^continent_ids)
    |> select([province], province.id)
    |> Repo.all()
  end

  defp hold_ids_for_provinces([]) do
    []
  end

  defp hold_ids_for_provinces(province_ids) do
    Hold
    |> where([hold], hold.province_id in ^province_ids)
    |> select([hold], hold.id)
    |> Repo.all()
  end

  defp delete_tax_assessments_for_world(world_id) do
    policy_ids =
      TaxPolicy
      |> where([policy], policy.world_id == ^world_id)
      |> select([policy], policy.id)

    TaxAssessment
    |> where([assessment], assessment.tax_policy_id in subquery(policy_ids))
    |> Repo.delete_all()

    :ok
  end

  defp delete_commercial_venture_graph_for_world(world_id) do
    venture_ids =
      CommercialVenture
      |> where([venture], venture.world_id == ^world_id)
      |> select([venture], venture.id)

    VentureTradeRoute
    |> where([link], link.commercial_venture_id in subquery(venture_ids))
    |> Repo.delete_all()

    VentureMembership
    |> where([membership], membership.commercial_venture_id in subquery(venture_ids))
    |> Repo.delete_all()

    CommercialVenture
    |> where([venture], venture.id in subquery(venture_ids))
    |> Repo.delete_all()

    :ok
  end

  defp delete_waterway_graph_for_world(world_id) do
    route_ids =
      TradeRoute
      |> where([route], route.world_id == ^world_id)
      |> select([route], route.id)

    water_body_ids =
      WaterBody
      |> where([water], water.world_id == ^world_id)
      |> select([water], water.id)

    TradeRouteLeg
    |> where([leg], leg.trade_route_id in subquery(route_ids))
    |> Repo.delete_all()

    TradeRouteStop
    |> where([stop], stop.trade_route_id in subquery(route_ids))
    |> Repo.delete_all()

    Location
    |> where([location], location.water_body_id in subquery(water_body_ids))
    |> Repo.update_all(set: [water_body_id: nil])

    WaterBodyConnection
    |> where([connection], connection.origin_water_body_id in subquery(water_body_ids))
    |> Repo.delete_all()

    ProvinceWaterBody
    |> where([link], link.water_body_id in subquery(water_body_ids))
    |> Repo.delete_all()

    WaterBody
    |> where([water], water.id in subquery(water_body_ids))
    |> Repo.update_all(set: [parent_water_body_id: nil])

    WaterBody
    |> where([water], water.id in subquery(water_body_ids))
    |> Repo.delete_all()

    :ok
  end

  defp delete_landholdings_for_world(world_id) do
    household_ids =
      Household
      |> where([household], household.world_id == ^world_id)
      |> select([household], household.id)

    Landholding
    |> where([holding], holding.household_id in subquery(household_ids))
    |> Repo.delete_all()

    :ok
  end

  defp delete_character_relationships_for_world(world_id) do
    CharacterRelationship
    |> where([relationship], relationship.world_id == ^world_id)
    |> Repo.delete_all()

    :ok
  end

  defp delete_household_memberships_for_world(world_id) do
    household_ids =
      Household
      |> where([household], household.world_id == ^world_id)
      |> select([household], household.id)

    HouseholdMembership
    |> where([membership], membership.household_id in subquery(household_ids))
    |> Repo.delete_all()

    :ok
  end

  defp lock_continents(continent_ids) do
    Continent
    |> where([continent], continent.id in ^continent_ids)
    |> order_by([continent], asc: continent.id)
    |> lock("FOR UPDATE")
    |> Repo.all()

    :ok
  end

  defp lock_provinces(province_ids) do
    Province
    |> where([province], province.id in ^province_ids)
    |> order_by([province], asc: province.id)
    |> lock("FOR UPDATE")
    |> Repo.all()

    :ok
  end

  defp lock_geography_holds(hold_ids) do
    Hold
    |> where([hold], hold.id in ^hold_ids)
    |> order_by([hold], asc: hold.id)
    |> lock("FOR UPDATE")
    |> Repo.all()

    :ok
  end

  defp lock_location_types(location_type_ids) do
    LocationType
    |> where([location_type], location_type.id in ^location_type_ids)
    |> order_by([location_type], asc: location_type.id)
    |> lock("FOR UPDATE")
    |> Repo.all()

    :ok
  end

  defp lock_locations(location_ids) do
    Location
    |> where([location], location.id in ^location_ids)
    |> order_by([location], asc: location.id)
    |> lock("FOR UPDATE")
    |> Repo.all()

    :ok
  end

  defp landholdings_for_hold_ids?([]), do: false

  defp landholdings_for_hold_ids?(hold_ids) do
    location_ids =
      Location
      |> where([location], location.hold_id in ^hold_ids)
      |> select([location], location.id)

    Landholding
    |> where(
      [holding],
      holding.hold_id in ^hold_ids or holding.location_id in subquery(location_ids)
    )
    |> Repo.exists?()
  end

  defp landholdings_for_location_ids?([]), do: false

  defp landholdings_for_location_ids?(location_ids) do
    Landholding
    |> where([holding], holding.location_id in ^location_ids)
    |> Repo.exists?()
  end

  defp trade_route_stops_for_hold_ids?([]) do
    false
  end

  defp trade_route_stops_for_hold_ids?(hold_ids) do
    TradeRouteStop
    |> join(:inner, [stop], location in assoc(stop, :location))
    |> where([_stop, location], location.hold_id in ^hold_ids)
    |> Repo.exists?()
  end

  defp trade_route_stops_for_location_ids?([]) do
    false
  end

  defp trade_route_stops_for_location_ids?(location_ids) do
    TradeRouteStop
    |> where([stop], stop.location_id in ^location_ids)
    |> Repo.exists?()
  end

  defp delete_locations_for_holds([]) do
    :ok
  end

  defp delete_locations_for_holds(hold_ids) do
    Hold
    |> where([hold], hold.id in ^hold_ids)
    |> Repo.update_all(set: [capital_location_id: nil])

    Location
    |> where([location], location.hold_id in ^hold_ids)
    |> Repo.delete_all()

    :ok
  end

  defp delete_location_types_for_world(world_id) do
    LocationType
    |> where([location_type], location_type.world_id == ^world_id)
    |> Repo.delete_all()
  end

  defp delete_holds_by_ids([]) do
    :ok
  end

  defp delete_holds_by_ids(hold_ids) do
    Hold
    |> where([hold], hold.id in ^hold_ids)
    |> Repo.delete_all()

    :ok
  end

  defp delete_provinces_by_ids([]) do
    :ok
  end

  defp delete_provinces_by_ids(province_ids) do
    Province
    |> where([province], province.id in ^province_ids)
    |> Repo.delete_all()

    :ok
  end

  defp delete_continents_by_ids([]) do
    :ok
  end

  defp delete_continents_by_ids(continent_ids) do
    Continent
    |> where([continent], continent.id in ^continent_ids)
    |> Repo.delete_all()

    :ok
  end

  defp location_ids_with_descendants(%Location{hold_id: hold_id, id: location_id}) do
    hold_id
    |> locations_for_hold()
    |> descendant_ids(location_id)
  end

  defp timeline_event_era(_timeline, nil) do
    {:ok, nil}
  end

  defp timeline_event_era(
         %Timeline{id: timeline_id},
         %TimelineEra{timeline_id: timeline_id} = era
       ) do
    {:ok, era}
  end

  defp timeline_event_era(%Timeline{}, %TimelineEra{}) do
    {:error, :timeline_era_outside_timeline}
  end

  defp locations_for_hold(hold_id) do
    Location
    |> where([location], location.hold_id == ^hold_id)
    |> select([location], %{id: location.id, parent_location_id: location.parent_location_id})
    |> Repo.all()
  end

  defp descendant_ids(locations, parent_id) do
    child_ids =
      locations
      |> Enum.filter(&(&1.parent_location_id == parent_id))
      |> Enum.map(& &1.id)

    Enum.reduce(child_ids, [parent_id], fn child_id, acc ->
      acc ++ descendant_ids(locations, child_id)
    end)
  end

  defp location_type_ids_with_descendants(%LocationType{
         world_id: world_id,
         id: location_type_id
       }) do
    world_id
    |> location_types_for_world()
    |> descendant_ids(location_type_id)
  end

  defp location_types_for_world(world_id) do
    LocationType
    |> where([location_type], location_type.world_id == ^world_id)
    |> select([location_type], %{
      id: location_type.id,
      parent_location_id: location_type.parent_id
    })
    |> Repo.all()
  end

  defp clear_capitals_for_locations([]) do
    :ok
  end

  defp clear_capitals_for_locations(location_ids) do
    Hold
    |> where([hold], hold.capital_location_id in ^location_ids)
    |> Repo.update_all(set: [capital_location_id: nil])

    :ok
  end

  defp merge_template_attrs(template_data, attrs) do
    attrs = normalize_world_attrs(attrs)

    template_data
    |> Map.take([
      :name,
      :description,
      :primary_star_name,
      :orbital_period_days,
      :axial_tilt_degrees,
      :day_length_hours,
      :mean_radius_km,
      :mass_earths,
      :surface_gravity_m_s2,
      :orbital_distance_au,
      :orbital_eccentricity,
      :atmospheric_pressure_atm,
      :bond_albedo,
      :ocean_fraction,
      :star_mass_solar,
      :star_luminosity_solar,
      :star_temperature_k,
      :map_projection
    ])
    |> Map.merge(attrs)
  end

  defp normalize_world_attrs(attrs) do
    %{}
    |> maybe_put_attr(:name, attrs[:name] || attrs["name"])
    |> maybe_put_attr(:description, attrs[:description] || attrs["description"])
    |> maybe_put_attr(:primary_star_name, attrs[:primary_star_name] || attrs["primary_star_name"])
    |> maybe_put_attr(
      :orbital_period_days,
      attrs[:orbital_period_days] || attrs["orbital_period_days"]
    )
    |> maybe_put_attr(
      :axial_tilt_degrees,
      attrs[:axial_tilt_degrees] || attrs["axial_tilt_degrees"]
    )
    |> maybe_put_attr(:day_length_hours, attrs[:day_length_hours] || attrs["day_length_hours"])
    |> maybe_put_attr(:mean_radius_km, attrs[:mean_radius_km] || attrs["mean_radius_km"])
    |> maybe_put_attr(:mass_earths, attrs[:mass_earths] || attrs["mass_earths"])
    |> maybe_put_attr(
      :surface_gravity_m_s2,
      attrs[:surface_gravity_m_s2] || attrs["surface_gravity_m_s2"]
    )
    |> maybe_put_attr(
      :orbital_distance_au,
      attrs[:orbital_distance_au] || attrs["orbital_distance_au"]
    )
    |> maybe_put_attr(
      :orbital_eccentricity,
      attrs[:orbital_eccentricity] || attrs["orbital_eccentricity"]
    )
    |> maybe_put_attr(
      :atmospheric_pressure_atm,
      attrs[:atmospheric_pressure_atm] || attrs["atmospheric_pressure_atm"]
    )
    |> maybe_put_attr(:bond_albedo, attrs[:bond_albedo] || attrs["bond_albedo"])
    |> maybe_put_attr(:ocean_fraction, attrs[:ocean_fraction] || attrs["ocean_fraction"])
    |> maybe_put_attr(:star_mass_solar, attrs[:star_mass_solar] || attrs["star_mass_solar"])
    |> maybe_put_attr(
      :star_luminosity_solar,
      attrs[:star_luminosity_solar] || attrs["star_luminosity_solar"]
    )
    |> maybe_put_attr(
      :star_temperature_k,
      attrs[:star_temperature_k] || attrs["star_temperature_k"]
    )
    |> maybe_put_attr(:map_projection, attrs[:map_projection] || attrs["map_projection"])
    |> maybe_put_attr(:moons, attrs[:moons] || attrs["moons"])
    |> maybe_put_attr(:moons_sort, attrs[:moons_sort] || attrs["moons_sort"])
    |> maybe_put_attr(:moons_drop, attrs[:moons_drop] || attrs["moons_drop"])
  end

  defp prepare_world_creation_attrs(attrs) when is_map(attrs) do
    prepare_world_moon_attrs(attrs, nil)
  end

  defp prepare_world_moon_attrs(attrs, fallback_mass) when is_map(attrs) do
    with {:ok, planet_mass} <-
           positive_float(world_mass_value(attrs, fallback_mass), @max_world_mass_earths) do
      update_moon_attrs(attrs, fn moon_attrs ->
        derive_moon_orbital_period(moon_attrs, planet_mass)
      end)
    else
      :error -> attrs
    end
  end

  defp world_mass_value(attrs, fallback_mass) do
    if Map.has_key?(attrs, :mass_earths) or Map.has_key?(attrs, "mass_earths") do
      creation_attr_value(attrs, :mass_earths)
    else
      fallback_mass
    end
  end

  defp update_moon_attrs(attrs, update_fun) do
    cond do
      Map.has_key?(attrs, :moons) ->
        Map.update!(attrs, :moons, &map_moon_attrs(&1, update_fun))

      Map.has_key?(attrs, "moons") ->
        Map.update!(attrs, "moons", &map_moon_attrs(&1, update_fun))

      true ->
        attrs
    end
  end

  defp map_moon_attrs(moons, update_fun) when is_list(moons) do
    Enum.map(moons, update_fun)
  end

  defp map_moon_attrs(moons, update_fun) when is_map(moons) do
    Map.new(moons, fn {key, moon_attrs} -> {key, update_fun.(moon_attrs)} end)
  end

  defp map_moon_attrs(moons, _update_fun) do
    moons
  end

  defp derive_moon_orbital_period(moon_attrs, planet_mass) when is_map(moon_attrs) do
    period = creation_attr_value(moon_attrs, :orbital_period_days)

    if period in [nil, ""] do
      with {:ok, semi_major_axis} <-
             positive_float(
               creation_attr_value(moon_attrs, :semi_major_axis_km),
               @max_bigint
             ),
           {:ok, moon_mass} <-
             non_negative_float(
               creation_attr_value(moon_attrs, :mass_lunar),
               @max_moon_mass_lunar
             ) do
        total_mass_earths = planet_mass + moon_mass * @lunar_mass_earths
        gravitational_parameter = @earth_gravitational_parameter_km3_s2 * total_mass_earths

        orbital_period_days =
          2.0 * :math.pi() * :math.sqrt(semi_major_axis ** 3 / gravitational_parameter) /
            @seconds_per_day

        put_attr(moon_attrs, :orbital_period_days, Decimal.from_float(orbital_period_days))
      else
        :error -> moon_attrs
      end
    else
      moon_attrs
    end
  end

  defp creation_attr_value(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp positive_float(value, maximum) do
    with {:ok, decimal} <- Decimal.cast(value),
         :gt <- Decimal.compare(decimal, Decimal.new(0)),
         comparison when comparison in [:eq, :lt] <-
           Decimal.compare(decimal, Decimal.new(maximum)) do
      {:ok, Decimal.to_float(decimal)}
    else
      _other -> :error
    end
  end

  defp non_negative_float(value, _maximum) when value in [nil, ""] do
    {:ok, 0.0}
  end

  defp non_negative_float(value, maximum) do
    with {:ok, decimal} <- Decimal.cast(value),
         minimum_comparison when minimum_comparison in [:eq, :gt] <-
           Decimal.compare(decimal, Decimal.new(0)),
         maximum_comparison when maximum_comparison in [:eq, :lt] <-
           Decimal.compare(decimal, Decimal.new(maximum)) do
      {:ok, Decimal.to_float(decimal)}
    else
      _other -> :error
    end
  end

  defp put_attr(attrs, key, value) do
    if Enum.any?(Map.keys(attrs), &is_atom/1) do
      Map.put(attrs, key, value)
    else
      Map.put(attrs, Atom.to_string(key), value)
    end
  end

  defp maybe_put_attr(attrs, _key, nil) do
    attrs
  end

  defp maybe_put_attr(attrs, _key, "") do
    attrs
  end

  defp maybe_put_attr(attrs, key, value) do
    Map.put(attrs, key, value)
  end

  defp build_template_world!(
         world,
         %{continents: continents, location_types: location_types} = template_data
       ) do
    type_by_name = build_template_location_types!(world, location_types)

    creature_type_by_name =
      build_template_creature_types!(world, Map.get(template_data, :creature_types, []))

    creature_by_name =
      build_template_creatures!(
        world,
        Map.get(template_data, :creatures, []),
        creature_type_by_name
      )

    build_template_moons!(world, Map.get(template_data, :moons, []))

    god_by_name = build_template_gods!(world, Map.get(template_data, :gods, []))
    build_template_spells!(world, Map.get(template_data, :spells, []))
    effect_by_name = build_template_effects!(world, Map.get(template_data, :effects, []))

    item_by_name =
      build_template_items!(world, Map.get(template_data, :items, []), effect_by_name)

    skill_tree_by_name =
      build_template_skill_trees!(world, Map.get(template_data, :skill_trees, []))

    skill_by_name =
      build_template_skills!(world, Map.get(template_data, :skills, []), skill_tree_by_name)

    occupation_by_name =
      build_template_occupations!(world, Map.get(template_data, :occupations, []))

    guild_by_name =
      build_template_guilds!(world, Map.get(template_data, :guilds, []), god_by_name)

    era_by_name = build_template_timelines!(world, Map.get(template_data, :timelines, []))
    race_by_name = build_template_races!(world, Map.get(template_data, :races, []))

    character_role_by_name = build_template_character_roles!(world, template_data)

    civilization_by_name =
      build_template_civilizations!(
        world,
        Map.get(template_data, :civilizations, []),
        era_by_name
      )

    build_template_continents!(world, continents, type_by_name)

    build_template_item_locations!(world, Map.get(template_data, :items, []), item_by_name)
    build_template_creature_locations!(world, template_data, creature_by_name)
    build_template_location_gods!(world, template_data, god_by_name)
    build_template_assemblies!(world, template_data)

    water_by_name = build_template_waters!(world, template_data)
    build_template_location_water_links!(world, template_data, water_by_name)
    route_by_name = build_template_trade_routes!(world, template_data, water_by_name)

    character_by_name =
      build_template_characters!(
        world,
        Map.get(template_data, :characters, []),
        race_by_name,
        guild_by_name,
        character_role_by_name
      )

    build_template_political_offices!(
      world,
      Map.get(template_data, :political_offices, []),
      character_by_name
    )

    build_template_character_links!(world, template_data, character_by_name, skill_by_name)

    build_template_guild_links!(
      world,
      template_data,
      guild_by_name,
      character_by_name,
      god_by_name
    )

    build_template_civilization_links!(
      world,
      template_data,
      civilization_by_name,
      race_by_name
    )

    build_template_character_relationships!(world, template_data, character_by_name)

    household_by_name =
      build_template_households!(world, template_data, character_by_name)

    build_template_tax_policies!(world, template_data, guild_by_name, route_by_name)

    build_template_commercial_ventures!(
      world,
      template_data,
      character_by_name,
      household_by_name,
      route_by_name
    )

    build_template_character_occupations!(
      Map.get(template_data, :characters, []),
      character_by_name,
      occupation_by_name
    )

    build_template_character_inventory!(
      Map.get(template_data, :characters, []),
      character_by_name,
      item_by_name
    )

    template_refs =
      template_refs(world, %{
        characters: character_by_name,
        civilizations: civilization_by_name,
        gods: god_by_name,
        guilds: guild_by_name,
        races: race_by_name
      })

    build_template_documents!(world, Map.get(template_data, :documents, []), template_refs)

    build_template_lore_connections!(
      world,
      Map.get(template_data, :lore_connections, []),
      template_refs
    )

    get_world!(world.id)
  end

  defp build_template_world!(world, %{continents: continents} = template_data) do
    creature_type_by_name =
      build_template_creature_types!(world, Map.get(template_data, :creature_types, []))

    creature_by_name =
      build_template_creatures!(
        world,
        Map.get(template_data, :creatures, []),
        creature_type_by_name
      )

    build_template_moons!(world, Map.get(template_data, :moons, []))

    god_by_name = build_template_gods!(world, Map.get(template_data, :gods, []))
    build_template_spells!(world, Map.get(template_data, :spells, []))
    effect_by_name = build_template_effects!(world, Map.get(template_data, :effects, []))

    item_by_name =
      build_template_items!(world, Map.get(template_data, :items, []), effect_by_name)

    skill_tree_by_name =
      build_template_skill_trees!(world, Map.get(template_data, :skill_trees, []))

    skill_by_name =
      build_template_skills!(world, Map.get(template_data, :skills, []), skill_tree_by_name)

    occupation_by_name =
      build_template_occupations!(world, Map.get(template_data, :occupations, []))

    guild_by_name =
      build_template_guilds!(world, Map.get(template_data, :guilds, []), god_by_name)

    era_by_name = build_template_timelines!(world, Map.get(template_data, :timelines, []))
    race_by_name = build_template_races!(world, Map.get(template_data, :races, []))

    character_role_by_name = build_template_character_roles!(world, template_data)

    civilization_by_name =
      build_template_civilizations!(
        world,
        Map.get(template_data, :civilizations, []),
        era_by_name
      )

    build_template_continents!(world, continents, %{})

    build_template_item_locations!(world, Map.get(template_data, :items, []), item_by_name)
    build_template_creature_locations!(world, template_data, creature_by_name)
    build_template_location_gods!(world, template_data, god_by_name)
    build_template_assemblies!(world, template_data)

    water_by_name = build_template_waters!(world, template_data)
    build_template_location_water_links!(world, template_data, water_by_name)
    route_by_name = build_template_trade_routes!(world, template_data, water_by_name)

    character_by_name =
      build_template_characters!(
        world,
        Map.get(template_data, :characters, []),
        race_by_name,
        guild_by_name,
        character_role_by_name
      )

    build_template_political_offices!(
      world,
      Map.get(template_data, :political_offices, []),
      character_by_name
    )

    build_template_character_links!(world, template_data, character_by_name, skill_by_name)

    build_template_guild_links!(
      world,
      template_data,
      guild_by_name,
      character_by_name,
      god_by_name
    )

    build_template_civilization_links!(
      world,
      template_data,
      civilization_by_name,
      race_by_name
    )

    build_template_character_relationships!(world, template_data, character_by_name)

    household_by_name =
      build_template_households!(world, template_data, character_by_name)

    build_template_tax_policies!(world, template_data, guild_by_name, route_by_name)

    build_template_commercial_ventures!(
      world,
      template_data,
      character_by_name,
      household_by_name,
      route_by_name
    )

    build_template_character_occupations!(
      Map.get(template_data, :characters, []),
      character_by_name,
      occupation_by_name
    )

    build_template_character_inventory!(
      Map.get(template_data, :characters, []),
      character_by_name,
      item_by_name
    )

    template_refs =
      template_refs(world, %{
        characters: character_by_name,
        civilizations: civilization_by_name,
        gods: god_by_name,
        guilds: guild_by_name,
        races: race_by_name
      })

    build_template_documents!(world, Map.get(template_data, :documents, []), template_refs)

    build_template_lore_connections!(
      world,
      Map.get(template_data, :lore_connections, []),
      template_refs
    )

    get_world!(world.id)
  end

  defp build_template_location_types!(world, location_types) do
    Enum.reduce(location_types, %{}, fn location_type_data, acc ->
      create_template_location_type!(world, location_type_data, acc)
    end)
  end

  defp build_template_races!(world, races) do
    Enum.reduce(races, %{}, fn race_data, acc ->
      race =
        world
        |> create_race(race_data, %{})
        |> unwrap_transaction!()

      Map.put(acc, race.name, race)
    end)
  end

  defp ensure_template_galaxies!(galaxies) do
    Enum.reduce(galaxies, %{}, fn galaxy_data, acc ->
      galaxy = Galaxies.get_or_create_galaxy_by_name!(galaxy_data)

      Map.put(acc, galaxy.name, galaxy)
    end)
  end

  defp build_template_timelines!(world, timelines) do
    Enum.reduce(timelines, %{}, fn timeline_data, acc ->
      timeline =
        world
        |> create_timeline(timeline_data)
        |> unwrap_transaction!()

      era_by_name =
        timeline_data
        |> Map.get(:eras, [])
        |> Enum.reduce(acc, fn era_data, era_acc ->
          era =
            timeline
            |> create_timeline_era(era_data)
            |> unwrap_transaction!()

          Map.put(era_acc, era.name, era)
        end)

      build_template_timeline_events!(
        timeline,
        Map.get(timeline_data, :events, []),
        era_by_name
      )

      era_by_name
    end)
  end

  defp build_template_timeline_events!(timeline, events, era_by_name) do
    for event_data <- events do
      refs = %{timeline_era: Map.get(era_by_name, event_data[:timeline_era])}

      timeline
      |> create_timeline_event(event_data, refs)
      |> unwrap_transaction!()
    end
  end

  defp build_template_civilizations!(world, civilizations, era_by_name) do
    Enum.reduce(civilizations, %{}, fn civilization_data, acc ->
      refs = %{timeline_era: Map.get(era_by_name, civilization_data[:timeline_era])}

      civilization =
        world
        |> create_civilization(civilization_data, refs)
        |> unwrap_transaction!()

      Map.put(acc, civilization.name, civilization)
    end)
  end

  defp build_template_creature_types!(world, creature_types) do
    Enum.reduce(creature_types, %{}, fn creature_type_data, acc ->
      creature_type =
        world
        |> create_creature_type(creature_type_data)
        |> unwrap_transaction!()

      Map.put(acc, creature_type.name, creature_type)
    end)
  end

  defp build_template_creatures!(world, creatures, creature_type_by_name) do
    Enum.reduce(creatures, %{}, fn creature_data, acc ->
      creature_type = Map.get(creature_type_by_name, creature_data[:type])

      creature =
        world
        |> create_creature(creature_data, creature_type: creature_type)
        |> unwrap_transaction!()

      Map.put(acc, creature.name, creature)
    end)
  end

  defp build_template_moons!(world, moons) do
    for moon_data <- moons do
      world
      |> create_moon(moon_data)
      |> unwrap_transaction!()
    end
  end

  defp build_template_spells!(world, spells) do
    for spell_data <- spells do
      world
      |> create_spell(spell_data)
      |> unwrap_transaction!()
    end
  end

  defp build_template_effects!(world, effects) do
    Enum.reduce(effects, %{}, fn effect_data, acc ->
      effect =
        world
        |> create_effect(effect_data)
        |> unwrap_transaction!()

      Map.put(acc, effect.name, effect)
    end)
  end

  defp build_template_items!(world, items, effect_by_name) do
    Enum.reduce(items, %{}, fn item_data, acc ->
      item =
        world
        |> create_item(Map.drop(item_data, [:effects]))
        |> unwrap_transaction!()

      build_template_item_effects!(item, Map.get(item_data, :effects, []), effect_by_name)

      Map.put(acc, item.name, item)
    end)
  end

  defp build_template_item_effects!(item, effects, effect_by_name) do
    effects
    |> Enum.with_index(1)
    |> Enum.each(fn {effect_name, position} ->
      effect = Map.fetch!(effect_by_name, effect_name)

      item
      |> create_item_effect(effect, %{position: position})
      |> unwrap_transaction!()
    end)
  end

  defp build_template_skill_trees!(world, skill_trees) do
    Enum.reduce(skill_trees, %{}, fn skill_tree_data, acc ->
      skill_tree =
        world
        |> create_skill_tree(skill_tree_data)
        |> unwrap_transaction!()

      for perk_data <- Map.get(skill_tree_data, :perks, []) do
        skill_tree
        |> create_skill_tree_perk(perk_data)
        |> unwrap_transaction!()
      end

      Map.put(acc, skill_tree.name, skill_tree)
    end)
  end

  defp build_template_skills!(world, skills, skill_tree_by_name) do
    Enum.reduce(skills, %{}, fn skill_data, acc ->
      refs = %{skill_tree: Map.get(skill_tree_by_name, skill_data[:skill_tree])}

      skill =
        world
        |> create_skill(skill_data, refs)
        |> unwrap_transaction!()

      for level_data <- Map.get(skill_data, :levels, []) do
        skill
        |> create_skill_level(level_data)
        |> unwrap_transaction!()
      end

      Map.put(acc, skill.name, skill)
    end)
  end

  defp build_template_occupations!(world, occupations) do
    Enum.reduce(occupations, %{}, fn occupation_data, acc ->
      occupation =
        world
        |> create_occupation(occupation_data)
        |> unwrap_transaction!()

      Map.put(acc, occupation.name, occupation)
    end)
  end

  defp build_template_gods!(world, gods) do
    Enum.reduce(gods, %{}, fn god_data, acc ->
      god =
        world
        |> create_god(god_data)
        |> unwrap_transaction!()

      Map.put(acc, god.name, god)
    end)
  end

  defp build_template_guilds!(world, guilds, god_by_name) do
    Enum.reduce(guilds, %{}, fn guild_data, acc ->
      guild =
        world
        |> create_guild(guild_data)
        |> unwrap_transaction!()

      if patron_god = Map.get(god_by_name, guild_data[:patron]) do
        guild
        |> create_guild_influence(
          %{
            relationship: "serves",
            description: "#{guild.name} serves or venerates #{patron_god.name}."
          },
          god: patron_god
        )
        |> unwrap_transaction!()
      end

      Map.put(acc, guild.name, guild)
    end)
  end

  defp build_template_character_roles!(world, template_data) do
    characters = Map.get(template_data, :characters, [])

    explicit_roles = Map.get(template_data, :character_roles, [])
    explicit_names = MapSet.new(explicit_roles, & &1.name)

    derived_roles =
      characters
      |> Enum.map(&Map.get(&1, :role))
      |> Enum.reject(&(is_nil(&1) or MapSet.member?(explicit_names, &1)))
      |> Enum.uniq()
      |> Enum.map(fn role_name ->
        %{
          name: role_name,
          description: "Imported template character role for #{role_name}."
        }
      end)

    Enum.reduce(explicit_roles ++ derived_roles, %{}, fn role_data, acc ->
      role =
        world
        |> create_character_role(role_data)
        |> unwrap_transaction!()

      Map.put(acc, role.name, role)
    end)
  end

  defp build_template_characters!(
         world,
         characters,
         race_by_name,
         guild_by_name,
         character_role_by_name
       ) do
    location_by_name = locations_by_name(world)

    Enum.reduce(characters, %{}, fn character_data, acc ->
      refs = %{
        character_role: Map.get(character_role_by_name, character_data[:role]),
        race: Map.get(race_by_name, character_data[:race]),
        guild: Map.get(guild_by_name, character_data[:guild]),
        home_location: Map.get(location_by_name, character_data[:home_location])
      }

      world
      |> create_character(character_data, refs)
      |> unwrap_transaction!()
      |> then(fn character -> Map.put(acc, character.name, character) end)
    end)
  end

  defp build_template_character_occupations!(characters, character_by_name, occupation_by_name) do
    for character_data <- characters,
        occupation_data <- Map.get(character_data, :occupations, []) do
      {occupation_name, attrs} = template_character_occupation(occupation_data, character_data)
      character = Map.fetch!(character_by_name, character_data.name)
      occupation = Map.fetch!(occupation_by_name, occupation_name)

      character
      |> create_character_occupation(occupation, attrs)
      |> unwrap_transaction!()
    end
  end

  defp template_character_occupation(occupation_name, character_data)
       when is_binary(occupation_name) do
    {occupation_name,
     %{
       primary: primary_occupation?(character_data, occupation_name)
     }}
  end

  defp template_character_occupation(occupation_data, _character_data) do
    {occupation_data.occupation, Map.drop(occupation_data, [:occupation])}
  end

  defp build_template_character_inventory!(characters, character_by_name, item_by_name) do
    for character_data <- characters do
      character = Map.fetch!(character_by_name, character_data.name)

      category_by_name =
        build_template_inventory_categories!(
          character,
          Map.get(character_data, :inventory_categories, [])
        )

      build_template_inventory_items!(
        character,
        Map.get(character_data, :inventory_items, []),
        category_by_name,
        item_by_name
      )
    end
  end

  defp build_template_inventory_categories!(character, categories) do
    Enum.reduce(categories, %{}, fn category_data, acc ->
      category =
        character
        |> create_inventory_category(category_data)
        |> unwrap_transaction!()

      Map.put(acc, category.name, category)
    end)
  end

  defp build_template_inventory_items!(character, items, category_by_name, item_by_name) do
    for item_data <- items do
      refs = %{
        inventory_category: Map.get(category_by_name, item_data[:category]),
        item: Map.get(item_by_name, item_data[:item])
      }

      character
      |> create_inventory_item(item_data, refs)
      |> unwrap_transaction!()
    end
  end

  defp build_template_documents!(world, documents, template_refs) do
    for document_data <- documents do
      refs = %{
        author_character: template_ref(template_refs, :character, document_data[:author]),
        location: template_ref(template_refs, :location, document_data[:location]),
        guild: template_ref(template_refs, :guild, document_data[:guild]),
        god: template_ref(template_refs, :god, document_data[:god]),
        race: template_ref(template_refs, :race, document_data[:race]),
        civilization: template_ref(template_refs, :civilization, document_data[:civilization])
      }

      world
      |> create_document(document_data, refs)
      |> unwrap_transaction!()
    end
  end

  defp build_template_lore_connections!(world, lore_connections, template_refs) do
    for lore_connection_data <- lore_connections do
      refs = %{
        source: template_endpoint(template_refs, lore_connection_data[:source]),
        target: template_endpoint(template_refs, lore_connection_data[:target])
      }

      world
      |> create_lore_connection(lore_connection_data, refs)
      |> unwrap_transaction!()
    end
  end

  defp template_refs(world, refs) do
    refs
    |> Map.put(:continents, continents_by_name(world))
    |> Map.put(:holds, holds_by_name(world))
    |> Map.put(:locations, locations_by_name(world))
    |> Map.put(:provinces, provinces_by_name(world))
  end

  defp template_endpoint(_template_refs, nil) do
    nil
  end

  defp template_endpoint(template_refs, {kind, name}) do
    {kind, template_ref(template_refs, kind, name)}
  end

  defp template_endpoint(template_refs, %{kind: kind, name: name}) do
    template_endpoint(template_refs, {String.to_existing_atom(kind), name})
  end

  defp template_ref(_template_refs, _kind, nil) do
    nil
  end

  defp template_ref(template_refs, kind, name) do
    template_refs
    |> Map.fetch!(template_ref_key(kind))
    |> Map.get(name)
  end

  defp template_ref_key(:character) do
    :characters
  end

  defp template_ref_key(:civilization) do
    :civilizations
  end

  defp template_ref_key(:continent) do
    :continents
  end

  defp template_ref_key(:god) do
    :gods
  end

  defp template_ref_key(:guild) do
    :guilds
  end

  defp template_ref_key(:hold) do
    :holds
  end

  defp template_ref_key(:location) do
    :locations
  end

  defp template_ref_key(:province) do
    :provinces
  end

  defp template_ref_key(:race) do
    :races
  end

  defp primary_occupation?(%{primary_occupation: occupation_name}, occupation_name) do
    true
  end

  defp primary_occupation?(_character_data, _occupation_name) do
    false
  end

  defp build_template_political_offices!(world, political_offices, character_by_name) do
    continent_by_name = continents_by_name(world)
    province_by_name = provinces_by_name(world)
    hold_by_name = holds_by_name(world)

    for office_data <- political_offices do
      refs = %{
        continent: Map.get(continent_by_name, office_data[:continent]),
        province: Map.get(province_by_name, office_data[:province]),
        hold: Map.get(hold_by_name, office_data[:hold]),
        character: Map.get(character_by_name, office_data[:character]),
        designated_successor: Map.get(character_by_name, office_data[:designated_successor])
      }

      world
      |> create_political_office(office_data, refs)
      |> unwrap_transaction!()
    end
  end

  defp build_template_item_locations!(world, items, item_by_name) do
    location_by_name = locations_by_name(world)

    for item_data <- items,
        location_name = item_data[:find_location],
        not is_nil(location_name) do
      item = Map.fetch!(item_by_name, item_data.name)
      location = Map.fetch!(location_by_name, location_name)

      item
      |> update_item(%{}, %{find_location: location})
      |> unwrap_transaction!()
    end
  end

  defp build_template_creature_locations!(world, template_data, creature_by_name) do
    location_by_name = locations_by_name(world)

    for link_data <- Map.get(template_data, :creature_locations, []) do
      creature = Map.fetch!(creature_by_name, link_data.creature)
      location = Map.fetch!(location_by_name, link_data.location)

      creature
      |> create_creature_location(location, Map.drop(link_data, [:creature, :location]))
      |> unwrap_transaction!()
    end
  end

  defp build_template_location_gods!(world, template_data, god_by_name) do
    location_by_name = locations_by_name(world)

    for link_data <- Map.get(template_data, :location_gods, []) do
      location = Map.fetch!(location_by_name, link_data.location)
      god = Map.fetch!(god_by_name, link_data.god)

      world
      |> create_location_god(location, god, Map.drop(link_data, [:location, :god]))
      |> unwrap_transaction!()
    end
  end

  defp build_template_assemblies!(world, template_data) do
    continent_by_name = continents_by_name(world)
    province_by_name = provinces_by_name(world)
    hold_by_name = holds_by_name(world)
    location_by_name = locations_by_name(world)

    for assembly_data <- Map.get(template_data, :assemblies, []) do
      refs = %{
        continent: Map.get(continent_by_name, assembly_data[:continent]),
        province: Map.get(province_by_name, assembly_data[:province]),
        hold: Map.get(hold_by_name, assembly_data[:hold]),
        location: Map.get(location_by_name, assembly_data[:location])
      }

      world
      |> create_assembly(
        Map.drop(assembly_data, [:continent, :province, :hold, :location]),
        refs
      )
      |> unwrap_transaction!()
    end
  end

  defp build_template_character_links!(world, template_data, character_by_name, skill_by_name) do
    location_by_name = locations_by_name(world)

    for link_data <- Map.get(template_data, :character_locations, []) do
      character = Map.fetch!(character_by_name, link_data.character)
      location = Map.fetch!(location_by_name, link_data.location)

      %CharacterLocation{character_id: character.id, location_id: location.id}
      |> CharacterLocation.changeset(Map.drop(link_data, [:character, :location]))
      |> Repo.insert()
      |> unwrap_transaction!()
    end

    for link_data <- Map.get(template_data, :character_skills, []) do
      character = Map.fetch!(character_by_name, link_data.character)
      skill = Map.fetch!(skill_by_name, link_data.skill)

      character
      |> create_character_skill(skill, Map.drop(link_data, [:character, :skill]))
      |> unwrap_transaction!()
    end
  end

  defp build_template_guild_links!(
         _world,
         template_data,
         guild_by_name,
         character_by_name,
         god_by_name
       ) do
    for membership_data <- Map.get(template_data, :guild_memberships, []) do
      guild = Map.fetch!(guild_by_name, membership_data.guild)
      character = Map.fetch!(character_by_name, membership_data.character)
      attrs = Map.drop(membership_data, [:guild, :character])

      case Repo.get_by(GuildMembership, guild_id: guild.id, character_id: character.id) do
        nil ->
          %GuildMembership{guild_id: guild.id, character_id: character.id}
          |> GuildMembership.changeset(attrs)
          |> Repo.insert()
          |> unwrap_transaction!()

        membership ->
          membership
          |> GuildMembership.changeset(attrs)
          |> Repo.update()
          |> unwrap_transaction!()
      end
    end

    for influence_data <- Map.get(template_data, :guild_influences, []) do
      guild = Map.fetch!(guild_by_name, influence_data.guild)

      refs = %{
        character: Map.get(character_by_name, influence_data[:character]),
        god: Map.get(god_by_name, influence_data[:god])
      }

      guild
      |> create_guild_influence(Map.drop(influence_data, [:guild, :character, :god]), refs)
      |> unwrap_transaction!()
    end
  end

  defp build_template_civilization_links!(
         world,
         template_data,
         civilization_by_name,
         race_by_name
       ) do
    location_by_name = locations_by_name(world)

    for link_data <- Map.get(template_data, :civilization_locations, []) do
      civilization = Map.fetch!(civilization_by_name, link_data.civilization)
      location = Map.fetch!(location_by_name, link_data.location)

      civilization
      |> create_civilization_location(
        location,
        Map.drop(link_data, [:civilization, :location])
      )
      |> unwrap_transaction!()
    end

    for link_data <- Map.get(template_data, :civilization_races, []) do
      civilization = Map.fetch!(civilization_by_name, link_data.civilization)
      race = Map.fetch!(race_by_name, link_data.race)

      civilization
      |> create_civilization_race(race, Map.drop(link_data, [:civilization, :race]))
      |> unwrap_transaction!()
    end
  end

  defp build_template_character_relationships!(world, template_data, character_by_name) do
    for relationship_data <- Map.get(template_data, :character_relationships, []) do
      character_a = Map.fetch!(character_by_name, relationship_data.character_a)
      character_b = Map.fetch!(character_by_name, relationship_data.character_b)

      world
      |> create_character_relationship(
        character_a,
        character_b,
        Map.drop(relationship_data, [:character_a, :character_b])
      )
      |> unwrap_transaction!()
    end
  end

  defp provinces_by_name(%World{id: world_id}) do
    world_id
    |> continent_ids_for_world()
    |> province_ids_for_continents()
    |> then(fn province_ids ->
      Province
      |> where([province], province.id in ^province_ids)
      |> Repo.all()
      |> Map.new(&{&1.name, &1})
    end)
  end

  defp continents_by_name(%World{id: world_id}) do
    Continent
    |> where([continent], continent.world_id == ^world_id)
    |> Repo.all()
    |> Map.new(&{&1.name, &1})
  end

  defp holds_by_name(%World{id: world_id}) do
    continent_ids = continent_ids_for_world(world_id)
    province_ids = province_ids_for_continents(continent_ids)
    hold_ids = hold_ids_for_provinces(province_ids)

    Hold
    |> where([hold], hold.id in ^hold_ids)
    |> Repo.all()
    |> Map.new(&{&1.name, &1})
  end

  defp locations_by_name(%World{id: world_id}) do
    continent_ids = continent_ids_for_world(world_id)
    province_ids = province_ids_for_continents(continent_ids)
    hold_ids = hold_ids_for_provinces(province_ids)

    locations =
      Location
      |> where([location], location.hold_id in ^hold_ids)
      |> Repo.all()

    hold_by_id =
      Hold
      |> where([hold], hold.id in ^hold_ids)
      |> Repo.all()
      |> Map.new(&{&1.id, &1})

    location_by_id = Map.new(locations, &{&1.id, &1})
    by_name = Map.new(locations, &{&1.name, &1})

    by_ref =
      Map.new(locations, fn location ->
        {template_location_ref(location, location_by_id, hold_by_id), location}
      end)

    Map.merge(by_name, by_ref)
  end

  defp template_location_ref(location, location_by_id, hold_by_id) do
    hold_name = Map.fetch!(hold_by_id, location.hold_id).name

    path =
      location
      |> location_ancestors(location_by_id, [])
      |> Enum.map_join("::", & &1.name)

    "#{hold_name}::#{path}"
  end

  defp location_ancestors(%Location{parent_location_id: nil} = location, _location_by_id, acc) do
    [location | acc]
  end

  defp location_ancestors(location, location_by_id, acc) do
    parent = Map.fetch!(location_by_id, location.parent_location_id)
    location_ancestors(parent, location_by_id, [location | acc])
  end

  defp create_template_location_type!(parent, location_type_data, acc) do
    location_type =
      parent
      |> create_location_type(location_type_data)
      |> unwrap_transaction!()

    acc = Map.put(acc, location_type.name, location_type)

    location_type_data
    |> Map.get(:children, [])
    |> Enum.reduce(acc, fn child_data, child_acc ->
      create_template_location_type!(location_type, child_data, child_acc)
    end)
  end

  defp build_template_continents!(world, continents, type_by_name) do
    for continent_data <- continents do
      continent =
        world
        |> create_continent(continent_data)
        |> unwrap_transaction!()

      if currency_data = continent_data[:currency] do
        continent
        |> put_continent_currency(currency_data)
        |> unwrap_transaction!()
      end

      build_template_calendars!(continent, Map.get(continent_data, :calendars, []))
      build_template_provinces!(continent, Map.get(continent_data, :provinces, []), type_by_name)
    end
  end

  defp build_template_calendars!(continent, calendars) do
    for calendar_data <- calendars do
      calendar =
        continent
        |> create_calendar(calendar_data)
        |> unwrap_transaction!()

      for month_data <- Map.get(calendar_data, :months, []) do
        calendar
        |> create_calendar_month(month_data)
        |> unwrap_transaction!()
      end
    end
  end

  defp build_template_provinces!(continent, provinces, type_by_name) do
    for province_data <- provinces do
      province =
        continent
        |> create_province(province_data)
        |> unwrap_transaction!()

      hold_by_name =
        build_template_holds!(province, Map.get(province_data, :holds, []), type_by_name)

      if capital_name = province_data[:capital] do
        hold_by_name
        |> Map.fetch!(capital_name)
        |> update_hold(province, %{}, province_capital: true)
        |> unwrap_transaction!()
      end
    end
  end

  defp build_template_holds!(province, holds, type_by_name) do
    Enum.reduce(holds, %{}, fn hold_data, hold_by_name ->
      hold =
        province
        |> create_hold(hold_data)
        |> unwrap_transaction!()

      build_template_hold_commerce_entries!(hold, Map.get(hold_data, :commerce_entries, []))
      build_template_hold_economy!(hold, hold_data)

      location_by_name =
        build_template_locations!(hold, Map.get(hold_data, :locations, []), type_by_name)

      hold =
        if capital_name = hold_data[:capital] do
          capital = Map.fetch!(location_by_name, capital_name)

          hold
          |> set_hold_capital(capital)
          |> unwrap_transaction!()
        else
          hold
        end

      Map.put(hold_by_name, hold.name, hold)
    end)
  end

  defp build_template_hold_commerce_entries!(hold, commerce_entries) do
    for commerce_data <- commerce_entries do
      hold
      |> create_hold_commerce_entry(commerce_data)
      |> unwrap_transaction!()
    end
  end

  defp build_template_hold_economy!(hold, hold_data) do
    if profile_data = hold_data[:economic_profile] do
      hold
      |> create_hold_economic_profile(profile_data)
      |> unwrap_transaction!()
    end

    for balance_data <- Map.get(hold_data, :commodity_balances, []) do
      hold
      |> create_commodity_balance(balance_data)
      |> unwrap_transaction!()
    end
  end

  defp build_template_locations!(hold, locations, type_by_name) do
    Enum.reduce(locations, %{}, fn location_data, acc ->
      create_template_location!(hold, location_data, type_by_name, acc)
    end)
  end

  defp create_template_location!(parent, location_data, type_by_name, acc) do
    location_type = Map.fetch!(type_by_name, location_data.type)

    location =
      case parent do
        %Hold{} ->
          parent
          |> create_location(location_type, location_data)
          |> unwrap_transaction!()

        %Location{} ->
          parent
          |> create_child_location(location_type, location_data)
          |> unwrap_transaction!()
      end

    acc = Map.put(acc, location.name, location)

    location_data
    |> Map.get(:children, [])
    |> Enum.reduce(acc, fn child_data, child_acc ->
      create_template_location!(location, child_data, type_by_name, child_acc)
    end)
  end

  defp build_template_waters!(world, template_data) do
    water_data = Map.get(template_data, :water_bodies, [])
    water_by_name = build_template_water_bodies!(world, water_data)
    province_by_name = provinces_by_name(world)

    for water <- water_data,
        link_data <- Map.get(water, :province_links, []) do
      province = Map.fetch!(province_by_name, link_data.province)
      water_body = Map.fetch!(water_by_name, water.name)

      province
      |> create_province_water_body(water_body, link_data)
      |> unwrap_transaction!()
    end

    for connection_data <- Map.get(template_data, :water_body_connections, []) do
      refs = %{
        origin_water_body: Map.fetch!(water_by_name, connection_data.origin_water_body),
        destination_water_body: Map.fetch!(water_by_name, connection_data.destination_water_body)
      }

      world
      |> create_water_body_connection(connection_data, refs)
      |> unwrap_transaction!()
    end

    water_by_name
  end

  defp build_template_water_bodies!(world, water_data) do
    data_by_name = Map.new(water_data, &{&1.name, &1})

    Enum.reduce(water_data, %{}, fn data, water_by_name ->
      {_water, water_by_name} =
        ensure_template_water_body!(world, data.name, data_by_name, water_by_name)

      water_by_name
    end)
  end

  defp ensure_template_water_body!(world, name, data_by_name, water_by_name) do
    case Map.fetch(water_by_name, name) do
      {:ok, water} ->
        {water, water_by_name}

      :error ->
        data = Map.fetch!(data_by_name, name)

        {parent, water_by_name} =
          case data[:parent] do
            nil ->
              {nil, water_by_name}

            parent_name ->
              ensure_template_water_body!(world, parent_name, data_by_name, water_by_name)
          end

        water =
          world
          |> create_water_body(data, %{parent_water_body: parent})
          |> unwrap_transaction!()

        {water, Map.put(water_by_name, water.name, water)}
    end
  end

  defp build_template_location_water_links!(world, template_data, water_by_name) do
    location_by_name = locations_by_name(world)

    template_data
    |> template_location_data()
    |> Enum.each(fn location_data ->
      if water_name = location_data[:water_body] do
        location_ref = location_data[:ref] || location_data.name
        location = Map.fetch!(location_by_name, location_ref)
        water_body = Map.fetch!(water_by_name, water_name)

        world
        |> set_location_water_body(location, water_body)
        |> unwrap_transaction!()
      end
    end)
  end

  defp template_location_data(template_data) do
    template_data
    |> Map.get(:continents, [])
    |> Enum.flat_map(&Map.get(&1, :provinces, []))
    |> Enum.flat_map(&Map.get(&1, :holds, []))
    |> Enum.flat_map(&flatten_template_locations(Map.get(&1, :locations, [])))
  end

  defp flatten_template_locations(locations) do
    Enum.flat_map(locations, fn location ->
      [location | flatten_template_locations(Map.get(location, :children, []))]
    end)
  end

  defp build_template_trade_routes!(world, template_data, water_by_name) do
    hold_by_name = holds_by_name(world)
    location_by_name = locations_by_name(world)
    currency_by_name = continent_currencies_by_name(world)

    Enum.reduce(Map.get(template_data, :trade_routes, []), %{}, fn route_data, route_by_name ->
      refs = %{
        origin_hold: Map.get(hold_by_name, route_data[:origin_hold]),
        destination_hold: Map.get(hold_by_name, route_data[:destination_hold]),
        origin_location: Map.get(location_by_name, route_data[:origin_location]),
        destination_location: Map.get(location_by_name, route_data[:destination_location])
      }

      route =
        world
        |> create_trade_route(route_data, refs)
        |> unwrap_transaction!()

      stop_by_position =
        Enum.reduce(Map.get(route_data, :stops, []), %{}, fn stop_data, acc ->
          location = Map.fetch!(location_by_name, stop_data.location)

          stop =
            route
            |> create_trade_route_stop(location, stop_data)
            |> unwrap_transaction!()

          Map.put(acc, stop.position, stop)
        end)

      for leg_data <- Map.get(route_data, :legs, []) do
        refs = %{
          origin_stop: Map.fetch!(stop_by_position, leg_data.origin_stop_position),
          destination_stop: Map.fetch!(stop_by_position, leg_data.destination_stop_position),
          water_body: Map.get(water_by_name, leg_data[:water_body])
        }

        route
        |> create_trade_route_leg(leg_data, refs)
        |> unwrap_transaction!()
      end

      for flow_data <- Map.get(route_data, :flows, []) do
        refs = %{currency: Map.get(currency_by_name, flow_data[:currency])}

        route
        |> create_trade_flow(flow_data, refs)
        |> unwrap_transaction!()
      end

      Map.put(route_by_name, route.name, route)
    end)
  end

  defp build_template_households!(world, template_data, character_by_name) do
    hold_by_name = holds_by_name(world)
    location_by_name = locations_by_name(world)

    Enum.reduce(Map.get(template_data, :households, []), %{}, fn household_data,
                                                                 household_by_name ->
      household =
        world
        |> create_household(household_data,
          home_location: Map.get(location_by_name, household_data[:home_location])
        )
        |> unwrap_transaction!()

      for membership_data <- Map.get(household_data, :memberships, []) do
        character = Map.fetch!(character_by_name, membership_data.character)

        household
        |> create_household_membership(character, membership_data)
        |> unwrap_transaction!()
      end

      for holding_data <- Map.get(household_data, :landholdings, []) do
        refs = [
          hold: Map.get(hold_by_name, holding_data[:hold]),
          location: Map.get(location_by_name, holding_data[:location])
        ]

        household
        |> create_landholding(holding_data, refs)
        |> unwrap_transaction!()
      end

      Map.put(household_by_name, household.name, household)
    end)
  end

  defp build_template_tax_policies!(world, template_data, guild_by_name, route_by_name) do
    continent_by_name = continents_by_name(world)
    province_by_name = provinces_by_name(world)
    hold_by_name = holds_by_name(world)
    currency_by_name = continent_currencies_by_name(world)
    office_by_ref = political_offices_by_template_ref(world)

    for policy_data <- Map.get(template_data, :tax_policies, []) do
      refs = %{
        continent: Map.get(continent_by_name, policy_data[:continent]),
        province: Map.get(province_by_name, policy_data[:province]),
        hold: Map.get(hold_by_name, policy_data[:hold]),
        collecting_office:
          Map.get(office_by_ref, political_office_template_ref(policy_data[:collecting_office])),
        currency: Map.get(currency_by_name, policy_data[:currency])
      }

      policy =
        world
        |> create_tax_policy(policy_data, refs)
        |> unwrap_transaction!()

      for assessment_data <- Map.get(policy_data, :assessments, []) do
        refs = %{currency: Map.get(currency_by_name, assessment_data[:currency])}

        policy
        |> create_tax_assessment(assessment_data, refs)
        |> unwrap_transaction!()
      end

      for exemption_data <- Map.get(policy_data, :exemptions, []) do
        refs = %{
          guild: Map.get(guild_by_name, exemption_data[:guild]),
          trade_route: Map.get(route_by_name, exemption_data[:trade_route]),
          continent: Map.get(continent_by_name, exemption_data[:continent]),
          province: Map.get(province_by_name, exemption_data[:province]),
          hold: Map.get(hold_by_name, exemption_data[:hold])
        }

        policy
        |> create_tax_exemption(exemption_data, refs)
        |> unwrap_transaction!()
      end

      for share_data <- Map.get(policy_data, :revenue_shares, []) do
        office_ref = political_office_template_ref(share_data.political_office)
        office = Map.fetch!(office_by_ref, office_ref)

        policy
        |> create_tax_revenue_share(share_data, %{political_office: office})
        |> unwrap_transaction!()
      end
    end
  end

  defp build_template_commercial_ventures!(
         world,
         template_data,
         character_by_name,
         household_by_name,
         route_by_name
       ) do
    location_by_name = locations_by_name(world)

    for venture_data <- Map.get(template_data, :commercial_ventures, []) do
      venture =
        world
        |> create_commercial_venture(venture_data, %{
          home_location: Map.get(location_by_name, venture_data[:home_location])
        })
        |> unwrap_transaction!()

      for membership_data <- Map.get(venture_data, :memberships, []) do
        refs = %{
          household: Map.get(household_by_name, membership_data[:household]),
          character: Map.get(character_by_name, membership_data[:character])
        }

        venture
        |> create_venture_membership(membership_data, refs)
        |> unwrap_transaction!()
      end

      for route_data <- Map.get(venture_data, :trade_routes, []) do
        route = Map.fetch!(route_by_name, route_data.trade_route)

        venture
        |> create_venture_trade_route(route, route_data)
        |> unwrap_transaction!()
      end
    end
  end

  defp continent_currencies_by_name(%World{id: world_id}) do
    ContinentCurrency
    |> join(:inner, [currency], continent in assoc(currency, :continent))
    |> where([_currency, continent], continent.world_id == ^world_id)
    |> Repo.all()
    |> Map.new(&{&1.name, &1})
  end

  defp political_offices_by_template_ref(%World{id: world_id}) do
    PoliticalOffice
    |> where([office], office.world_id == ^world_id)
    |> Repo.all()
    |> Repo.preload([:continent, :province, :hold])
    |> Map.new(&{political_office_template_ref(&1), &1})
  end

  defp political_office_template_ref(nil) do
    nil
  end

  defp political_office_template_ref(%PoliticalOffice{} = office) do
    target =
      case office.scope do
        "continent" -> office.continent.name
        "province" -> office.province.name
        "hold" -> office.hold.name
      end

    {office.scope, target, office.office}
  end

  defp political_office_template_ref(office_data) do
    {office_data.scope, office_data.target, office_data.office}
  end

  defp route_ref_fields do
    [
      origin_hold: :origin_hold_id,
      destination_hold: :destination_hold_id,
      origin_location: :origin_location_id,
      destination_location: :destination_location_id
    ]
  end

  defp policy_ref_fields do
    [
      continent: :continent_id,
      province: :province_id,
      hold: :hold_id,
      collecting_office: :collecting_office_id,
      currency: :currency_id
    ]
  end

  defp exemption_ref_fields do
    [
      guild: :guild_id,
      trade_route: :trade_route_id,
      continent: :continent_id,
      province: :province_id,
      hold: :hold_id
    ]
  end

  defp economic_ref_ids(refs, fields) when is_list(refs) do
    economic_ref_ids(Map.new(refs), fields)
  end

  defp economic_ref_ids(refs, fields) do
    fields
    |> Enum.filter(fn {key, _field} -> Map.has_key?(refs, key) end)
    |> Map.new(fn {key, field} -> {field, ref_id(Map.get(refs, key))} end)
  end

  defp assembly_ref_ids(refs, world_id) do
    refs = Map.new(refs)

    %{
      world_id: world_id,
      continent_id: ref_id(Map.get(refs, :continent)),
      province_id: ref_id(Map.get(refs, :province)),
      hold_id: ref_id(Map.get(refs, :hold)),
      location_id: ref_id(Map.get(refs, :location))
    }
  end

  defp water_connection_ref_ids(refs) do
    economic_ref_ids(refs,
      origin_water_body: :origin_water_body_id,
      destination_water_body: :destination_water_body_id
    )
  end

  defp trade_route_leg_ref_ids(refs) do
    economic_ref_ids(refs,
      origin_stop: :origin_stop_id,
      destination_stop: :destination_stop_id,
      water_body: :water_body_id
    )
  end

  defp venture_membership_ref_ids(refs) do
    economic_ref_ids(refs,
      household: :household_id,
      character: :character_id
    )
  end

  defp validate_commercial_venture_refs(changeset, world_id) do
    location_id = Ecto.Changeset.get_field(changeset, :home_location_id)

    validate_world_ref(
      changeset,
      :home_location_id,
      location_id,
      &location_in_world?(&1, world_id)
    )
  end

  defp validate_venture_membership_refs(changeset, world_id) do
    household_id = Ecto.Changeset.get_field(changeset, :household_id)
    character_id = Ecto.Changeset.get_field(changeset, :character_id)

    changeset
    |> validate_world_ref(
      :household_id,
      household_id,
      &household_in_world?(&1, world_id)
    )
    |> validate_world_ref(
      :character_id,
      character_id,
      &character_in_world?(&1, world_id)
    )
  end

  defp persist_venture_membership(changeset, venture_id, excluded_membership_id \\ nil) do
    Repo.transaction(fn ->
      CommercialVenture
      |> where([venture], venture.id == ^venture_id)
      |> lock("FOR UPDATE")
      |> Repo.one!()

      changeset = validate_venture_share_total(changeset, venture_id, excluded_membership_id)

      if changeset.valid? do
        result =
          if is_nil(excluded_membership_id) do
            Repo.insert(changeset)
          else
            Repo.update(changeset)
          end

        case result do
          {:ok, membership} -> membership
          {:error, invalid_changeset} -> Repo.rollback(invalid_changeset)
        end
      else
        Repo.rollback(changeset)
      end
    end)
  end

  defp validate_venture_share_total(changeset, venture_id, excluded_membership_id) do
    share = Ecto.Changeset.get_field(changeset, :share_percentage)
    status = Ecto.Changeset.get_field(changeset, :status)

    candidate_share =
      if status in [:active, :inherited] and not is_nil(share) do
        share
      else
        Decimal.new(0)
      end

    query =
      VentureMembership
      |> where(
        [membership],
        membership.commercial_venture_id == ^venture_id and
          membership.status in [:active, :inherited] and
          not is_nil(membership.share_percentage)
      )
      |> maybe_exclude_venture_membership(excluded_membership_id)

    allocated_share = Repo.aggregate(query, :sum, :share_percentage) || Decimal.new(0)

    if Decimal.gt?(Decimal.add(allocated_share, candidate_share), Decimal.new(100)) do
      Ecto.Changeset.add_error(changeset, :share_percentage, "would allocate more than 100%")
    else
      changeset
    end
  end

  defp maybe_exclude_venture_membership(query, nil) do
    query
  end

  defp maybe_exclude_venture_membership(query, membership_id) do
    where(query, [membership], membership.id != ^membership_id)
  end

  defp validate_water_body_parent(changeset, world_id) do
    parent_id = Ecto.Changeset.get_field(changeset, :parent_water_body_id)

    validate_world_ref(
      changeset,
      :parent_water_body_id,
      parent_id,
      &water_body_in_world?(&1, world_id)
    )
  end

  defp validate_water_body_cycle(changeset) do
    water_body_id = Ecto.Changeset.get_field(changeset, :id)
    parent_id = Ecto.Changeset.get_field(changeset, :parent_water_body_id)

    if water_body_id && parent_id && water_body_ancestor?(parent_id, water_body_id) do
      Ecto.Changeset.add_error(
        changeset,
        :parent_water_body_id,
        "would create a containment cycle"
      )
    else
      changeset
    end
  end

  defp validate_water_connection_refs(changeset, world_id) do
    changeset
    |> validate_world_ref(
      :origin_water_body_id,
      Ecto.Changeset.get_field(changeset, :origin_water_body_id),
      &water_body_in_world?(&1, world_id)
    )
    |> validate_world_ref(
      :destination_water_body_id,
      Ecto.Changeset.get_field(changeset, :destination_water_body_id),
      &water_body_in_world?(&1, world_id)
    )
  end

  defp validate_route_stop_location(changeset, world_id) do
    location_id = Ecto.Changeset.get_field(changeset, :location_id)
    validate_world_ref(changeset, :location_id, location_id, &location_in_world?(&1, world_id))
  end

  defp validate_trade_route_stop_position(changeset, route_id, nil) do
    final_position =
      TradeRouteStop
      |> where([stop], stop.trade_route_id == ^route_id)
      |> Repo.aggregate(:max, :position)

    expected_position = if final_position, do: final_position + 1, else: 1

    leg_count =
      TradeRouteLeg
      |> where([leg], leg.trade_route_id == ^route_id)
      |> Repo.aggregate(:count)

    complete? = final_position && final_position >= 2 && leg_count == final_position - 1

    cond do
      complete? ->
        Ecto.Changeset.add_error(
          changeset,
          :position,
          "remove the final leg before extending a completed itinerary"
        )

      Ecto.Changeset.get_field(changeset, :position) != expected_position ->
        Ecto.Changeset.add_error(changeset, :position, "must be the next itinerary position")

      true ->
        changeset
    end
  end

  defp validate_trade_route_stop_position(changeset, _route_id, stop) do
    if Ecto.Changeset.get_field(changeset, :position) == stop.position do
      changeset
    else
      Ecto.Changeset.add_error(changeset, :position, "cannot be reordered after creation")
    end
  end

  defp validate_trade_route_leg_refs(changeset, route_id, world_id) do
    origin_stop_id = Ecto.Changeset.get_field(changeset, :origin_stop_id)
    destination_stop_id = Ecto.Changeset.get_field(changeset, :destination_stop_id)
    water_body_id = Ecto.Changeset.get_field(changeset, :water_body_id)

    changeset
    |> validate_route_stop_ref(:origin_stop_id, origin_stop_id, route_id)
    |> validate_route_stop_ref(:destination_stop_id, destination_stop_id, route_id)
    |> validate_world_ref(
      :water_body_id,
      water_body_id,
      &water_body_in_world?(&1, world_id)
    )
    |> validate_leg_stop_order(origin_stop_id, destination_stop_id, route_id)
    |> validate_trade_route_leg_mode(route_id, water_body_id)
    |> validate_trade_route_leg_seasonality(route_id)
  end

  defp validate_route_stop_ref(changeset, _field, nil, _route_id) do
    changeset
  end

  defp validate_route_stop_ref(changeset, field, stop_id, route_id) do
    if trade_route_stop_in_route?(stop_id, route_id) do
      changeset
    else
      Ecto.Changeset.add_error(changeset, field, "must belong to this route")
    end
  end

  defp validate_leg_stop_order(changeset, nil, _destination_id, _route_id) do
    changeset
  end

  defp validate_leg_stop_order(changeset, _origin_id, nil, _route_id) do
    changeset
  end

  defp validate_leg_stop_order(changeset, origin_id, destination_id, route_id) do
    positions =
      TradeRouteStop
      |> where(
        [stop],
        stop.trade_route_id == ^route_id and stop.id in ^[origin_id, destination_id]
      )
      |> select([stop], {stop.id, stop.position})
      |> Repo.all()
      |> Map.new()

    if Map.get(positions, origin_id, 0) + 1 == Map.get(positions, destination_id, 0) do
      changeset
    else
      Ecto.Changeset.add_error(
        changeset,
        :destination_stop_id,
        "must immediately follow the origin stop"
      )
    end
  end

  defp validate_trade_route_leg_position(changeset, route_id, nil) do
    origin_stop_id = Ecto.Changeset.get_field(changeset, :origin_stop_id)

    origin_position =
      TradeRouteStop
      |> where([stop], stop.id == ^origin_stop_id and stop.trade_route_id == ^route_id)
      |> select([stop], stop.position)
      |> Repo.one()

    expected_position =
      TradeRouteLeg
      |> where([leg], leg.trade_route_id == ^route_id)
      |> Repo.aggregate(:max, :position)
      |> case do
        nil -> 1
        position -> position + 1
      end

    position = Ecto.Changeset.get_field(changeset, :position)

    if position == expected_position and position == origin_position do
      changeset
    else
      Ecto.Changeset.add_error(
        changeset,
        :position,
        "must continue from the final completed leg"
      )
    end
  end

  defp validate_trade_route_leg_position(changeset, _route_id, leg) do
    unchanged? =
      Ecto.Changeset.get_field(changeset, :position) == leg.position and
        Ecto.Changeset.get_field(changeset, :origin_stop_id) == leg.origin_stop_id and
        Ecto.Changeset.get_field(changeset, :destination_stop_id) == leg.destination_stop_id

    if unchanged? do
      changeset
    else
      Ecto.Changeset.add_error(changeset, :position, "route endpoints cannot be reordered")
    end
  end

  defp validate_trade_route_leg_mode(changeset, route_id, water_body_id) do
    route = Repo.get!(TradeRoute, route_id)
    mode = Ecto.Changeset.get_field(changeset, :transport_mode)

    changeset =
      if route.transport_mode != :mixed and mode != route.transport_mode do
        Ecto.Changeset.add_error(changeset, :transport_mode, "must match the route transport")
      else
        changeset
      end

    cond do
      mode in [:sea, :river] and is_nil(water_body_id) ->
        Ecto.Changeset.add_error(changeset, :water_body_id, "is required for water transport")

      mode in [:road, :trail, :caravan] and water_body_id ->
        Ecto.Changeset.add_error(
          changeset,
          :water_body_id,
          "must be empty for overland transport"
        )

      true ->
        changeset
    end
  end

  defp validate_trade_route_leg_seasonality(changeset, route_id) do
    route = Repo.get!(TradeRoute, route_id)
    seasonality = Ecto.Changeset.get_field(changeset, :seasonality)

    if route.seasonality && seasonality != route.seasonality do
      Ecto.Changeset.add_error(changeset, :seasonality, "must match the route season")
    else
      changeset
    end
  end

  defp lock_world_waters(world_id) do
    WaterBody
    |> where([water], water.world_id == ^world_id)
    |> order_by([water], asc: water.id)
    |> lock("FOR UPDATE")
    |> Repo.all()
  end

  defp lock_world_water_connections(world_id) do
    water_ids =
      WaterBody
      |> where([water], water.world_id == ^world_id)
      |> select([water], water.id)

    WaterBodyConnection
    |> where([connection], connection.origin_water_body_id in subquery(water_ids))
    |> order_by([connection], asc: connection.id)
    |> lock("FOR UPDATE")
    |> Repo.all()
  end

  defp lock_trade_route(route_id) do
    TradeRoute
    |> where([route], route.id == ^route_id)
    |> lock("FOR UPDATE")
    |> Repo.one!()
  end

  defp water_body_ancestor?(water_body_id, sought_ancestor_id) do
    cond do
      water_body_id == sought_ancestor_id ->
        true

      true ->
        case Repo.get(WaterBody, water_body_id) do
          %WaterBody{parent_water_body_id: nil} ->
            false

          %WaterBody{parent_water_body_id: parent_id} ->
            water_body_ancestor?(parent_id, sought_ancestor_id)

          nil ->
            false
        end
    end
  end

  defp refresh_world_water_paths!(%World{id: world_id} = world) do
    refresh_world_water_paths_by_id!(world_id)
    world
  end

  defp refresh_world_water_paths!(%WaterBody{world_id: world_id} = water_body) do
    refresh_world_water_paths_by_id!(world_id)
    water_body
  end

  defp refresh_world_water_paths!(%WaterBodyConnection{} = connection) do
    world_id =
      WaterBody
      |> where([water], water.id == ^connection.origin_water_body_id)
      |> select([water], water.world_id)
      |> Repo.one!()

    refresh_world_water_paths_by_id!(world_id)
    connection
  end

  defp refresh_world_water_paths_by_id!(world_id) do
    TradeRouteLeg
    |> join(:inner, [leg], route in assoc(leg, :trade_route))
    |> where(
      [leg, route],
      route.world_id == ^world_id and
        (leg.transport_mode in [:sea, :river] or not is_nil(leg.water_body_id))
    )
    |> order_by([leg], asc: leg.trade_route_id, asc: leg.position)
    |> Repo.all()
    |> Enum.each(fn leg ->
      lock_trade_route(leg.trade_route_id)
      sync_trade_route_leg_water_path!(leg)
    end)
  end

  defp refresh_route_water_paths!(route_id) do
    TradeRouteLeg
    |> where([leg], leg.trade_route_id == ^route_id)
    |> order_by([leg], asc: leg.position)
    |> Repo.all()
    |> Enum.each(&sync_trade_route_leg_water_path!/1)
  end

  defp sync_trade_route_leg_water_path!(%TradeRouteLeg{} = leg) do
    leg =
      Repo.preload(
        leg,
        [
          :trade_route,
          :water_body,
          water_traversals: :water_body,
          origin_stop: [location: :water_body],
          destination_stop: [location: :water_body]
        ],
        force: true
      )

    case water_path_for_leg(leg) do
      {:ok, path} ->
        TradeRouteLegWater
        |> where([traversal], traversal.trade_route_leg_id == ^leg.id)
        |> Repo.delete_all()

        path
        |> Enum.with_index(1)
        |> Enum.each(fn {water, position} ->
          %TradeRouteLegWater{
            trade_route_leg_id: leg.id,
            water_body_id: water.id,
            position: position
          }
          |> Repo.insert!()
        end)

        Repo.preload(leg, [water_traversals: :water_body], force: true)

      {:error, message} ->
        leg
        |> TradeRouteLeg.changeset(%{})
        |> Ecto.Changeset.add_error(:water_body_id, message)
        |> Repo.rollback()
    end
  end

  defp water_path_for_leg(%TradeRouteLeg{transport_mode: mode, water_body_id: nil})
       when mode in [:road, :trail, :caravan, :mixed] do
    {:ok, []}
  end

  defp water_path_for_leg(%TradeRouteLeg{} = leg) do
    origin_water_id = leg.origin_stop.location.water_body_id
    destination_water_id = leg.destination_stop.location.water_body_id

    cond do
      is_nil(leg.water_body_id) ->
        {:error, "is required for this waterborne leg"}

      is_nil(origin_water_id) or is_nil(destination_water_id) ->
        {:error, "requires water-linked origin and destination stops"}

      true ->
        path =
          navigable_water_path(
            origin_water_id,
            destination_water_id,
            leg.water_body_id,
            leg.trade_route.world_id,
            leg.transport_mode,
            leg.seasonality
          )

        if path do
          {:ok, path}
        else
          {:error, "is not on a navigable path between the stops"}
        end
    end
  end

  defp navigable_water_path(
         origin_id,
         destination_id,
         waypoint_id,
         world_id,
         mode,
         seasonality
       ) do
    waters =
      WaterBody
      |> where([water], water.world_id == ^world_id and water.navigability != :none)
      |> Repo.all()
      |> Map.new(&{&1.id, &1})

    connections =
      WaterBodyConnection
      |> join(:inner, [connection], origin in assoc(connection, :origin_water_body))
      |> where(
        [connection, origin],
        origin.world_id == ^world_id and connection.navigability != :none
      )
      |> Repo.all()

    adjacency = water_adjacency(connections, waters, mode, seasonality)

    with true <- water_mode_compatible?(Map.get(waters, waypoint_id), mode),
         path_to_waypoint when is_list(path_to_waypoint) <-
           breadth_first_water_path(origin_id, waypoint_id, adjacency),
         path_from_waypoint when is_list(path_from_waypoint) <-
           breadth_first_water_path(waypoint_id, destination_id, adjacency),
         path_ids = path_to_waypoint ++ Enum.drop(path_from_waypoint, 1),
         true <- length(path_ids) == MapSet.size(MapSet.new(path_ids)) do
      Enum.map(path_ids, &Map.fetch!(waters, &1))
    else
      _reason -> nil
    end
  end

  defp water_adjacency(connections, waters, mode, seasonality) do
    Enum.reduce(connections, %{}, fn connection, adjacency ->
      if connection_season_compatible?(connection.seasonality, seasonality) do
        adjacency =
          maybe_add_water_edge(
            adjacency,
            connection.origin_water_body_id,
            connection.destination_water_body_id,
            waters,
            mode
          )

        if connection.navigation_directionality == :two_way do
          maybe_add_water_edge(
            adjacency,
            connection.destination_water_body_id,
            connection.origin_water_body_id,
            waters,
            mode
          )
        else
          adjacency
        end
      else
        adjacency
      end
    end)
  end

  defp maybe_add_water_edge(adjacency, origin_id, destination_id, waters, mode) do
    if water_mode_compatible?(Map.get(waters, origin_id), mode) and
         water_mode_compatible?(Map.get(waters, destination_id), mode) do
      Map.update(adjacency, origin_id, [destination_id], &[destination_id | &1])
    else
      adjacency
    end
  end

  defp water_mode_compatible?(nil, _mode) do
    false
  end

  defp water_mode_compatible?(%WaterBody{}, :mixed) do
    true
  end

  defp water_mode_compatible?(%WaterBody{kind: kind}, :sea) do
    kind in [:ocean, :sea, :shelf_sea, :gulf, :bay, :strait, :sound, :fjord, :estuary, :channel]
  end

  defp water_mode_compatible?(%WaterBody{kind: kind}, :river) do
    kind in [:river, :estuary, :lake, :channel]
  end

  defp water_mode_compatible?(_water, _mode) do
    false
  end

  defp connection_season_compatible?(nil, _leg_seasonality) do
    true
  end

  defp connection_season_compatible?(:year_round, _leg_seasonality) do
    true
  end

  defp connection_season_compatible?(_connection_seasonality, nil) do
    true
  end

  defp connection_season_compatible?(seasonality, seasonality) do
    true
  end

  defp connection_season_compatible?(_connection_seasonality, _leg_seasonality) do
    false
  end

  defp breadth_first_water_path(origin_id, destination_id, _adjacency)
       when origin_id == destination_id do
    [origin_id]
  end

  defp breadth_first_water_path(origin_id, destination_id, adjacency) do
    queue = :queue.from_list([{origin_id, [origin_id]}])
    visit_water_path(queue, MapSet.new([origin_id]), destination_id, adjacency)
  end

  defp visit_water_path(queue, visited, destination_id, adjacency) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        nil

      {{:value, {water_id, reversed_path}}, remaining_queue} ->
        neighbors = Map.get(adjacency, water_id, []) |> Enum.sort()

        case Enum.find(neighbors, &(&1 == destination_id)) do
          nil ->
            {next_queue, next_visited} =
              Enum.reduce(neighbors, {remaining_queue, visited}, fn neighbor, {queued, seen} ->
                if MapSet.member?(seen, neighbor) do
                  {queued, seen}
                else
                  {
                    :queue.in({neighbor, [neighbor | reversed_path]}, queued),
                    MapSet.put(seen, neighbor)
                  }
                end
              end)

            visit_water_path(next_queue, next_visited, destination_id, adjacency)

          destination ->
            Enum.reverse([destination | reversed_path])
        end
    end
  end

  defp validate_route_topology!(route_id, subject) do
    route = Repo.get!(TradeRoute, route_id)

    stops =
      TradeRouteStop
      |> where([stop], stop.trade_route_id == ^route_id)
      |> order_by([stop], asc: stop.position)
      |> Repo.all()
      |> Repo.preload(location: :hold)

    legs =
      TradeRouteLeg
      |> where([leg], leg.trade_route_id == ^route_id)
      |> order_by([leg], asc: leg.position)
      |> Repo.all()

    error = route_topology_error(route, stops, legs)

    if error do
      subject
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.add_error(:base, error)
      |> Repo.rollback()
    else
      :ok
    end
  end

  defp route_topology_error(route, stops, legs) do
    stop_positions = Enum.map(stops, & &1.position)
    leg_positions = Enum.map(legs, & &1.position)
    complete? = length(stops) >= 2 and length(legs) == length(stops) - 1

    cond do
      stop_positions != expected_positions(length(stops)) ->
        "itinerary stop positions must be contiguous"

      leg_positions != expected_positions(length(legs)) ->
        "route leg positions must be contiguous"

      length(legs) > max(length(stops) - 1, 0) ->
        "route has more legs than adjacent stop pairs"

      Enum.any?(legs, &leg_misses_adjacent_stops?(&1, stops)) ->
        "every leg must join its adjacent itinerary stops"

      complete? and hd(stops).location.hold_id != route.origin_hold_id ->
        "first stop must belong to the route origin hold"

      complete? and List.last(stops).location.hold_id != route.destination_hold_id ->
        "last stop must belong to the route destination hold"

      (complete? and route.distance_km) && route_distance_mismatch?(route, legs) ->
        "route distance must equal the sum of its legs"

      true ->
        nil
    end
  end

  defp leg_misses_adjacent_stops?(leg, stops) do
    origin = Enum.at(stops, leg.position - 1)
    destination = Enum.at(stops, leg.position)

    is_nil(origin) or is_nil(destination) or leg.origin_stop_id != origin.id or
      leg.destination_stop_id != destination.id
  end

  defp expected_positions(0) do
    []
  end

  defp expected_positions(count) do
    Enum.to_list(1..count)
  end

  defp route_distance_mismatch?(route, legs) do
    total = Enum.reduce(legs, Decimal.new(0), &Decimal.add(&1.distance_km, &2))
    not Decimal.equal?(total, route.distance_km)
  end

  defp validate_trade_route_stop_deletion(stop) do
    max_position =
      TradeRouteStop
      |> where([candidate], candidate.trade_route_id == ^stop.trade_route_id)
      |> Repo.aggregate(:max, :position)

    referenced? =
      TradeRouteLeg
      |> where(
        [leg],
        leg.origin_stop_id == ^stop.id or leg.destination_stop_id == ^stop.id
      )
      |> Repo.exists?()

    changeset = Ecto.Changeset.change(stop)

    cond do
      stop.position != max_position ->
        Ecto.Changeset.add_error(changeset, :position, "only the final stop can be removed")

      referenced? ->
        Ecto.Changeset.add_error(changeset, :position, "remove the final route leg first")

      true ->
        changeset
    end
  end

  defp validate_trade_route_leg_deletion(leg) do
    max_position =
      TradeRouteLeg
      |> where([candidate], candidate.trade_route_id == ^leg.trade_route_id)
      |> Repo.aggregate(:max, :position)

    if leg.position == max_position do
      Ecto.Changeset.change(leg)
    else
      leg
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.add_error(:position, "only the final leg can be removed")
    end
  end

  defp maybe_search_water_bodies(query, search) when search in [nil, ""] do
    query
  end

  defp maybe_search_water_bodies(query, search) do
    term = "%#{String.trim(search)}%"

    where(
      query,
      [water],
      ilike(water.name, ^term) or ilike(water.description, ^term) or
        ilike(water.prevailing_conditions, ^term) or ilike(water.hazards, ^term)
    )
  end

  defp maybe_search_commercial_ventures(query, search) when search in [nil, ""] do
    query
  end

  defp maybe_search_commercial_ventures(query, search) do
    term = "%#{String.trim(search)}%"

    where(
      query,
      [venture],
      ilike(venture.name, ^term) or ilike(venture.purpose, ^term) or
        ilike(venture.description, ^term)
    )
  end

  defp maybe_search_hold_economic_profiles(query, search) when search in [nil, ""] do
    query
  end

  defp maybe_search_hold_economic_profiles(query, search) do
    term = "%#{String.trim(search)}%"

    where(
      query,
      [profile, hold, province, _continent],
      ilike(hold.name, ^term) or ilike(province.name, ^term) or
        ilike(profile.assessment_label, ^term)
    )
  end

  defp maybe_search_commodity_balances(query, search) when search in [nil, ""] do
    query
  end

  defp maybe_search_commodity_balances(query, search) do
    term = "%#{String.trim(search)}%"

    where(
      query,
      [balance, hold, province, _continent],
      ilike(hold.name, ^term) or ilike(province.name, ^term) or
        ilike(balance.commodity, ^term) or ilike(balance.category, ^term)
    )
  end

  defp maybe_search_tax_assessments(query, search) when search in [nil, ""] do
    query
  end

  defp maybe_search_tax_assessments(query, search) do
    term = "%#{String.trim(search)}%"

    where(
      query,
      [assessment, policy],
      ilike(policy.name, ^term) or ilike(assessment.assessment_period_label, ^term)
    )
  end

  defp ref_id(nil), do: nil
  defp ref_id(%{id: id}), do: id

  defp validate_assembly_refs(changeset, world_id) do
    changeset
    |> validate_world_ref(
      :continent_id,
      Ecto.Changeset.get_field(changeset, :continent_id),
      &continent_in_world?(&1, world_id)
    )
    |> validate_world_ref(
      :province_id,
      Ecto.Changeset.get_field(changeset, :province_id),
      &province_in_world?(&1, world_id)
    )
    |> validate_world_ref(
      :hold_id,
      Ecto.Changeset.get_field(changeset, :hold_id),
      &hold_in_world?(&1, world_id)
    )
    |> validate_world_ref(
      :location_id,
      Ecto.Changeset.get_field(changeset, :location_id),
      &location_in_world?(&1, world_id)
    )
  end

  defp validate_trade_route_refs(changeset, world_id) do
    origin_hold_id = Ecto.Changeset.get_field(changeset, :origin_hold_id)
    destination_hold_id = Ecto.Changeset.get_field(changeset, :destination_hold_id)

    changeset
    |> validate_world_ref(:origin_hold_id, origin_hold_id, &hold_in_world?(&1, world_id))
    |> validate_world_ref(
      :destination_hold_id,
      destination_hold_id,
      &hold_in_world?(&1, world_id)
    )
    |> validate_location_endpoint(:origin_location_id, origin_hold_id)
    |> validate_location_endpoint(:destination_location_id, destination_hold_id)
  end

  defp validate_currency_ref(changeset, world_id) do
    id = Ecto.Changeset.get_field(changeset, :currency_id)
    validate_world_ref(changeset, :currency_id, id, &currency_in_world?(&1, world_id))
  end

  defp validate_tax_policy_refs(changeset, world_id) do
    changeset
    |> validate_world_ref(
      :continent_id,
      Ecto.Changeset.get_field(changeset, :continent_id),
      &continent_in_world?(&1, world_id)
    )
    |> validate_world_ref(
      :province_id,
      Ecto.Changeset.get_field(changeset, :province_id),
      &province_in_world?(&1, world_id)
    )
    |> validate_world_ref(
      :hold_id,
      Ecto.Changeset.get_field(changeset, :hold_id),
      &hold_in_world?(&1, world_id)
    )
    |> validate_world_ref(
      :collecting_office_id,
      Ecto.Changeset.get_field(changeset, :collecting_office_id),
      &office_in_world?(&1, world_id)
    )
    |> validate_currency_ref(world_id)
  end

  defp validate_tax_exemption_refs(changeset, world_id) do
    checks = [
      {:guild_id, &guild_in_world?(&1, world_id)},
      {:trade_route_id, &trade_route_in_world?(&1, world_id)},
      {:continent_id, &continent_in_world?(&1, world_id)},
      {:province_id, &province_in_world?(&1, world_id)},
      {:hold_id, &hold_in_world?(&1, world_id)}
    ]

    Enum.reduce(checks, changeset, fn {field, validator}, acc ->
      validate_world_ref(acc, field, Ecto.Changeset.get_field(acc, field), validator)
    end)
  end

  defp validate_world_ref(changeset, _field, nil, _validator), do: changeset

  defp validate_world_ref(changeset, field, id, validator) do
    if validator.(id),
      do: changeset,
      else: Ecto.Changeset.add_error(changeset, field, "does not belong to this world")
  end

  defp validate_location_endpoint(changeset, field, hold_id) do
    location_id = Ecto.Changeset.get_field(changeset, field)

    cond do
      is_nil(location_id) ->
        changeset

      is_nil(hold_id) ->
        Ecto.Changeset.add_error(changeset, field, "requires an endpoint hold")

      location_in_hold?(location_id, hold_id) ->
        changeset

      true ->
        Ecto.Changeset.add_error(changeset, field, "must belong to its endpoint hold")
    end
  end

  defp persist_tax_revenue_share(policy, share, attrs, office) do
    Repo.transaction(fn ->
      lock_tax_policy!(policy.id)

      changeset =
        share
        |> TaxRevenueShare.changeset(attrs, %{
          tax_policy_id: policy.id,
          political_office_id: office.id
        })
        |> validate_world_ref(
          :political_office_id,
          office.id,
          &office_in_world?(&1, policy.world_id)
        )
        |> validate_revenue_allocation(policy.id, share.id)

      case Repo.insert_or_update(changeset) do
        {:ok, saved_share} -> saved_share
        {:error, failed_changeset} -> Repo.rollback(failed_changeset)
      end
    end)
  end

  defp validate_revenue_allocation(changeset, policy_id, share_id) do
    query =
      TaxRevenueShare
      |> where([share], share.tax_policy_id == ^policy_id)
      |> then(fn query ->
        if share_id, do: where(query, [share], share.id != ^share_id), else: query
      end)
      |> select([share], sum(share.percentage))

    allocated = Repo.one(query) || Decimal.new(0)
    percentage = Ecto.Changeset.get_field(changeset, :percentage)

    if percentage && Decimal.gt?(Decimal.add(allocated, percentage), Decimal.new(100)) do
      Ecto.Changeset.add_error(changeset, :percentage, "would allocate more than 100%")
    else
      changeset
    end
  end

  defp lock_tax_policy!(policy_id) do
    TaxPolicy |> where([policy], policy.id == ^policy_id) |> lock("FOR UPDATE") |> Repo.one!()
  end

  defp hold_in_world?(id, world_id) do
    Hold
    |> join(:inner, [hold], province in assoc(hold, :province))
    |> join(:inner, [_hold, province], continent in assoc(province, :continent))
    |> where([hold, _province, continent], hold.id == ^id and continent.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp location_in_hold?(id, hold_id) do
    Location
    |> where([location], location.id == ^id and location.hold_id == ^hold_id)
    |> Repo.exists?()
  end

  defp continent_in_world?(id, world_id) do
    Continent
    |> where([continent], continent.id == ^id and continent.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp province_in_world?(id, world_id) do
    Province
    |> join(:inner, [province], continent in assoc(province, :continent))
    |> where([province, continent], province.id == ^id and continent.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp currency_in_world?(id, world_id) do
    ContinentCurrency
    |> join(:inner, [currency], continent in assoc(currency, :continent))
    |> where([currency, continent], currency.id == ^id and continent.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp office_in_world?(id, world_id) do
    PoliticalOffice
    |> where([office], office.id == ^id and office.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp guild_in_world?(id, world_id) do
    Guild |> where([guild], guild.id == ^id and guild.world_id == ^world_id) |> Repo.exists?()
  end

  defp household_in_world?(id, world_id) do
    Household
    |> where([household], household.id == ^id and household.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp character_in_world?(id, world_id) do
    Character
    |> where([character], character.id == ^id and character.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp trade_route_in_world?(id, world_id) do
    TradeRoute
    |> where([route], route.id == ^id and route.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp water_body_in_world?(id, world_id) do
    WaterBody
    |> where([water], water.id == ^id and water.world_id == ^world_id)
    |> Repo.exists?()
  end

  defp trade_route_stop_in_route?(id, route_id) do
    TradeRouteStop
    |> where([stop], stop.id == ^id and stop.trade_route_id == ^route_id)
    |> Repo.exists?()
  end

  defp province_and_water_share_world?(%Province{id: province_id}, water_body_id) do
    WaterBody
    |> join(:inner, [water], continent in Continent, on: continent.world_id == water.world_id)
    |> join(:inner, [_water, continent], province in Province,
      on: province.continent_id == continent.id
    )
    |> where(
      [water, _continent, province],
      water.id == ^water_body_id and province.id == ^province_id
    )
    |> Repo.exists?()
  end

  defp province_water_link_in_use?(link) do
    Location
    |> join(:inner, [location], hold in assoc(location, :hold))
    |> where(
      [location, hold],
      hold.province_id == ^link.province_id and location.water_body_id == ^link.water_body_id
    )
    |> Repo.exists?()
  end

  defp lock_province_water_link(link_id) do
    ProvinceWaterBody
    |> where([link], link.id == ^link_id)
    |> lock("FOR UPDATE")
    |> Repo.one!()
  end

  defp lock_location_province_water_link(location_id, water_body_id) do
    province_id =
      Location
      |> join(:inner, [location], hold in assoc(location, :hold))
      |> where([location, _hold], location.id == ^location_id)
      |> select([_location, hold], hold.province_id)
      |> Repo.one()

    ProvinceWaterBody
    |> where(
      [link],
      link.province_id == ^province_id and link.water_body_id == ^water_body_id
    )
    |> lock("FOR UPDATE")
    |> Repo.one()
    |> then(&(not is_nil(&1)))
  end

  defp household_preloads do
    [
      home_location: [:hold],
      memberships: [:character],
      landholdings: [:hold, :location],
      venture_memberships: [:commercial_venture]
    ]
  end

  defp commercial_venture_preloads do
    [
      home_location: [:hold],
      memberships: [:household, :character],
      trade_route_links: [:trade_route]
    ]
  end

  defp maybe_search_households(query, search) when search in [nil, ""], do: query

  defp maybe_search_households(query, search) do
    pattern = "%#{String.trim(search)}%"

    where(
      query,
      [household],
      ilike(household.name, ^pattern) or ilike(household.description, ^pattern)
    )
  end

  defp maybe_search_character_relationships(query, search) when search in [nil, ""], do: query

  defp maybe_search_character_relationships(query, search) do
    pattern = "%#{String.trim(search)}%"

    where(
      query,
      [relationship, character_a, character_b],
      ilike(character_a.name, ^pattern) or ilike(character_b.name, ^pattern) or
        ilike(relationship.description, ^pattern)
    )
  end

  defp maybe_search_landholdings(query, search) when search in [nil, ""], do: query

  defp maybe_search_landholdings(query, search) do
    pattern = "%#{String.trim(search)}%"

    where(
      query,
      [holding, household],
      ilike(holding.name, ^pattern) or ilike(holding.description, ^pattern) or
        ilike(household.name, ^pattern)
    )
  end

  defp maybe_add_household_head(multi, nil), do: multi

  defp maybe_add_household_head(multi, character) do
    Ecto.Multi.run(multi, :head_membership, fn repo, %{household: household} ->
      %HouseholdMembership{household_id: household.id, character_id: character.id}
      |> HouseholdMembership.changeset(%{role: :head, status: :active, is_primary: true})
      |> repo.insert()
    end)
  end

  defp validate_optional_location_world(nil, _world_id, _kind), do: :ok

  defp validate_optional_location_world(%Location{id: location_id}, world_id, kind) do
    if location_in_world?(location_id, world_id) do
      :ok
    else
      case kind do
        :home_location -> {:error, :home_location_outside_world}
        :landholding -> {:error, :location_outside_world}
      end
    end
  end

  defp validate_optional_hold_world(nil, _world_id), do: :ok

  defp validate_optional_hold_world(%Hold{id: hold_id}, world_id) do
    if hold_in_world?(hold_id, world_id), do: :ok, else: {:error, :hold_outside_world}
  end

  defp validate_optional_character_world(nil, _world_id), do: :ok

  defp validate_optional_character_world(%Character{} = character, world_id) do
    validate_character_world(character, world_id)
  end

  defp validate_character_world(%Character{world_id: world_id}, world_id), do: :ok
  defp validate_character_world(%Character{}, _world_id), do: {:error, :character_outside_world}

  defp validate_distinct_characters(%Character{id: id}, %Character{id: id}) do
    {:error, :relationship_requires_two_characters}
  end

  defp validate_distinct_characters(%Character{}, %Character{}), do: :ok

  defp canonical_relationship(character_a, character_b, attrs) do
    attrs = Map.new(attrs, fn {key, value} -> {to_string(key), value} end)

    if character_a.id < character_b.id do
      {character_a, character_b, attrs}
    else
      swapped_attrs =
        attrs
        |> Map.put("character_a_role", Map.get(attrs, "character_b_role"))
        |> Map.put("character_b_role", Map.get(attrs, "character_a_role"))

      {character_b, character_a, swapped_attrs}
    end
  end

  defp default_relationship_roles(attrs) do
    attrs = Map.new(attrs, fn {key, value} -> {to_string(key), value} end)

    {default_a, default_b} =
      case attrs["relationship_type"] do
        type when type in [:parent_child, "parent_child"] ->
          {"parent", "child"}

        type when type in [:siblings, "siblings"] ->
          {"sibling", "sibling"}

        type when type in [:spouses, "spouses"] ->
          {"spouse", "spouse"}

        type when type in [:partners, "partners"] ->
          {"partner", "partner"}

        type when type in [:betrothed, "betrothed"] ->
          {"betrothed", "betrothed"}

        type when type in [:foster_parent_child, "foster_parent_child"] ->
          {"foster parent", "foster child"}

        type when type in [:foster_siblings, "foster_siblings"] ->
          {"foster sibling", "foster sibling"}

        type when type in [:guardian_ward, "guardian_ward"] ->
          {"guardian", "ward"}

        _type ->
          {nil, nil}
      end

    attrs
    |> put_default_role("character_a_role", default_a)
    |> put_default_role("character_b_role", default_b)
  end

  defp put_default_role(attrs, key, default) do
    if attrs[key] in [nil, ""] do
      Map.put(attrs, key, default)
    else
      attrs
    end
  end

  defp validate_single_landholding_scope(nil, nil) do
    {:error, :landholding_requires_one_geographic_scope}
  end

  defp validate_single_landholding_scope(%Hold{}, %Location{}) do
    {:error, :landholding_requires_one_geographic_scope}
  end

  defp validate_single_landholding_scope(%Hold{}, nil), do: :ok
  defp validate_single_landholding_scope(nil, %Location{}), do: :ok

  defp location_in_world?(id, world_id) do
    Location
    |> join(:inner, [location], hold in assoc(location, :hold))
    |> join(:inner, [_location, hold], province in assoc(hold, :province))
    |> join(:inner, [_location, _hold, province], continent in assoc(province, :continent))
    |> where(
      [location, _hold, _province, continent],
      location.id == ^id and continent.world_id == ^world_id
    )
    |> Repo.exists?()
  end

  defp sync_legacy_character_membership(%Character{guild_id: nil} = character) do
    GuildMembership
    |> where(
      [membership],
      membership.character_id == ^character.id and membership.is_primary
    )
    |> Repo.delete_all()

    ensure_primary_membership(character.id)
    sync_character_primary_guild(character.id)
    Repo.get!(Character, character.id)
  end

  defp sync_legacy_character_membership(%Character{} = character) do
    clear_primary_membership(character.id)

    case Repo.get_by(GuildMembership,
           guild_id: character.guild_id,
           character_id: character.id
         ) do
      nil ->
        %GuildMembership{guild_id: character.guild_id, character_id: character.id}
        |> GuildMembership.changeset(%{is_primary: true, status: :active})
        |> Repo.insert()
        |> unwrap_transaction!()

      membership ->
        membership
        |> GuildMembership.changeset(%{is_primary: true, status: :active})
        |> Repo.update()
        |> unwrap_transaction!()
    end

    sync_character_primary_guild(character.id)
    Repo.get!(Character, character.id)
  end

  defp default_first_membership_to_primary(changeset, character_id) do
    membership_exists? =
      Repo.exists?(
        from membership in GuildMembership, where: membership.character_id == ^character_id
      )

    if membership_exists? or Ecto.Changeset.get_field(changeset, :status) != :active do
      changeset
    else
      Ecto.Changeset.put_change(changeset, :is_primary, true)
    end
  end

  defp clear_primary_membership(character_id, except_id \\ nil) do
    query =
      from membership in GuildMembership,
        where: membership.character_id == ^character_id and membership.is_primary

    query =
      if except_id do
        where(query, [membership], membership.id != ^except_id)
      else
        query
      end

    Repo.update_all(query, set: [is_primary: false])
  end

  defp ensure_primary_membership(character_id) do
    primary_exists? =
      Repo.exists?(
        from membership in GuildMembership,
          where: membership.character_id == ^character_id and membership.is_primary
      )

    unless primary_exists? do
      membership =
        GuildMembership
        |> where([membership], membership.character_id == ^character_id)
        |> where([membership], membership.status == :active)
        |> order_by([membership], asc: membership.inserted_at)
        |> first()
        |> Repo.one()

      if membership do
        membership
        |> Ecto.Changeset.change(is_primary: true)
        |> Repo.update()
        |> unwrap_transaction!()
      end
    end
  end

  defp sync_character_primary_guild(character_id) do
    guild_id =
      GuildMembership
      |> where([membership], membership.character_id == ^character_id)
      |> where([membership], membership.is_primary)
      |> select([membership], membership.guild_id)
      |> Repo.one()

    Character
    |> where([character], character.id == ^character_id)
    |> Repo.update_all(set: [guild_id: guild_id])
  end

  defp sync_guild_leader(guild_id) do
    leader_name =
      GuildMembership
      |> join(:inner, [membership], character in assoc(membership, :character))
      |> where([membership], membership.guild_id == ^guild_id)
      |> where([membership], membership.role == :leader and membership.status == :active)
      |> order_by([membership], asc: membership.inserted_at)
      |> select([_membership, character], character.name)
      |> first()
      |> Repo.one()

    Guild
    |> where([guild], guild.id == ^guild_id)
    |> Repo.update_all(set: [leader: leader_name])
  end

  defp unwrap_transaction!({:ok, record}) do
    record
  end

  defp unwrap_transaction!({:error, reason}) do
    Repo.rollback(reason)
  end
end
