defmodule AncientStones.WorldExports.WorldGuideDetails do
  import Ecto.Query

  alias AncientStones.Maps.{MapDocument, MapItem}
  alias AncientStones.Repo
  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.Document
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.Item
  alias AncientStones.Worlds.Location
  alias AncientStones.Worlds.LoreConnection
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.Skill
  alias AncientStones.Worlds.SkillTree
  alias AncientStones.Worlds.Spell
  alias AncientStones.Worlds.Timeline

  def load(world_id) do
    %{
      locations: locations(world_id),
      characters: characters(world_id),
      guilds: guilds(world_id),
      civilizations: civilizations(world_id),
      races: races(world_id),
      gods: gods(world_id),
      documents: documents(world_id),
      connections: connections(world_id),
      maps: maps(world_id),
      skill_trees: skill_trees(world_id),
      skills: skills(world_id),
      spells: spells(world_id),
      items: items(world_id),
      creatures: creatures(world_id),
      calendars: calendars(world_id),
      timelines: timelines(world_id)
    }
  end

  defp locations(world_id) do
    Location
    |> join(:inner, [location], hold in assoc(location, :hold))
    |> join(:inner, [_location, hold], province in assoc(hold, :province))
    |> join(:inner, [_location, _hold, province], continent in assoc(province, :continent))
    |> where([_location, _hold, _province, continent], continent.world_id == ^world_id)
    |> order_by([location], asc: location.name)
    |> Repo.all()
    |> Repo.preload([
      :location_type,
      hold: [province: :continent],
      character_locations: [character: [character_occupations: :occupation]]
    ])
    |> Enum.map(&location_card/1)
  end

  defp characters(world_id) do
    Character
    |> world_records(world_id)
    |> Repo.preload([
      :race,
      :character_role,
      :home_location,
      character_locations: :location,
      character_occupations: :occupation,
      guild_memberships: :guild,
      character_skills: :skill,
      spellbook_entries: :spell,
      inventory_items: [:item, :inventory_category]
    ])
    |> Enum.map(&character_card/1)
  end

  defp guilds(world_id) do
    Guild
    |> world_records(world_id)
    |> Repo.preload(guild_memberships: :character, guild_influences: [:god, :character])
    |> Enum.map(&guild_card/1)
  end

  defp civilizations(world_id) do
    Civilization
    |> world_records(world_id)
    |> Repo.preload(civilization_locations: :location, civilization_races: :race)
    |> Enum.map(&civilization_card/1)
  end

  defp races(world_id) do
    Race
    |> world_records(world_id)
    |> Repo.preload(:traits)
    |> Enum.map(fn race ->
      card(race)
      |> Map.put(:traits, Enum.map(race.traits, &record(&1.name, &1.category, &1.description)))
    end)
  end

  defp gods(world_id) do
    God
    |> world_records(world_id)
    |> Enum.map(fn god ->
      card(god)
      |> Map.merge(%{pantheon: god.pantheon, domain: god.domain})
    end)
  end

  defp documents(world_id) do
    Document
    |> world_records(world_id, :title)
    |> Repo.preload([
      :author_character,
      :location,
      :guild,
      :god,
      :race,
      :civilization
    ])
    |> Enum.map(fn document ->
      %{
        name: document.title,
        kind: document.kind,
        source: document.source,
        summary: document.summary,
        content: document.content,
        author: entity_name(document.author_character),
        location: entity_name(document.location),
        guild: entity_name(document.guild),
        god: entity_name(document.god),
        race: entity_name(document.race),
        civilization: entity_name(document.civilization)
      }
    end)
  end

  defp connections(world_id) do
    LoreConnection
    |> world_records(world_id, :connection_type)
    |> Repo.preload(connection_preloads())
    |> Enum.map(fn connection ->
      {source_type, source} = connection_endpoint(connection, :source)
      {target_type, target} = connection_endpoint(connection, :target)

      %{
        name: connection.name,
        type: connection.connection_type,
        status: connection.status,
        started_at: connection.started_at,
        ended_at: connection.ended_at,
        description: connection.description,
        source: %{type: source_type, name: source},
        target: %{type: target_type, name: target}
      }
    end)
  end

  defp maps(world_id) do
    MapDocument
    |> world_records(world_id)
    |> Repo.preload([:parent_map, items: [:continent, :province, :hold, :location]])
    |> Enum.map(fn map_document ->
      %{
        name: map_document.name,
        kind: map_document.kind,
        description: map_document.description,
        width: map_document.width,
        height: map_document.height,
        document: map_document.document,
        parent: entity_name(map_document.parent_map),
        items: Enum.map(map_document.items, &map_item_card/1)
      }
    end)
  end

  defp skill_trees(world_id) do
    SkillTree
    |> world_records(world_id)
    |> Repo.preload(skills: :levels, perks: [])
    |> Enum.map(fn tree ->
      card(tree)
      |> Map.put(:category, tree.category)
      |> Map.put(:skills, Enum.map(tree.skills, &skill_card/1))
      |> Map.put(
        :perks,
        Enum.map(tree.perks, fn perk ->
          record(
            perk.name,
            join_values([
              measure(perk.required_level, "required"),
              measure(perk.ranks, "ranks")
            ]),
            perk.description
          )
        end)
      )
    end)
  end

  defp spells(world_id) do
    Spell
    |> world_records(world_id)
    |> Enum.map(fn spell ->
      card(spell)
      |> Map.merge(%{
        school: spell.school,
        level: spell.level,
        magicka_cost: spell.magicka_cost,
        source: spell.source
      })
    end)
  end

  defp skills(world_id) do
    Skill
    |> world_records(world_id)
    |> Repo.preload([:skill_tree, :levels])
    |> Enum.map(&skill_card/1)
  end

  defp items(world_id) do
    Item
    |> world_records(world_id)
    |> Repo.preload(item_effects: :effect)
    |> Enum.map(fn item ->
      card(item)
      |> Map.merge(%{
        category: item.category,
        kind: item.kind,
        material: item.material,
        hands: item.hands,
        damage: item.damage,
        critical_damage: item.critical_damage,
        weight: item.weight,
        value: item.value,
        source: item.source,
        effects:
          Enum.map(item.item_effects, fn item_effect ->
            record(entity_name(item_effect.effect), nil, item_effect.notes)
          end)
      })
    end)
  end

  defp creatures(world_id) do
    Creature
    |> world_records(world_id)
    |> Repo.preload([:creature_type, creature_locations: :location])
    |> Enum.map(fn creature ->
      card(creature)
      |> Map.merge(%{
        type: entity_name(creature.creature_type),
        habitat: creature.habitat,
        temperament: creature.temperament,
        danger_level: creature.danger_level,
        locations:
          Enum.map(creature.creature_locations, fn relation ->
            record(entity_name(relation.location), relation.presence, relation.description)
          end)
      })
    end)
  end

  defp calendars(world_id) do
    Calendar
    |> join(:inner, [calendar], continent in assoc(calendar, :continent))
    |> where([_calendar, continent], continent.world_id == ^world_id)
    |> order_by([calendar], asc: calendar.name)
    |> Repo.all()
    |> Repo.preload([:continent, :months])
    |> Enum.map(fn calendar ->
      %{
        name: calendar.name,
        description: calendar.description,
        continent: entity_name(calendar.continent),
        era: calendar.era,
        days_per_week: calendar.days_per_week,
        weekday_names: calendar.weekday_names,
        year_start_angle: calendar.year_start_angle,
        perihelion_day: calendar.perihelion_day,
        months:
          calendar.months
          |> Enum.sort_by(& &1.position)
          |> Enum.map(&record(&1.name, measure(&1.days, "days"), nil))
      }
    end)
  end

  defp timelines(world_id) do
    Timeline
    |> world_records(world_id)
    |> Repo.preload([:eras, :events])
    |> Enum.map(fn timeline ->
      %{
        name: timeline.name,
        description: timeline.description,
        eras:
          timeline.eras
          |> Enum.sort_by(& &1.position)
          |> Enum.map(fn era ->
            %{
              name: era.name,
              abbreviation: era.abbreviation,
              starts_at_year: era.starts_at_year,
              ends_at_year: era.ends_at_year,
              description: era.description,
              events:
                timeline.events
                |> Enum.filter(&(&1.timeline_era_id == era.id))
                |> Enum.sort_by(& &1.position)
                |> Enum.map(&record(&1.name, measure(&1.year, "year"), &1.description))
            }
          end),
        events:
          timeline.events
          |> Enum.filter(&is_nil(&1.timeline_era_id))
          |> Enum.sort_by(& &1.position)
          |> Enum.map(&record(&1.name, measure(&1.year, "year"), &1.description))
      }
    end)
  end

  defp world_records(schema, world_id, order_field \\ :name) do
    schema
    |> where([record], record.world_id == ^world_id)
    |> order_by([record], asc: field(record, ^order_field))
    |> Repo.all()
  end

  defp location_card(location) do
    %{
      name: location.name,
      description: location.description,
      type: entity_name(location.location_type),
      hold: entity_name(location.hold),
      province: entity_name(location.hold.province),
      continent: entity_name(location.hold.province.continent),
      visibility: location.visibility,
      map_x: location.map_x,
      map_y: location.map_y,
      characters:
        Enum.map(location.character_locations, fn relation ->
          %{
            name: entity_name(relation.character),
            relationship: relation.relationship,
            description: relation.description,
            occupations:
              Enum.map(relation.character.character_occupations, fn occupation ->
                entity_name(occupation.occupation)
              end)
          }
        end)
    }
  end

  defp character_card(character) do
    card(character)
    |> Map.merge(%{
      title: character.title,
      role: character.role || entity_name(character.character_role),
      politics: character.politics,
      status: character.status,
      race: entity_name(character.race),
      home_location: entity_name(character.home_location),
      locations:
        Enum.map(character.character_locations, fn relation ->
          record(entity_name(relation.location), relation.relationship, relation.description)
        end),
      occupations:
        Enum.map(character.character_occupations, fn relation ->
          record(entity_name(relation.occupation), relation.rank, relation.description)
        end),
      guilds:
        Enum.map(character.guild_memberships, fn membership ->
          record(
            entity_name(membership.guild),
            join_values([membership.role, membership.rank]),
            membership.description
          )
        end),
      skills:
        Enum.map(character.character_skills, fn relation ->
          record(entity_name(relation.skill), relation.level, relation.description)
        end),
      spells:
        Enum.map(character.spellbook_entries, fn entry ->
          record(
            entity_name(entry.spell),
            if(entry.favorite, do: "Favorite", else: nil),
            entry.notes
          )
        end),
      inventory:
        Enum.map(character.inventory_items, fn inventory_item ->
          item_name = entity_name(inventory_item.item) || inventory_item.name || "Unnamed item"

          record(
            item_name,
            join_values([
              entity_name(inventory_item.inventory_category),
              measure(inventory_item.quantity, "carried"),
              if(inventory_item.equipped, do: "equipped", else: nil)
            ]),
            inventory_item.notes
          )
        end)
    })
  end

  defp guild_card(guild) do
    card(guild)
    |> Map.merge(%{
      leader: guild.leader,
      headquarters: guild.headquarters,
      alignment: guild.alignment,
      members:
        Enum.map(guild.guild_memberships, fn membership ->
          record(
            entity_name(membership.character),
            join_values([membership.role, membership.rank, membership.status]),
            membership.description
          )
        end),
      influences:
        Enum.map(guild.guild_influences, fn influence ->
          subject = entity_name(influence.god) || entity_name(influence.character)
          record(subject, influence.relationship, influence.description)
        end)
    })
  end

  defp civilization_card(civilization) do
    card(civilization)
    |> Map.merge(%{
      era: civilization.era,
      status: civilization.status,
      races:
        Enum.map(civilization.civilization_races, fn relation ->
          record(entity_name(relation.race), relation.relationship, relation.description)
        end),
      locations:
        Enum.map(civilization.civilization_locations, fn relation ->
          record(entity_name(relation.location), relation.relationship, relation.description)
        end)
    })
  end

  defp skill_card(skill) do
    card(skill)
    |> Map.merge(%{
      category: skill.category,
      tree: entity_name(skill.skill_tree),
      levels:
        skill.levels
        |> Enum.sort_by(& &1.rank)
        |> Enum.map(fn level ->
          record(
            level.name,
            join_values([
              measure(level.rank, "rank"),
              measure(level.minimum_value, "minimum")
            ]),
            level.description
          )
        end)
    })
  end

  defp map_item_card(%MapItem{} = item) do
    linked_entity =
      entity_name(item.location) || entity_name(item.hold) || entity_name(item.province) ||
        entity_name(item.continent)

    %{
      name: item.name || linked_entity || item.kind || item.object_type,
      detail: join_values([item.layer, item.kind, linked_entity]),
      description: position(item.x, item.y),
      named_or_linked?: not is_nil(item.name) || not is_nil(linked_entity)
    }
  end

  defp connection_endpoint(connection, prefix) do
    Enum.find_value(connection_entity_types(), {nil, nil}, fn {type, suffix} ->
      entity = Map.get(connection, String.to_existing_atom("#{prefix}_#{suffix}"))
      entity && {type, entity_name(entity)}
    end)
  end

  defp connection_preloads do
    for prefix <- [:source, :target], {_type, suffix} <- connection_entity_types() do
      String.to_existing_atom("#{prefix}_#{suffix}")
    end
  end

  defp connection_entity_types do
    [
      {"Character", "character"},
      {"Guild", "guild"},
      {"God", "god"},
      {"Race", "race"},
      {"Civilization", "civilization"},
      {"Location", "location"},
      {"Hold", "hold"},
      {"Province", "province"},
      {"Continent", "continent"}
    ]
  end

  defp card(entity) do
    %{name: entity.name, description: entity.description}
  end

  defp record(name, detail, description) do
    %{name: name, detail: detail, description: description}
  end

  defp entity_name(nil) do
    nil
  end

  defp entity_name(entity) do
    Map.get(entity, :name)
  end

  defp position(nil, nil) do
    nil
  end

  defp position(x, y) do
    "Position: #{x}, #{y}"
  end

  defp measure(nil, _unit) do
    nil
  end

  defp measure(value, unit) do
    "#{value} #{unit}"
  end

  defp join_values(values) do
    values
    |> Enum.reject(&blank?/1)
    |> Enum.map(&humanize/1)
    |> Enum.join(" / ")
  end

  defp humanize(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> humanize()
  end

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
  end

  defp blank?(value) do
    is_nil(value) || String.trim(to_string(value)) == ""
  end
end
