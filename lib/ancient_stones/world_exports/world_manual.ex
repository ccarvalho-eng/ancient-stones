defmodule AncientStones.WorldExports.WorldManual do
  alias AncientStones.WorldExports.WorldGuideDetails

  def build(guide) do
    details = details(guide)

    chapters =
      [
        overview(guide),
        atlas(guide, details),
        chapter("maps", "Maps", Map.get(details, :maps, []), &map_record/1),
        chapter(
          "civilizations",
          "Civilizations",
          Map.get(details, :civilizations, []),
          &civilization_record/1
        ),
        chapter("races", "Races", Map.get(details, :races, []), &race_record/1),
        chapter("guilds", "Guilds", resolved(guide, details, :guilds), &guild_record/1),
        chapter("gods", "Gods", Map.get(details, :gods, []), &god_record/1),
        chapter("people", "People", resolved(guide, details, :characters), &character_record/1),
        society_chapter(details),
        skills_chapter(details),
        chapter("spells", "Spells", Map.get(details, :spells, []), &spell_record/1),
        chapter("items", "Items", Map.get(details, :items, []), &item_record/1),
        chapter("bestiary", "Bestiary", Map.get(details, :creatures, []), &creature_record/1),
        chapter("documents", "Documents", Map.get(details, :documents, []), &document_record/1),
        connections_chapter(details),
        economy(guide),
        chapter("calendars", "Calendars", Map.get(details, :calendars, []), &calendar_record/1),
        chapter("timeline", "Timeline", Map.get(details, :timelines, []), &timeline_record/1)
      ]
      |> Enum.reject(&is_nil/1)

    %{
      title: Map.get(guide.world, :name, "World Guide"),
      description: Map.get(guide.world, :description),
      world: guide.world,
      chapters: chapters
    }
  end

  defp details(guide) do
    with id when is_binary(id) <- Map.get(guide.world, :id),
         {:ok, world_id} <- Ecto.UUID.cast(id) do
      WorldGuideDetails.load(world_id)
    else
      _ -> Map.get(guide, :details, %{})
    end
  end

  defp overview(guide) do
    continents = Map.get(guide, :continents, [])
    provinces = Enum.flat_map(continents, &Map.get(&1, :provinces, []))
    holds = Enum.flat_map(provinces, &Map.get(&1, :holds, []))
    locations = Enum.flat_map(holds, &Map.get(&1, :locations, []))

    %{
      id: "overview",
      title: "World at a glance",
      description: Map.get(guide.world, :description),
      facts:
        facts([
          {"Galaxy", Map.get(guide.world, :galaxy_name)},
          {"Primary star", Map.get(guide.world, :primary_star_name)},
          {"Orbital period", measure(Map.get(guide.world, :orbital_period_days), "days")},
          {"Day length", measure(Map.get(guide.world, :day_length_hours), "hours")},
          {"Axial tilt", measure(Map.get(guide.world, :axial_tilt_degrees), "degrees")},
          {"Mean radius", measure(Map.get(guide.world, :mean_radius_km), "km")},
          {"Map projection", Map.get(guide.world, :map_projection)},
          {"Continents", length(continents)},
          {"Provinces", length(provinces)},
          {"Holds", length(holds)},
          {"Named locations", length(locations)}
        ]),
      records: []
    }
  end

  defp atlas(guide, details) do
    %{
      id: "atlas",
      title: "Atlas",
      description:
        "Continents, provinces, holds, settlements, landmarks, offices, and regional commerce.",
      facts: [],
      records:
        section(
          "Named waters",
          Enum.map(Map.get(guide, :water_bodies, []), &water_body_record/1)
        ) ++
          section(
            "Water connections",
            Enum.map(Map.get(guide, :water_connections, []), &simple_record/1)
          ) ++
          Enum.map(Map.get(guide, :continents, []), fn continent ->
            continent_record(continent, Map.get(details, :locations, []))
          end)
    }
  end

  defp water_body_record(water) do
    record(
      water.name,
      Map.get(water, :detail),
      Map.get(water, :description),
      facts([
        {"Prevailing conditions", Map.get(water, :prevailing_conditions)},
        {"Hazards", Map.get(water, :hazards)}
      ]),
      entity_records("Provinces", Map.get(water, :provinces, []))
    )
  end

  defp continent_record(continent, locations) do
    calendar = Map.get(continent, :calendar)

    record(
      continent.name,
      nil,
      Map.get(continent, :description),
      facts([
        {"Calendar", calendar && calendar.name},
        {"Weekdays", calendar && Enum.join(Map.get(calendar, :weekday_names, []), ", ")}
      ]),
      entity_records("Offices", Map.get(continent, :offices, [])) ++
        Enum.map(Map.get(continent, :provinces, []), &province_record(&1, locations))
    )
  end

  defp province_record(province, locations) do
    record(
      province.name,
      join_values([Map.get(province, :terrain), Map.get(province, :climate)]),
      Map.get(province, :description),
      [],
      entity_records("Offices", Map.get(province, :offices, [])) ++
        Enum.map(Map.get(province, :holds, []), &hold_record(&1, province.name, locations))
    )
  end

  defp hold_record(hold, province_name, locations) do
    hold_locations =
      case Enum.filter(locations, &(&1.hold == hold.name && &1.province == province_name)) do
        [] -> Map.get(hold, :locations, [])
        matches -> matches
      end

    profile = Map.get(hold, :economic_profile)

    children =
      entity_records("Offices", Map.get(hold, :offices, [])) ++
        entity_records("Regional economy", Map.get(hold, :commerce, [])) ++
        entity_records("Commodity balances", Map.get(hold, :commodity_balances, [])) ++
        section("Places and establishments", Enum.map(hold_locations, &location_record/1))

    record(
      hold.name,
      join_values([Map.get(hold, :terrain), Map.get(hold, :climate)]),
      Map.get(hold, :description),
      facts([
        {"Population estimate", profile && Map.get(profile, :population_estimate)},
        {"Household estimate", profile && Map.get(profile, :household_estimate)},
        {"Urban population", profile && Map.get(profile, :urban_population_estimate)},
        {"Arable hectares", profile && Map.get(profile, :arable_hectares_estimate)},
        {"Pasture hectares", profile && Map.get(profile, :pasture_hectares_estimate)},
        {"Staple reserve months", profile && Map.get(profile, :staple_reserve_months)},
        {"Estimate", profile && Map.get(profile, :assessment_label)},
        {"Confidence", profile && Map.get(profile, :confidence)}
      ]),
      children
    )
  end

  defp location_record(location) do
    people =
      Enum.map(Map.get(location, :characters, []), fn character ->
        occupation = character |> Map.get(:occupations, []) |> List.first()

        record(
          character.name,
          join_values([Map.get(character, :relationship), occupation]),
          Map.get(character, :description)
        )
      end)

    record(
      location.name,
      Map.get(location, :type) || Map.get(location, :detail),
      Map.get(location, :description),
      facts([
        {"Water body", Map.get(location, :water_body)},
        {"Coordinates", coordinates(location)}
      ]),
      section("Associated people", people)
    )
  end

  defp map_record(map) do
    placed_features =
      map
      |> Map.get(:items, [])
      |> Enum.filter(&Map.get(&1, :named_or_linked?, false))

    map
    |> then(fn map ->
      record(
        map.name,
        humanize(Map.get(map, :kind)),
        Map.get(map, :description),
        facts([{"Dimensions", dimensions(map)}, {"Parent map", Map.get(map, :parent)}]),
        section("Placed features", Enum.map(placed_features, &simple_record/1))
      )
    end)
    |> Map.put(:map_canvas, %{
      document: Map.get(map, :document),
      width: Map.get(map, :width),
      height: Map.get(map, :height)
    })
  end

  defp civilization_record(civilization) do
    record(
      civilization.name,
      join_values([Map.get(civilization, :era), Map.get(civilization, :status)]),
      Map.get(civilization, :description),
      [],
      section("Peoples", Enum.map(Map.get(civilization, :races, []), &simple_record/1)) ++
        section(
          "Territories and sites",
          Enum.map(Map.get(civilization, :locations, []), &simple_record/1)
        )
    )
  end

  defp race_record(race) do
    record(
      race.name,
      nil,
      Map.get(race, :description),
      [],
      section("Traits", Enum.map(Map.get(race, :traits, []), &simple_record/1))
    )
  end

  defp guild_record(guild) do
    record(
      guild.name,
      Map.get(guild, :alignment),
      Map.get(guild, :description),
      facts([
        {"Leader", Map.get(guild, :leader)},
        {"Headquarters", Map.get(guild, :headquarters)}
      ]),
      section("Members", Enum.map(Map.get(guild, :members, []), &simple_record/1)) ++
        section("Influence", Enum.map(Map.get(guild, :influences, []), &simple_record/1))
    )
  end

  defp god_record(god) do
    record(
      god.name,
      Map.get(god, :pantheon),
      Map.get(god, :description),
      facts([{"Domain", Map.get(god, :domain)}])
    )
  end

  defp character_record(character) do
    record(
      character.name,
      join_values([Map.get(character, :title), Map.get(character, :role)]),
      Map.get(character, :description),
      facts([
        {"Race", Map.get(character, :race)},
        {"Status", Map.get(character, :status)},
        {"Social status", humanize(Map.get(character, :social_status))},
        {"Life stage", humanize(Map.get(character, :life_stage))},
        {"Means", humanize(Map.get(character, :wealth_band))},
        {"Home", Map.get(character, :home_location)},
        {"Politics", Map.get(character, :politics)}
      ]),
      related_sections(character, [
        {:occupations, "Occupations"},
        {:locations, "Places"},
        {:guilds, "Guilds"},
        {:skills, "Skills"},
        {:spells, "Spellbook"},
        {:inventory, "Inventory"}
      ])
    )
  end

  defp society_chapter(details) do
    records =
      section(
        "Households",
        Enum.map(Map.get(details, :households, []), &household_record/1)
      ) ++
        section(
          "Personal ties",
          Enum.map(
            Map.get(details, :character_relationships, []),
            &character_relationship_record/1
          )
        )

    chapter_from_records("society", "Society", records)
  end

  defp household_record(household) do
    record(
      household.name,
      join_values([Map.get(household, :household_type), Map.get(household, :status)]),
      Map.get(household, :description),
      facts([{"Usual residence", Map.get(household, :home_location)}]),
      section(
        "People of the household",
        Enum.map(Map.get(household, :memberships, []), &simple_record/1)
      ) ++
        section(
          "Tenure and use rights",
          Enum.map(Map.get(household, :landholdings, []), &simple_record/1)
        )
    )
  end

  defp character_relationship_record(relationship) do
    record(
      relationship.name,
      join_values([
        Map.get(relationship, :relationship_type),
        Map.get(relationship, :status)
      ]),
      Map.get(relationship, :description),
      facts([
        {Map.get(relationship, :character_a) || "First person",
         Map.get(relationship, :character_a_role)},
        {Map.get(relationship, :character_b) || "Second person",
         Map.get(relationship, :character_b_role)},
        {"Began", Map.get(relationship, :start_date_label)},
        {"Ended", Map.get(relationship, :end_date_label)}
      ])
    )
  end

  defp skill_tree_record(tree) do
    record(
      tree.name,
      Map.get(tree, :category),
      Map.get(tree, :description),
      [],
      section("Skills", Enum.map(Map.get(tree, :skills, []), &skill_record/1)) ++
        section("Perks", Enum.map(Map.get(tree, :perks, []), &simple_record/1))
    )
  end

  defp skills_chapter(details) do
    tree_records = Enum.map(Map.get(details, :skill_trees, []), &skill_tree_record/1)

    standalone_records =
      details
      |> Map.get(:skills, [])
      |> Enum.filter(&blank?(Map.get(&1, :tree)))
      |> Enum.map(&skill_record/1)

    chapter_from_records("skills", "Skills", tree_records ++ standalone_records)
  end

  defp skill_record(skill) do
    record(
      skill.name,
      Map.get(skill, :category),
      Map.get(skill, :description),
      [],
      section("Levels", Enum.map(Map.get(skill, :levels, []), &simple_record/1))
    )
  end

  defp spell_record(spell) do
    record(
      spell.name,
      join_values([Map.get(spell, :school), Map.get(spell, :level)]),
      Map.get(spell, :description),
      facts([
        {"Magicka cost", Map.get(spell, :magicka_cost)},
        {"Source", Map.get(spell, :source)}
      ])
    )
  end

  defp item_record(item) do
    record(
      item.name,
      join_values([Map.get(item, :category), Map.get(item, :kind), Map.get(item, :material)]),
      Map.get(item, :description),
      facts([
        {"Hands", Map.get(item, :hands)},
        {"Damage", Map.get(item, :damage)},
        {"Critical damage", Map.get(item, :critical_damage)},
        {"Weight", Map.get(item, :weight)},
        {"Value", Map.get(item, :value)},
        {"Source", Map.get(item, :source)}
      ]),
      section("Effects", Enum.map(Map.get(item, :effects, []), &simple_record/1))
    )
  end

  defp creature_record(creature) do
    record(
      creature.name,
      Map.get(creature, :type),
      Map.get(creature, :description),
      facts([
        {"Habitat", Map.get(creature, :habitat)},
        {"Temperament", Map.get(creature, :temperament)},
        {"Danger", Map.get(creature, :danger_level)}
      ]),
      section("Known locations", Enum.map(Map.get(creature, :locations, []), &simple_record/1))
    )
  end

  defp document_record(document) do
    record(
      document.name,
      join_values([Map.get(document, :kind), Map.get(document, :source)]),
      Map.get(document, :summary),
      facts([
        {"Author", Map.get(document, :author)},
        {"Location", Map.get(document, :location)},
        {"Guild", Map.get(document, :guild)},
        {"God", Map.get(document, :god)},
        {"Race", Map.get(document, :race)},
        {"Civilization", Map.get(document, :civilization)}
      ]),
      section("Text", [record("Full text", nil, Map.get(document, :content))])
    )
  end

  defp connections_chapter(details) do
    records =
      details
      |> Map.get(:connections, [])
      |> Enum.group_by(fn connection ->
        source = Map.get(connection, :source, %{})
        {Map.get(source, :type), Map.get(source, :name)}
      end)
      |> Enum.sort_by(fn {{type, name}, _connections} -> {type || "", name || ""} end)
      |> Enum.map(fn {{type, name}, connections} ->
        record(
          join_values([type, name]),
          nil,
          nil,
          [],
          Enum.map(connections, &connection_record/1)
        )
      end)

    chapter_from_records("connections", "Connections", records)
  end

  defp connection_record(connection) do
    target = Map.get(connection, :target, %{})

    record(
      Map.get(connection, :name) ||
        join_values([Map.get(connection, :type), Map.get(target, :name)]),
      join_values([Map.get(connection, :type), Map.get(connection, :status)]),
      Map.get(connection, :description),
      facts([
        {"Target", join_values([Map.get(target, :type), Map.get(target, :name)])},
        {"Began", Map.get(connection, :started_at)},
        {"Ended", Map.get(connection, :ended_at)}
      ])
    )
  end

  defp economy(guide) do
    routes = Map.get(guide, :trade_routes, [])
    policies = Map.get(guide, :tax_policies, [])
    profiles = Map.get(guide, :economic_profiles, [])
    balances = Map.get(guide, :commodity_balances, [])
    assessments = Map.get(guide, :tax_assessments, [])
    ventures = Map.get(guide, :commercial_ventures, [])

    records =
      section("Hold capacity", Enum.map(profiles, &simple_record/1)) ++
        section("Commodity balances", Enum.map(balances, &simple_record/1)) ++
        section("Tax assessments", Enum.map(assessments, &simple_record/1)) ++
        section("Merchant houses and partnerships", Enum.map(ventures, &venture_record/1)) ++
        section("Trade routes", Enum.map(routes, &trade_route_record/1)) ++
        section(
          "Tax policies",
          Enum.map(policies, fn policy ->
            record(
              policy.name,
              Map.get(policy, :detail),
              Map.get(policy, :description),
              [],
              section(
                "Revenue allocation",
                Enum.map(Map.get(policy, :revenue_shares, []), &simple_record/1)
              ) ++
                section(
                  "Exemptions",
                  Enum.map(Map.get(policy, :exemptions, []), &simple_record/1)
                ) ++
                section(
                  "Assessments",
                  Enum.map(Map.get(policy, :assessments, []), &simple_record/1)
                )
            )
          end)
        )

    chapter_from_records("economy", "Trade and taxation", records)
  end

  defp venture_record(venture) do
    record(
      venture.name,
      Map.get(venture, :detail),
      Map.get(venture, :description),
      facts([
        {"Capital and assets", Map.get(venture, :capital_basis)},
        {"Formed", Map.get(venture, :formation_label)},
        {"Ended", Map.get(venture, :end_label)}
      ]),
      section("Partners", Enum.map(Map.get(venture, :members, []), &simple_record/1)) ++
        section("Route work", Enum.map(Map.get(venture, :routes, []), &simple_record/1))
    )
  end

  defp trade_route_record(route) do
    record(
      route.name,
      Map.get(route, :detail),
      Map.get(route, :description),
      [],
      section("Commodity flows", Enum.map(Map.get(route, :flows, []), &simple_record/1)) ++
        section("Itinerary stops", Enum.map(Map.get(route, :stops, []), &simple_record/1)) ++
        section("Route legs", Enum.map(Map.get(route, :legs, []), &simple_record/1))
    )
  end

  defp calendar_record(calendar) do
    record(
      calendar.name,
      Map.get(calendar, :continent),
      Map.get(calendar, :description),
      facts([
        {"Era", Map.get(calendar, :era)},
        {"Days per week", Map.get(calendar, :days_per_week)},
        {"Weekdays", Enum.join(Map.get(calendar, :weekday_names, []), ", ")},
        {"Perihelion day", Map.get(calendar, :perihelion_day)}
      ]),
      section("Months", Enum.map(Map.get(calendar, :months, []), &simple_record/1))
    )
  end

  defp timeline_record(timeline) do
    eras =
      Enum.map(Map.get(timeline, :eras, []), fn era ->
        record(
          era.name,
          join_values([Map.get(era, :abbreviation), year_range(era)]),
          Map.get(era, :description),
          [],
          section("Events", Enum.map(Map.get(era, :events, []), &simple_record/1))
        )
      end)

    record(
      timeline.name,
      nil,
      Map.get(timeline, :description),
      [],
      eras ++
        section("Unassigned events", Enum.map(Map.get(timeline, :events, []), &simple_record/1))
    )
  end

  defp chapter(_id, _title, [], _mapper) do
    nil
  end

  defp chapter(id, title, entries, mapper) do
    chapter_from_records(id, title, Enum.map(entries, mapper))
  end

  defp chapter_from_records(_id, _title, []) do
    nil
  end

  defp chapter_from_records(id, title, records) do
    %{id: id, title: title, description: nil, facts: [], records: records}
  end

  defp record(title, meta, description, facts \\ [], children \\ []) do
    %{
      title: title || "Untitled",
      meta: meta,
      description: description,
      facts: facts,
      children: children
    }
  end

  defp simple_record(entity) do
    detail = Map.get(entity, :detail) || Map.get(entity, :holder)
    record(entity.name, detail, Map.get(entity, :description))
  end

  defp entity_records(_title, []) do
    []
  end

  defp entity_records(title, entries) do
    section(title, Enum.map(entries, &simple_record/1))
  end

  defp section(_title, []) do
    []
  end

  defp section(title, records) do
    [record(title, nil, nil, [], records)]
  end

  defp related_sections(entity, relationships) do
    Enum.flat_map(relationships, fn {key, title} ->
      section(title, Enum.map(Map.get(entity, key, []), &simple_record/1))
    end)
  end

  defp resolved(guide, details, key) do
    case Map.get(details, key, []) do
      [] -> Map.get(guide, key, [])
      records -> records
    end
  end

  defp facts(rows) do
    Enum.reject(rows, fn {_label, value} -> blank?(value) end)
  end

  defp coordinates(entity) do
    case {Map.get(entity, :map_x), Map.get(entity, :map_y)} do
      {nil, nil} -> nil
      {x, y} -> "#{x}, #{y}"
    end
  end

  defp dimensions(entity) do
    case {Map.get(entity, :width), Map.get(entity, :height)} do
      {nil, nil} -> nil
      {width, height} -> "#{width} x #{height}"
    end
  end

  defp year_range(entity) do
    case {Map.get(entity, :starts_at_year), Map.get(entity, :ends_at_year)} do
      {nil, nil} -> nil
      {from, nil} -> "From #{from}"
      {nil, to} -> "Until #{to}"
      {from, to} -> "#{from}-#{to}"
    end
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

  defp humanize(nil) do
    nil
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
