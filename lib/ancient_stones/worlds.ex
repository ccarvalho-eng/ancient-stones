defmodule AncientStones.Worlds do
  @moduledoc """
  Geography workspace operations for worlds, regions, holds, location types,
  and locations.
  """

  import Ecto.Query

  alias AncientStones.Galaxies
  alias AncientStones.Repo
  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.CalendarMonth
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CharacterInventoryCategory
  alias AncientStones.Worlds.CharacterInventoryItem
  alias AncientStones.Worlds.CharacterOccupation
  alias AncientStones.Worlds.CharacterSkill
  alias AncientStones.Worlds.CharacterSpellbookEntry
  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.CivilizationLocation
  alias AncientStones.Worlds.CivilizationRace
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.CreatureLocation
  alias AncientStones.Worlds.CreatureType
  alias AncientStones.Worlds.Document
  alias AncientStones.Worlds.Effect
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.GuildInfluence
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.HoldCommerceEntry
  alias AncientStones.Worlds.Item
  alias AncientStones.Worlds.ItemEffect
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.Occupation
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Province
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.RaceTrait
  alias AncientStones.Worlds.Relationship
  alias AncientStones.Worlds.Skill
  alias AncientStones.Worlds.SkillLevel
  alias AncientStones.Worlds.SkillTree
  alias AncientStones.Worlds.SkillTreePerk
  alias AncientStones.Worlds.Spell
  alias AncientStones.Templates
  alias AncientStones.Worlds.Timeline
  alias AncientStones.Worlds.TimelineEra
  alias AncientStones.Worlds.World

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
    |> Repo.preload(:galaxy)
  end

  @doc "Loads a world with the geography associations needed by the dashboard."
  def get_world_dashboard!(id) do
    World
    |> Repo.get!(id)
    |> Repo.preload(
      characters: [
        :race,
        :guild,
        :home_location,
        inventory_categories: [],
        inventory_items: [:item, :inventory_category],
        character_occupations: [:occupation],
        character_skills: [:skill],
        spellbook_entries: [:spell]
      ],
      civilizations: [
        :timeline_era,
        civilization_locations: [:location],
        civilization_races: [:race]
      ],
      continents: [
        calendars: [:months],
        provinces: [
          political_offices: [:character],
          holds: [
            :capital_location,
            :commerce_entries,
            political_offices: [:character],
            locations: [
              :location_type,
              creature_locations: [creature: [:creature_type]],
              child_locations: [:location_type]
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
      guilds: [guild_influences: [:god, :character]],
      effects: [],
      items: [item_effects: [:effect]],
      location_types: [:children],
      occupations: [],
      political_offices: [:character, :province, :hold],
      races: [:traits],
      relationships: [
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
      timelines: [:eras]
    )
  end

  def change_world(%World{} = world, attrs \\ %{}) do
    World.changeset(world, attrs)
  end

  def change_new_world(attrs \\ %{}) do
    %World{}
    |> World.changeset(attrs)
  end

  def create_world(attrs) do
    %World{}
    |> World.changeset(attrs)
    |> Repo.insert()
  end

  def create_world(attrs, refs) do
    %World{}
    |> World.changeset(attrs)
    |> put_optional_ref(:galaxy_id, refs[:galaxy])
    |> Repo.insert()
  end

  @doc "Deletes a world and its geography graph in dependency order."
  def delete_world(%World{id: world_id} = world) do
    Repo.transaction(fn ->
      continent_ids = continent_ids_for_world(world_id)
      province_ids = province_ids_for_continents(continent_ids)
      hold_ids = hold_ids_for_provinces(province_ids)

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

  def create_timeline(%World{id: world_id}, attrs) do
    %Timeline{world_id: world_id}
    |> Timeline.changeset(attrs)
    |> Repo.insert()
  end

  def get_timeline!(id) do
    Timeline
    |> Repo.get!(id)
    |> Repo.preload(:eras)
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
    |> Repo.preload(:timeline)
  end

  def delete_timeline_era(%TimelineEra{} = timeline_era) do
    Repo.delete(timeline_era)
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
    Repo.transaction(fn ->
      province_ids = province_ids_for_continents([continent_id])
      hold_ids = hold_ids_for_provinces(province_ids)

      delete_locations_for_holds(hold_ids)
      delete_holds_by_ids(hold_ids)
      delete_provinces_by_ids(province_ids)

      continent
      |> Repo.delete()
      |> unwrap_transaction!()
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

  @doc "Deletes a province and all nested holds and locations."
  def delete_province(%Province{id: province_id} = province) do
    Repo.transaction(fn ->
      hold_ids = hold_ids_for_provinces([province_id])

      delete_locations_for_holds(hold_ids)
      delete_holds_by_ids(hold_ids)

      province
      |> Repo.delete()
      |> unwrap_transaction!()
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

  @doc "Deletes a hold and all locations inside it."
  def delete_hold(%Hold{id: hold_id} = hold) do
    Repo.transaction(fn ->
      delete_locations_for_holds([hold_id])

      hold
      |> Repo.delete()
      |> unwrap_transaction!()
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
    |> Repo.preload(guild_influences: [:god, :character])
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

  def create_relationship(%World{id: world_id}, attrs, refs) do
    %Relationship{world_id: world_id}
    |> Relationship.changeset(attrs)
    |> put_relationship_refs(refs)
    |> Repo.insert()
  end

  def get_relationship!(id) do
    Relationship
    |> Repo.get!(id)
    |> Repo.preload(relationship_preloads())
  end

  def update_relationship(%Relationship{} = relationship, attrs, refs) do
    relationship
    |> Relationship.changeset(attrs)
    |> clear_relationship_refs()
    |> put_relationship_refs(refs)
    |> Repo.update()
  end

  def delete_relationship(%Relationship{} = relationship) do
    Repo.delete(relationship)
  end

  def list_characters(%World{id: world_id}) do
    Character
    |> where([character], character.world_id == ^world_id)
    |> order_by([character], asc: character.name)
    |> Repo.all()
    |> Repo.preload([
      :race,
      :guild,
      :home_location,
      character_occupations: [:occupation],
      character_skills: [:skill]
    ])
  end

  def get_character!(id) do
    Character
    |> Repo.get!(id)
    |> Repo.preload([
      :race,
      :guild,
      :home_location,
      character_occupations: [:occupation],
      character_skills: [:skill]
    ])
  end

  def create_character(%World{id: world_id}, attrs, refs \\ %{}) do
    Repo.transaction(fn ->
      character =
        %Character{world_id: world_id}
        |> Character.changeset(attrs)
        |> put_optional_ref(:race_id, refs[:race])
        |> put_optional_ref(:guild_id, refs[:guild])
        |> put_optional_ref(:home_location_id, refs[:home_location])
        |> Repo.insert()
        |> unwrap_transaction!()

      if occupation = refs[:occupation] do
        unwrap_transaction!(create_character_occupation(character, occupation, %{primary: true}))
      end

      if skill = refs[:skill] do
        unwrap_transaction!(create_character_skill(character, skill, %{}))
      end

      character
    end)
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

  def create_item(%World{id: world_id}, attrs) do
    %Item{world_id: world_id}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  def get_item!(id) do
    Item
    |> Repo.get!(id)
    |> Repo.preload(item_effects: [:effect])
  end

  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
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
  def delete_character(%Character{} = character) do
    Repo.delete(character)
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
    |> put_optional_ref(:province_id, refs[:province])
    |> put_optional_ref(:hold_id, refs[:hold])
    |> put_optional_ref(:character_id, refs[:character])
    |> Repo.insert()
  end

  def get_political_office!(id) do
    PoliticalOffice
    |> Repo.get!(id)
    |> Repo.preload([:character, :province, :hold])
  end

  def update_political_office(%PoliticalOffice{} = political_office, attrs, refs \\ %{}) do
    political_office
    |> PoliticalOffice.changeset(attrs)
    |> put_ref(:character_id, refs[:character])
    |> Repo.update()
  end

  def delete_political_office(%PoliticalOffice{} = political_office) do
    Repo.delete(political_office)
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

  defp put_document_refs(changeset, refs) do
    changeset
    |> put_ref(:author_character_id, refs[:author_character])
    |> put_ref(:location_id, refs[:location])
    |> put_ref(:guild_id, refs[:guild])
    |> put_ref(:god_id, refs[:god])
    |> put_ref(:race_id, refs[:race])
    |> put_ref(:civilization_id, refs[:civilization])
  end

  defp put_relationship_refs(changeset, refs) do
    changeset
    |> put_relationship_endpoint(:source, refs[:source])
    |> put_relationship_endpoint(:target, refs[:target])
  end

  defp put_relationship_endpoint(changeset, _side, nil) do
    changeset
  end

  defp put_relationship_endpoint(changeset, _side, {_kind, nil}) do
    changeset
  end

  defp put_relationship_endpoint(changeset, side, {kind, %{id: id}})
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
    Ecto.Changeset.put_change(changeset, relationship_field(side, kind), id)
  end

  defp clear_relationship_refs(changeset) do
    Enum.reduce(relationship_ref_fields(), changeset, fn field, changeset ->
      Ecto.Changeset.put_change(changeset, field, nil)
    end)
  end

  defp relationship_field(side, kind) do
    :"#{side}_#{kind}_id"
  end

  defp relationship_ref_fields do
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
      relationship_field(side, kind)
    end
  end

  defp relationship_preloads do
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

  def create_race(%World{id: world_id}, attrs) do
    %Race{world_id: world_id}
    |> Race.changeset(attrs)
    |> Repo.insert()
  end

  def create_race_trait(%Race{id: race_id}, attrs) do
    %RaceTrait{race_id: race_id}
    |> RaceTrait.changeset(attrs)
    |> Repo.insert()
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
    Repo.transaction(fn ->
      location_type_ids = location_type_ids_with_descendants(location_type)

      Location
      |> where([location], location.location_type_id in ^location_type_ids)
      |> select([location], location.id)
      |> Repo.all()
      |> clear_capitals_for_locations()

      Location
      |> where([location], location.location_type_id in ^location_type_ids)
      |> Repo.delete_all()

      LocationType
      |> where([location_type], location_type.id in ^location_type_ids)
      |> Repo.delete_all()

      location_type
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
    Repo.transaction(fn ->
      location_ids = location_ids_with_descendants(location)

      clear_capitals_for_locations(location_ids)

      Location
      |> where([location], location.id in ^location_ids)
      |> Repo.delete_all()

      location
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
    |> Map.take([:name, :description])
    |> Map.merge(attrs)
  end

  defp normalize_world_attrs(attrs) do
    %{}
    |> maybe_put_attr(:name, attrs[:name] || attrs["name"])
    |> maybe_put_attr(:description, attrs[:description] || attrs["description"])
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

    build_template_creatures!(
      world,
      Map.get(template_data, :creatures, []),
      creature_type_by_name
    )

    god_by_name = build_template_gods!(world, Map.get(template_data, :gods, []))
    build_template_spells!(world, Map.get(template_data, :spells, []))
    effect_by_name = build_template_effects!(world, Map.get(template_data, :effects, []))

    item_by_name =
      build_template_items!(world, Map.get(template_data, :items, []), effect_by_name)

    skill_tree_by_name =
      build_template_skill_trees!(world, Map.get(template_data, :skill_trees, []))

    build_template_skills!(world, Map.get(template_data, :skills, []), skill_tree_by_name)

    occupation_by_name =
      build_template_occupations!(world, Map.get(template_data, :occupations, []))

    guild_by_name =
      build_template_guilds!(world, Map.get(template_data, :guilds, []), god_by_name)

    era_by_name = build_template_timelines!(world, Map.get(template_data, :timelines, []))
    race_by_name = build_template_races!(world, Map.get(template_data, :races, []))

    civilization_by_name =
      build_template_civilizations!(
        world,
        Map.get(template_data, :civilizations, []),
        era_by_name
      )

    build_template_continents!(world, continents, type_by_name)

    character_by_name =
      build_template_characters!(
        world,
        Map.get(template_data, :characters, []),
        race_by_name,
        guild_by_name
      )

    build_template_political_offices!(
      world,
      Map.get(template_data, :political_offices, []),
      character_by_name
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

    build_template_relationships!(
      world,
      Map.get(template_data, :relationships, []),
      template_refs
    )

    get_world!(world.id)
  end

  defp build_template_world!(world, %{continents: continents} = template_data) do
    creature_type_by_name =
      build_template_creature_types!(world, Map.get(template_data, :creature_types, []))

    build_template_creatures!(
      world,
      Map.get(template_data, :creatures, []),
      creature_type_by_name
    )

    god_by_name = build_template_gods!(world, Map.get(template_data, :gods, []))
    build_template_spells!(world, Map.get(template_data, :spells, []))
    effect_by_name = build_template_effects!(world, Map.get(template_data, :effects, []))

    item_by_name =
      build_template_items!(world, Map.get(template_data, :items, []), effect_by_name)

    skill_tree_by_name =
      build_template_skill_trees!(world, Map.get(template_data, :skill_trees, []))

    build_template_skills!(world, Map.get(template_data, :skills, []), skill_tree_by_name)

    occupation_by_name =
      build_template_occupations!(world, Map.get(template_data, :occupations, []))

    guild_by_name =
      build_template_guilds!(world, Map.get(template_data, :guilds, []), god_by_name)

    era_by_name = build_template_timelines!(world, Map.get(template_data, :timelines, []))
    race_by_name = build_template_races!(world, Map.get(template_data, :races, []))

    civilization_by_name =
      build_template_civilizations!(
        world,
        Map.get(template_data, :civilizations, []),
        era_by_name
      )

    build_template_continents!(world, continents, %{})

    character_by_name =
      build_template_characters!(
        world,
        Map.get(template_data, :characters, []),
        race_by_name,
        guild_by_name
      )

    build_template_political_offices!(
      world,
      Map.get(template_data, :political_offices, []),
      character_by_name
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

    build_template_relationships!(
      world,
      Map.get(template_data, :relationships, []),
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
        |> create_race(race_data)
        |> unwrap_transaction!()

      build_template_race_traits!(race, Map.get(race_data, :traits, []))

      Map.put(acc, race.name, race)
    end)
  end

  defp build_template_race_traits!(race, traits) do
    for trait_data <- traits do
      race
      |> create_race_trait(trait_data)
      |> unwrap_transaction!()
    end
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

      timeline_data
      |> Map.get(:eras, [])
      |> Enum.reduce(acc, fn era_data, era_acc ->
        era =
          timeline
          |> create_timeline_era(era_data)
          |> unwrap_transaction!()

        Map.put(era_acc, era.name, era)
      end)
    end)
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
    for creature_data <- creatures do
      creature_type = Map.get(creature_type_by_name, creature_data[:type])

      world
      |> create_creature(creature_data, creature_type: creature_type)
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
    for skill_data <- skills do
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

      skill
    end
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

  defp build_template_characters!(world, characters, race_by_name, guild_by_name) do
    location_by_name = locations_by_name(world)

    Enum.reduce(characters, %{}, fn character_data, acc ->
      refs = %{
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
        occupation_name <- Map.get(character_data, :occupations, []) do
      character = Map.fetch!(character_by_name, character_data.name)
      occupation = Map.fetch!(occupation_by_name, occupation_name)

      character
      |> create_character_occupation(occupation, %{
        primary: primary_occupation?(character_data, occupation_name)
      })
      |> unwrap_transaction!()
    end
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

  defp build_template_relationships!(world, relationships, template_refs) do
    for relationship_data <- relationships do
      refs = %{
        source: template_endpoint(template_refs, relationship_data[:source]),
        target: template_endpoint(template_refs, relationship_data[:target])
      }

      world
      |> create_relationship(relationship_data, refs)
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
    province_by_name = provinces_by_name(world)
    hold_by_name = holds_by_name(world)

    for office_data <- political_offices do
      refs = %{
        province: Map.get(province_by_name, office_data[:province]),
        hold: Map.get(hold_by_name, office_data[:hold]),
        character: Map.get(character_by_name, office_data[:character])
      }

      world
      |> create_political_office(office_data, refs)
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

    Location
    |> where([location], location.hold_id in ^hold_ids)
    |> Repo.all()
    |> Map.new(&{&1.name, &1})
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

      build_template_holds!(province, Map.get(province_data, :holds, []), type_by_name)
    end
  end

  defp build_template_holds!(province, holds, type_by_name) do
    for hold_data <- holds do
      hold =
        province
        |> create_hold(hold_data)
        |> unwrap_transaction!()

      build_template_hold_commerce_entries!(hold, Map.get(hold_data, :commerce_entries, []))

      location_by_name =
        build_template_locations!(hold, Map.get(hold_data, :locations, []), type_by_name)

      if capital_name = hold_data[:capital] do
        capital = Map.fetch!(location_by_name, capital_name)

        hold
        |> set_hold_capital(capital)
        |> unwrap_transaction!()
      end
    end
  end

  defp build_template_hold_commerce_entries!(hold, commerce_entries) do
    for commerce_data <- commerce_entries do
      hold
      |> create_hold_commerce_entry(commerce_data)
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

  defp unwrap_transaction!({:ok, record}) do
    record
  end

  defp unwrap_transaction!({:error, reason}) do
    Repo.rollback(reason)
  end
end
