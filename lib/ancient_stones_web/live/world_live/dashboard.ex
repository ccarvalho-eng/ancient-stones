defmodule AncientStonesWeb.WorldLive.Dashboard do
  use AncientStonesWeb, :live_view

  alias AncientStones.Worlds
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CharacterRole
  alias AncientStones.Worlds.Geography
  alias AncientStones.Worlds.Hold
  alias AncientStones.Worlds.Province

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "World Details",
       theme: "system",
       timeline_detail_tab: "eras",
       expanded_action: "continent",
       open_folded_groups: MapSet.new()
     )}
  end

  def handle_params(%{"id" => id} = params, _uri, socket) do
    {:noreply, assign_dashboard(socket, id, params, select_action: true)}
  end

  embed_templates "dashboard/*"

  def handle_event("create_continent", %{"continent" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, continent} <-
             Worlds.create_continent(socket.assigns.world, continent_attrs(params)),
           {:ok, _currency} <-
             Worlds.put_continent_currency(continent, continent_currency_attrs(params)) do
        {:ok, continent}
      end
    end)
  end

  def handle_event("update_continent", %{"continent" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, continent} <- get_selected_continent(socket) do
        with {:ok, continent} <- Worlds.update_continent(continent, continent_attrs(params)),
             {:ok, _currency} <-
               Worlds.put_continent_currency(continent, continent_currency_attrs(params)) do
          {:ok, continent}
        end
      end
    end)
  end

  def handle_event("create_province", %{"province" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, continent} <- get_continent_in_world(socket, params["continent_id"]) do
        Worlds.create_province(continent, params)
      end
    end)
  end

  def handle_event("update_province", %{"province" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, province} <- get_selected_province(socket),
           {:ok, continent} <- get_continent_in_world(socket, params["continent_id"]) do
        Worlds.update_province(province, continent, params)
      end
    end)
  end

  def handle_event("create_hold", %{"hold" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, province} <- get_province_in_world(socket, params["province_id"]) do
        Worlds.create_hold(province, params)
      end
    end)
  end

  def handle_event("update_hold", %{"hold" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, hold} <- get_selected_hold(socket),
           {:ok, province} <- get_province_in_world(socket, params["province_id"]) do
        Worlds.update_hold(hold, province, params,
          province_capital: params["province_capital"] == "true"
        )
      end
    end)
  end

  def handle_event("create_location_type", %{"location_type" => params}, socket) do
    create_and_reload(socket, fn ->
      case params["parent_id"] do
        "" ->
          Worlds.create_location_type(socket.assigns.world, params)

        parent_id ->
          with {:ok, parent} <- get_location_type_in_world(socket, parent_id) do
            Worlds.create_location_type(parent, params)
          end
      end
    end)
  end

  def handle_event("create_location", %{"location" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, hold} <- get_selected_hold(socket, params["hold_id"]),
           {:ok, location_type} <- get_location_type_in_world(socket, params["location_type_id"]),
           {:ok, parent_location} <-
             get_parent_location_in_selected_hold(socket, params["parent_location_id"]) do
        Worlds.create_location_in_hold(hold, location_type, params,
          parent_location: parent_location,
          capital: params["capital"] == "true"
        )
      end
    end)
  end

  def handle_event("update_location", %{"location_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, location} <- get_selected_location(socket),
           {:ok, location_type} <- get_location_type_in_world(socket, params["location_type_id"]) do
        Worlds.update_location_in_hold(location, location_type, params,
          capital: params["capital"] == "true"
        )
      end
    end)
  end

  def handle_event("create_commerce", %{"commerce" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, hold} <- get_selected_hold(socket) do
        Worlds.create_hold_commerce_entry(hold, params)
      end
    end)
  end

  def handle_event("delete_continent", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, continent} <- get_continent_in_world(socket, id) do
        Worlds.delete_continent(continent)
      end
    end)
  end

  def handle_event("delete_province", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, province} <- get_province_in_world(socket, id) do
        Worlds.delete_province(province)
      end
    end)
  end

  def handle_event("delete_hold", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, hold} <- get_hold_in_world(socket, id) do
        Worlds.delete_hold(hold)
      end
    end)
  end

  def handle_event("delete_location", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, location} <- get_location_in_world(socket, id) do
        Worlds.delete_location(location)
      end
    end)
  end

  def handle_event("delete_location_type", %{"location_type_delete" => %{"id" => id}}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, location_type} <- get_location_type_in_world(socket, id) do
        Worlds.delete_location_type(location_type)
      end
    end)
  end

  def handle_event("delete_commerce", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, commerce_entry} <- get_commerce_in_selected_hold(socket, id) do
        Worlds.delete_hold_commerce_entry(commerce_entry)
      end
    end)
  end

  def handle_event("create_political_office", %{"political_office" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, refs} <- political_office_refs(socket, params) do
        Worlds.create_political_office(socket.assigns.world, params, refs)
      end
    end)
  end

  def handle_event("update_political_office", %{"political_office_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, political_office} <- get_political_office_in_world(socket, params["id"]),
           {:ok, character} <- get_optional_character_in_world(socket, params["character_id"]) do
        attrs = Map.drop(params, ["id"])

        Worlds.update_political_office(political_office, attrs, character: character)
      end
    end)
  end

  def handle_event("delete_political_office", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, political_office} <- get_political_office_in_world(socket, id) do
        Worlds.delete_political_office(political_office)
      end
    end)
  end

  def handle_event("create_race", %{"race" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, civilization} <-
             get_optional_civilization_in_world(socket, params["civilization_id"]) do
        Worlds.create_race(socket.assigns.world, params, civilization: civilization)
      end
    end)
  end

  def handle_event("validate_race", %{"race" => params}, socket) do
    {:noreply, assign_race_form(socket, params)}
  end

  def handle_event("add_race_trait", _params, socket) do
    params = race_form_attrs(socket.assigns.race_form_params)
    traits = Map.get(params, "traits", []) ++ [race_trait_attrs()]

    {:noreply, assign_race_form(socket, Map.put(params, "traits", traits))}
  end

  def handle_event("remove_race_trait", %{"index" => index}, socket) do
    params = race_form_attrs(socket.assigns.race_form_params)
    traits = params |> Map.get("traits", []) |> delete_race_trait_at(index)

    {:noreply, assign_race_form(socket, Map.put(params, "traits", traits))}
  end

  def handle_event("delete_race", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, race} <- get_race_in_world(socket, id) do
        Worlds.delete_race(race)
      end
    end)
  end

  def handle_event("create_guild", %{"guild" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_guild(socket.assigns.world, params) end)
  end

  def handle_event("delete_guild", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, guild} <- get_guild_in_world(socket, id) do
        Worlds.delete_guild(guild)
      end
    end)
  end

  def handle_event("create_guild_influence", %{"guild_influence" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, guild} <- get_guild_in_world(socket, params["guild_id"]),
           {:ok, god} <- get_optional_god_in_world(socket, params["god_id"]),
           {:ok, character} <- get_optional_character_in_world(socket, params["character_id"]),
           {:ok, refs} <- guild_influence_refs(god, character) do
        Worlds.create_guild_influence(guild, params, refs)
      end
    end)
  end

  def handle_event("delete_guild_influence", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, guild_influence} <- get_guild_influence_in_world(socket, id) do
        Worlds.delete_guild_influence(guild_influence)
      end
    end)
  end

  def handle_event("create_god", %{"god" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_god(socket.assigns.world, params) end)
  end

  def handle_event("delete_god", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, god} <- get_god_in_world(socket, id) do
        Worlds.delete_god(god)
      end
    end)
  end

  def handle_event("create_document", %{"document" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, refs} <- document_refs(socket, params) do
        Worlds.create_document(socket.assigns.world, params, refs)
      end
    end)
  end

  def handle_event("update_document", %{"document_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, document} <- get_selected_document(socket),
           {:ok, refs} <- document_refs(socket, params) do
        Worlds.update_document(document, params, refs)
      end
    end)
  end

  def handle_event("delete_document", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, document} <- get_document_in_world(socket, id) do
        Worlds.delete_document(document)
      end
    end)
  end

  def handle_event("create_lore_connection", %{"lore_connection" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, refs} <- lore_connection_refs(socket, params) do
        Worlds.create_lore_connection(socket.assigns.world, params, refs)
      end
    end)
  end

  def handle_event("update_lore_connection", %{"lore_connection_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, lore_connection} <- get_selected_lore_connection(socket),
           {:ok, refs} <- lore_connection_refs(socket, params) do
        Worlds.update_lore_connection(lore_connection, params, refs)
      end
    end)
  end

  def handle_event("delete_lore_connection", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, lore_connection} <- get_lore_connection_in_world(socket, id) do
        Worlds.delete_lore_connection(lore_connection)
      end
    end)
  end

  def handle_event("create_civilization", %{"civilization" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, timeline_era} <-
             get_optional_timeline_era_in_world(socket, params["timeline_era_id"]) do
        Worlds.create_civilization(socket.assigns.world, params, timeline_era: timeline_era)
      end
    end)
  end

  def handle_event("delete_civilization", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, civilization} <- get_civilization_in_world(socket, id) do
        Worlds.delete_civilization(civilization)
      end
    end)
  end

  def handle_event("create_timeline", %{"timeline" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_timeline(socket.assigns.world, params) end)
  end

  def handle_event("create_timeline_era", %{"timeline_era" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, timeline} <- get_timeline_in_world(socket, params["timeline_id"]) do
        Worlds.create_timeline_era(timeline, params)
      end
    end)
  end

  def handle_event("create_timeline_event", %{"timeline_event" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, timeline} <- get_timeline_in_world(socket, params["timeline_id"]),
           {:ok, timeline_era} <-
             get_optional_timeline_era_in_world(socket, params["timeline_era_id"]) do
        Worlds.create_timeline_event(timeline, params, timeline_era: timeline_era)
      end
    end)
  end

  def handle_event("delete_timeline", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, timeline} <- get_timeline_in_world(socket, id) do
        Worlds.delete_timeline(timeline)
      end
    end)
  end

  def handle_event("delete_timeline_era", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, timeline_era} <- get_timeline_era_in_world(socket, id) do
        Worlds.delete_timeline_era(timeline_era)
      end
    end)
  end

  def handle_event("delete_timeline_event", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, timeline_event} <- get_timeline_event_in_world(socket, id) do
        Worlds.delete_timeline_event(timeline_event)
      end
    end)
  end

  def handle_event("create_character", %{"character" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, character_role} <-
             get_optional_character_role_in_world(socket, params["character_role_id"]),
           {:ok, race} <- get_optional_race_in_world(socket, params["race_id"]),
           {:ok, guild} <- get_optional_guild_in_world(socket, params["guild_id"]),
           {:ok, occupation} <- get_optional_occupation_in_world(socket, params["occupation_id"]),
           {:ok, skill} <- get_optional_skill_in_world(socket, params["skill_id"]),
           {:ok, home_location} <-
             get_optional_location_in_world(socket, params["home_location_id"]) do
        Worlds.create_character(socket.assigns.world, character_attrs(params, character_role),
          character_role: character_role,
          race: race,
          guild: guild,
          occupation: occupation,
          skill: skill,
          home_location: home_location
        )
      end
    end)
  end

  def handle_event("update_character", %{"character" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, character} <- get_selected_character(socket),
           {:ok, character_role} <-
             get_optional_character_role_in_world(socket, params["character_role_id"]),
           {:ok, race} <- get_optional_race_in_world(socket, params["race_id"]),
           {:ok, guild} <- get_optional_guild_in_world(socket, params["guild_id"]),
           {:ok, home_location} <-
             get_optional_location_in_world(socket, params["home_location_id"]) do
        Worlds.update_character(character, character_attrs(params, character_role),
          character_role: character_role,
          race: race,
          guild: guild,
          home_location: home_location
        )
      end
    end)
  end

  def handle_event("create_character_role", %{"character_role" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_character_role(socket.assigns.world, params) end)
  end

  def handle_event("create_occupation", %{"occupation" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_occupation(socket.assigns.world, params) end)
  end

  def handle_event("create_skill", %{"skill" => params}, socket) do
    create_and_reload(socket, fn ->
      Worlds.create_skill_with_tree(socket.assigns.world, params)
    end)
  end

  def handle_event("update_skill", %{"skill_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, skill} <- get_selected_skill(socket) do
        Worlds.update_skill(skill, params)
      end
    end)
  end

  def handle_event("delete_skill", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, skill} <- get_skill_in_world(socket, id) do
        Worlds.delete_skill(skill)
      end
    end)
  end

  def handle_event("create_skill_level", %{"skill_level" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, skill} <- get_selected_skill(socket) do
        Worlds.create_skill_level(skill, params)
      end
    end)
  end

  def handle_event("delete_skill_level", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, skill_level} <- get_skill_level_in_selected_skill(socket, id) do
        Worlds.delete_skill_level(skill_level)
      end
    end)
  end

  def handle_event("create_skill_perk", %{"skill_perk" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, skill_tree} <- get_selected_skill_tree(socket) do
        Worlds.create_skill_tree_perk(skill_tree, params)
      end
    end)
  end

  def handle_event("delete_skill_perk", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, perk} <- get_skill_perk_in_selected_skill(socket, id) do
        Worlds.delete_skill_tree_perk(perk)
      end
    end)
  end

  def handle_event("create_creature_type", %{"creature_type" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_creature_type(socket.assigns.world, params) end)
  end

  def handle_event("delete_creature_type", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, creature_type} <- get_creature_type_in_world(socket, id) do
        Worlds.delete_creature_type(creature_type)
      end
    end)
  end

  def handle_event("create_creature", %{"creature" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, creature_type} <-
             get_optional_creature_type_in_world(socket, params["creature_type_id"]) do
        Worlds.create_creature(socket.assigns.world, params, creature_type: creature_type)
      end
    end)
  end

  def handle_event("update_creature", %{"creature_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, creature} <- get_selected_creature(socket),
           {:ok, creature_type} <-
             get_optional_creature_type_in_world(socket, params["creature_type_id"]) do
        Worlds.update_creature(creature, params, creature_type: creature_type)
      end
    end)
  end

  def handle_event("delete_creature", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, creature} <- get_creature_in_world(socket, id) do
        Worlds.delete_creature(creature)
      end
    end)
  end

  def handle_event("create_creature_location", %{"creature_location" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, creature} <- get_creature_in_world(socket, params["creature_id"]),
           {:ok, location} <- get_location_in_world(socket, params["location_id"]) do
        Worlds.create_creature_location(creature, location, params)
      end
    end)
  end

  def handle_event("delete_creature_location", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, creature_location} <- get_creature_location_in_world(socket, id) do
        Worlds.delete_creature_location(creature_location)
      end
    end)
  end

  def handle_event("create_spell", %{"spell" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_spell(socket.assigns.world, params) end)
  end

  def handle_event("update_spell", %{"spell_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, spell} <- get_selected_spell(socket) do
        Worlds.update_spell(spell, params)
      end
    end)
  end

  def handle_event("delete_spell", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, spell} <- get_spell_in_world(socket, id) do
        Worlds.delete_spell(spell)
      end
    end)
  end

  def handle_event("create_item", %{"item" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_item(socket.assigns.world, params) end)
  end

  def handle_event("update_item", %{"item_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, item} <- get_selected_item(socket) do
        Worlds.update_item(item, params)
      end
    end)
  end

  def handle_event("delete_item", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, item} <- get_item_in_world(socket, id) do
        Worlds.delete_item(item)
      end
    end)
  end

  def handle_event("create_effect", %{"effect" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_effect(socket.assigns.world, params) end)
  end

  def handle_event("create_item_effect", %{"item_effect" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, item} <- get_selected_item(socket),
           {:ok, effect} <- get_effect_in_world(socket, params["effect_id"]) do
        Worlds.create_item_effect(item, effect, params)
      end
    end)
  end

  def handle_event("delete_item_effect", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, item_effect} <- get_item_effect_in_selected_item(socket, id) do
        Worlds.delete_item_effect(item_effect)
      end
    end)
  end

  def handle_event("create_inventory_category", %{"inventory_category" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, character} <- get_selected_character(socket) do
        Worlds.create_inventory_category(character, params)
      end
    end)
  end

  def handle_event("delete_inventory_category", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, inventory_category} <- get_inventory_category_in_selected_character(socket, id) do
        Worlds.delete_inventory_category(inventory_category)
      end
    end)
  end

  def handle_event("create_inventory_item", %{"inventory_item" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, character} <- get_selected_character(socket),
           {:ok, item} <- get_item_in_world(socket, params["item_id"]),
           {:ok, inventory_category} <-
             get_optional_inventory_category_in_selected_character(
               socket,
               params["inventory_category_id"]
             ) do
        Worlds.create_inventory_item(character, params,
          item: item,
          inventory_category: inventory_category
        )
      end
    end)
  end

  def handle_event("delete_inventory_item", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, inventory_item} <- get_inventory_item_in_selected_character(socket, id) do
        Worlds.delete_inventory_item(inventory_item)
      end
    end)
  end

  def handle_event("delete_character", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, character} <- get_character_in_world(socket, id) do
        Worlds.delete_character(character)
      end
    end)
  end

  def handle_event("create_calendar", %{"calendar" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, continent} <- get_continent_in_world(socket, params["continent_id"]) do
        Worlds.create_calendar(continent, params)
      end
    end)
  end

  def handle_event("update_calendar", %{"calendar_edit" => params}, socket) do
    update_and_reload(socket, fn ->
      with {:ok, calendar} <- get_selected_calendar(socket) do
        Worlds.update_calendar(calendar, params)
      end
    end)
  end

  def handle_event("create_calendar_month", %{"calendar_month" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, calendar} <- get_selected_calendar(socket) do
        Worlds.create_calendar_month(calendar, params)
      end
    end)
  end

  def handle_event("delete_calendar", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, calendar} <- get_calendar_in_world(socket, id) do
        Worlds.delete_calendar(calendar)
      end
    end)
  end

  def handle_event("delete_calendar_month", %{"id" => id}, socket) do
    delete_and_reload(socket, fn ->
      with {:ok, month} <- get_calendar_month_in_selected_calendar(socket, id) do
        Worlds.delete_calendar_month(month)
      end
    end)
  end

  def handle_event("show_action", %{"action" => action}, socket) do
    expanded_action =
      if socket.assigns.expanded_action == action do
        nil
      else
        action
      end

    {:noreply,
     socket
     |> assign(:expanded_action, expanded_action)
     |> assign(
       :skill_detail_tab,
       skill_detail_tab_for_action(action, socket.assigns.skill_detail_tab)
     )
     |> assign(
       :timeline_detail_tab,
       timeline_detail_tab_for_action(action, socket.assigns.timeline_detail_tab)
     )}
  end

  def handle_event("toggle_folded_group", %{"key" => key}, socket) do
    open_folded_groups = toggle_folded_group(socket.assigns.open_folded_groups, key)

    {:noreply, assign(socket, :open_folded_groups, open_folded_groups)}
  end

  def handle_event("set_skill_detail_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :skill_detail_tab, normalize_skill_detail_tab(tab))}
  end

  def handle_event("set_timeline_detail_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :timeline_detail_tab, normalize_timeline_detail_tab(tab))}
  end

  def handle_event("set_theme", %{"theme" => theme}, socket) do
    {:noreply, assign(socket, :theme, normalize_theme(theme))}
  end

  defp create_and_reload(socket, callback) do
    case callback.() do
      {:ok, _record} ->
        {:noreply,
         socket
         |> put_flash(:info, "Created")
         |> assign_dashboard(
           socket.assigns.world.id,
           reload_params(socket)
         )}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not create record")}
    end
  end

  defp update_and_reload(socket, callback) do
    case callback.() do
      {:ok, _record} ->
        {:noreply,
         socket
         |> put_flash(:info, "Updated")
         |> assign_dashboard(
           socket.assigns.world.id,
           reload_params(socket)
         )}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not update record")}
    end
  end

  defp delete_and_reload(socket, callback) do
    case callback.() do
      {:ok, _record} ->
        {:noreply,
         socket
         |> put_flash(:info, "Deleted")
         |> assign_dashboard(
           socket.assigns.world.id,
           reload_params(socket)
         )}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not delete record")}
    end
  end

  defp assign_dashboard(socket, world_id, params, opts \\ []) do
    world = Worlds.get_world_dashboard!(world_id)
    section = normalize_section(params["section"])
    expanded_action = selected_expanded_action(socket, section, params, opts)
    continents = sorted(world.continents)
    civilizations = sorted(world.civilizations)
    provinces = flat_provinces(continents)
    holds = flat_holds(provinces)
    locations = flat_locations(holds)
    calendars = flat_calendars(continents)
    characters = sorted(world.characters)
    character_roles = sorted(world.character_roles)
    creature_types = sorted(world.creature_types)
    creatures = sorted(world.creatures)
    creature_locations = flat_creature_locations(creatures)
    documents = sorted_by_title(world.documents)
    effects = sorted(world.effects)
    gods = sorted(world.gods)
    guilds = sorted(world.guilds)
    items = sorted(world.items)
    location_types = sorted(world.location_types)
    occupations = sorted(world.occupations)
    political_offices = world.political_offices
    races = sorted(world.races)
    lore_connections = sorted_lore_connections(world.lore_connections)
    skills = sorted(world.skills)
    spells = sorted(world.spells)
    timelines = sorted(world.timelines)
    timeline_eras = flat_timeline_eras(timelines)
    timeline_events = flat_timeline_events(timelines)
    selected_calendar = select_record(calendars, params["calendar_id"]) || first_record(calendars)

    selected_character =
      select_record(characters, params["character_id"]) || first_record(characters)

    selected_character_inventory_categories =
      character_inventory_categories(selected_character)

    selected_character_inventory_items =
      character_inventory_items(selected_character)

    selected_creature = select_record(creatures, params["creature_id"]) || first_record(creatures)
    selected_document = select_record(documents, params["document_id"]) || first_record(documents)
    selected_god = select_record(gods, params["god_id"]) || first_record(gods)
    selected_guild = select_record(guilds, params["guild_id"]) || first_record(guilds)
    selected_item = select_record(items, params["item_id"]) || first_record(items)
    selected_item_effects = item_effects(selected_item)
    selected_race = select_record(races, params["race_id"]) || first_record(races)

    selected_lore_connection =
      select_record(lore_connections, params["connection_id"]) || first_record(lore_connections)

    selected_skill = select_record(skills, params["skill_id"]) || first_record(skills)
    skill_detail_tab = selected_skill_detail_tab(socket)
    selected_spell = select_record(spells, params["spell_id"]) || first_record(spells)
    selected_timeline = select_record(timelines, params["timeline_id"]) || first_record(timelines)
    timeline_detail_tab = selected_timeline_detail_tab(socket)
    selected_timeline_era_options = option_list(timeline_eras(selected_timeline))
    selected_timeline_events = timeline_events(selected_timeline)
    selected_hold = select_hold(holds, params["hold_id"])
    selected_hold_commerce_entries = selected_hold_commerce_entries(selected_hold)
    selected_hold_locations = selected_hold_locations(selected_hold)
    selected_location = select_location(selected_hold_locations, params["location_id"])
    selected_continent = select_record(continents, params["continent_id"])
    selected_province = select_record(provinces, params["province_id"])

    selected_path =
      select_path(continents, selected_hold, selected_province, selected_continent)

    selected_province_political_offices =
      selected_province_political_offices(selected_path.province)

    selected_hold_political_offices = selected_hold_political_offices(selected_hold)

    selected_political_offices =
      selected_political_offices(
        selected_path.province,
        selected_hold,
        selected_province_political_offices,
        selected_hold_political_offices
      )

    selected_political_office =
      select_record(selected_political_offices, params["political_office_id"]) ||
        first_record(selected_political_offices)

    selected_continent_id = selected_or_first_id(selected_path.continent, continents)
    selected_province_id = selected_or_first_id(selected_path.province, provinces)
    selected_hold_options = option_list(List.wrap(selected_hold))

    lore_connection_entity_options =
      lore_connection_entity_options(
        characters,
        civilizations,
        continents,
        gods,
        guilds,
        holds,
        locations,
        provinces,
        races
      )

    socket
    |> assign(:world, world)
    |> assign(:page_title, world.name)
    |> assign(:section, section)
    |> assign(:expanded_action, expanded_action)
    |> assign(:calendars, calendars)
    |> assign(:selected_calendar, selected_calendar)
    |> assign(:characters, characters)
    |> assign(:character_roles, character_roles)
    |> assign(:selected_character, selected_character)
    |> assign(:selected_character_inventory_categories, selected_character_inventory_categories)
    |> assign(:selected_character_inventory_items, selected_character_inventory_items)
    |> assign(:civilizations, civilizations)
    |> assign(
      :selected_civilization,
      select_record(civilizations, params["civilization_id"]) || first_record(civilizations)
    )
    |> assign(:continents, continents)
    |> assign(:creature_types, creature_types)
    |> assign(:creatures, creatures)
    |> assign(:creature_locations, creature_locations)
    |> assign(:selected_creature, selected_creature)
    |> assign(:documents, documents)
    |> assign(:selected_document, selected_document)
    |> assign(:effects, effects)
    |> assign(:gods, gods)
    |> assign(:selected_god, selected_god)
    |> assign(:guilds, guilds)
    |> assign(:selected_guild, selected_guild)
    |> assign(:items, items)
    |> assign(:selected_item, selected_item)
    |> assign(:selected_item_effects, selected_item_effects)
    |> assign(:occupations, occupations)
    |> assign(:races, races)
    |> assign(:selected_race, selected_race)
    |> assign(:lore_connections, lore_connections)
    |> assign(:selected_lore_connection, selected_lore_connection)
    |> assign(:skills, skills)
    |> assign(:selected_skill, selected_skill)
    |> assign(:skill_detail_tab, skill_detail_tab)
    |> assign(:spells, spells)
    |> assign(:selected_spell, selected_spell)
    |> assign(:timelines, timelines)
    |> assign(:timeline_eras, timeline_eras)
    |> assign(:timeline_events, timeline_events)
    |> assign(:selected_timeline, selected_timeline)
    |> assign(:timeline_detail_tab, timeline_detail_tab)
    |> assign(:selected_timeline_events, selected_timeline_events)
    |> assign(:locations, locations)
    |> assign(:holds, holds)
    |> assign(:selected_hold, selected_hold)
    |> assign(:selected_hold_commerce_entries, selected_hold_commerce_entries)
    |> assign(:selected_hold_locations, selected_hold_locations)
    |> assign(:selected_location, selected_location)
    |> assign(:selected_path, selected_path)
    |> assign(:continent_options, option_list(continents))
    |> assign(:calendar_options, option_list(calendars))
    |> assign(:character_options, option_list(characters))
    |> assign(:character_role_options, option_list(character_roles))
    |> assign(
      :character_inventory_category_options,
      option_list(selected_character_inventory_categories)
    )
    |> assign(:civilization_options, option_list(civilizations))
    |> assign(:creature_type_options, option_list(creature_types))
    |> assign(:creature_options, option_list(creatures))
    |> assign(:document_options, option_list(documents, & &1.title))
    |> assign(:effect_options, option_list(effects))
    |> assign(:all_location_options, option_list(locations))
    |> assign(:god_options, option_list(gods))
    |> assign(:guild_options, option_list(guilds))
    |> assign(:item_options, option_list(items))
    |> assign(:occupation_options, option_list(occupations))
    |> assign(:political_offices, political_offices)
    |> assign(:selected_province_political_offices, selected_province_political_offices)
    |> assign(:selected_hold_political_offices, selected_hold_political_offices)
    |> assign(:selected_political_offices, selected_political_offices)
    |> assign(:selected_political_office, selected_political_office)
    |> assign(:political_office_options, political_office_options(selected_political_offices))
    |> assign(:province_options, option_list(provinces))
    |> assign(:race_options, option_list(races))
    |> assign(:lore_connection_entity_options, lore_connection_entity_options)
    |> assign(:lore_connection_options, option_list(lore_connections, &lore_connection_name/1))
    |> assign(:skill_options, option_list(skills))
    |> assign(:spell_options, option_list(spells))
    |> assign(:timeline_options, option_list(timelines))
    |> assign(:timeline_era_options, option_list(timeline_eras))
    |> assign(:timeline_event_options, option_list(timeline_events))
    |> assign(:selected_timeline_era_options, selected_timeline_era_options)
    |> assign(:selected_hold_options, selected_hold_options)
    |> assign(:location_type_options, option_list(location_types))
    |> assign(:location_options, option_list(selected_hold_locations))
    |> assign(
      :continent_form,
      data_form(:continent, continent_form_attrs(selected_path.continent))
    )
    |> assign(
      :province_form,
      data_form(:province, province_form_attrs(selected_path.province, selected_continent_id))
    )
    |> assign(
      :hold_form,
      data_form(
        :hold,
        hold_form_attrs(selected_hold, selected_path.province, selected_province_id)
      )
    )
    |> assign(:location_type_form, data_form(:location_type))
    |> assign(
      :location_type_delete_form,
      data_form(:location_type_delete, %{"id" => first_id(location_types)})
    )
    |> assign(
      :location_form,
      data_form(:location, %{
        "hold_id" => selected_or_first_id(selected_hold, holds),
        "location_type_id" => first_id(location_types),
        "capital" => "false"
      })
    )
    |> assign(
      :location_edit_form,
      data_form(:location_edit, location_edit_attrs(selected_location, selected_hold))
    )
    |> assign(
      :commerce_form,
      data_form(:commerce, %{
        "kind" => "income",
        "currency" => commerce_currency(selected_hold_commerce_entries, selected_path.continent),
        "frequency" => "monthly"
      })
    )
    |> assign(
      :political_office_form,
      data_form(:political_office, %{
        "scope" => "hold",
        "hold_id" => selected_or_first_id(selected_hold, holds),
        "province_id" => selected_province_id,
        "character_id" => nil
      })
    )
    |> assign(
      :political_office_edit_form,
      data_form(
        :political_office_edit,
        political_office_edit_attrs(selected_political_office)
      )
    )
    |> assign(
      :race_form,
      data_form(:race, race_form_attrs())
    )
    |> assign(:race_form_params, race_form_attrs())
    |> assign(:guild_form, data_form(:guild))
    |> assign(
      :guild_influence_form,
      data_form(:guild_influence, %{
        "guild_id" => selected_or_first_id(selected_guild, guilds),
        "god_id" => nil,
        "character_id" => nil,
        "relationship" => "serves"
      })
    )
    |> assign(:god_form, data_form(:god))
    |> assign(:character_role_form, data_form(:character_role))
    |> assign(
      :character_form,
      data_form(:character, character_form_attrs(selected_character))
    )
    |> assign(
      :inventory_category_form,
      data_form(:inventory_category, %{
        "position" => next_inventory_category_position(selected_character)
      })
    )
    |> assign(
      :inventory_item_form,
      data_form(:inventory_item, %{
        "item_id" => first_id(items),
        "inventory_category_id" => first_id(selected_character_inventory_categories),
        "quantity" => 1,
        "equipped" => "false"
      })
    )
    |> assign(:occupation_form, data_form(:occupation))
    |> assign(:skill_form, data_form(:skill))
    |> assign(:skill_edit_form, data_form(:skill_edit, skill_edit_attrs(selected_skill)))
    |> assign(
      :skill_level_form,
      data_form(:skill_level, %{
        "rank" => next_skill_level_rank(selected_skill),
        "minimum_value" => next_skill_level_minimum(selected_skill)
      })
    )
    |> assign(
      :skill_perk_form,
      data_form(:skill_perk, %{
        "required_level" => next_skill_perk_required_level(selected_skill),
        "ranks" => 1,
        "position" => next_skill_perk_position(selected_skill)
      })
    )
    |> assign(:spell_form, data_form(:spell))
    |> assign(:spell_edit_form, data_form(:spell_edit, spell_edit_attrs(selected_spell)))
    |> assign(:item_form, data_form(:item, %{"category" => "weapon", "source" => "Skyrim"}))
    |> assign(:item_edit_form, data_form(:item_edit, item_edit_attrs(selected_item)))
    |> assign(:effect_form, data_form(:effect, %{"category" => "Alchemy"}))
    |> assign(
      :item_effect_form,
      data_form(:item_effect, %{
        "effect_id" => first_id(effects),
        "position" => next_item_effect_position(selected_item)
      })
    )
    |> assign(:creature_type_form, data_form(:creature_type))
    |> assign(
      :creature_form,
      data_form(:creature, %{
        "creature_type_id" => first_id(creature_types),
        "danger_level" => "common"
      })
    )
    |> assign(
      :creature_edit_form,
      data_form(:creature_edit, creature_edit_attrs(selected_creature))
    )
    |> assign(
      :creature_location_form,
      data_form(:creature_location, %{
        "creature_id" => selected_or_first_id(selected_creature, creatures),
        "location_id" => first_id(locations),
        "presence" => "common"
      })
    )
    |> assign(:calendar_form, data_form(:calendar, %{"continent_id" => first_id(continents)}))
    |> assign(:civilization_form, data_form(:civilization, %{"timeline_era_id" => nil}))
    |> assign(:timeline_form, data_form(:timeline))
    |> assign(
      :timeline_era_form,
      data_form(:timeline_era, %{
        "timeline_id" => selected_or_first_id(selected_timeline, timelines),
        "position" => next_timeline_era_position(selected_timeline)
      })
    )
    |> assign(
      :timeline_event_form,
      data_form(:timeline_event, %{
        "timeline_id" => selected_or_first_id(selected_timeline, timelines),
        "timeline_era_id" => first_id(timeline_eras(selected_timeline)),
        "position" => next_timeline_event_position(selected_timeline)
      })
    )
    |> assign(
      :calendar_month_form,
      data_form(:calendar_month, %{
        "days" => 30,
        "position" => next_calendar_month_position(selected_calendar)
      })
    )
    |> assign(
      :calendar_edit_form,
      data_form(:calendar_edit, calendar_edit_attrs(selected_calendar))
    )
    |> assign(
      :document_form,
      data_form(:document, %{
        "kind" => "book",
        "source" => "Skyrim"
      })
    )
    |> assign(
      :document_edit_form,
      data_form(:document_edit, document_edit_attrs(selected_document))
    )
    |> assign(
      :lore_connection_form,
      data_form(:lore_connection, %{
        "connection_type" => "ally",
        "status" => "active",
        "source_entity" => first_lore_connection_entity(lore_connection_entity_options),
        "target_entity" => first_lore_connection_entity(lore_connection_entity_options)
      })
    )
    |> assign(
      :lore_connection_edit_form,
      data_form(:lore_connection_edit, lore_connection_edit_attrs(selected_lore_connection))
    )
  end

  defp reload_params(socket) do
    %{
      "section" => socket.assigns.section,
      "continent_id" => selected_continent_id(socket),
      "province_id" => selected_province_id(socket),
      "hold_id" => selected_hold_id(socket),
      "location_id" => selected_location_id(socket),
      "race_id" => selected_record_id(socket.assigns[:selected_race]),
      "guild_id" => selected_record_id(socket.assigns[:selected_guild]),
      "god_id" => selected_record_id(socket.assigns[:selected_god]),
      "character_id" => selected_record_id(socket.assigns[:selected_character]),
      "creature_id" => selected_record_id(socket.assigns[:selected_creature]),
      "document_id" => selected_record_id(socket.assigns[:selected_document]),
      "item_id" => selected_record_id(socket.assigns[:selected_item]),
      "political_office_id" => selected_record_id(socket.assigns[:selected_political_office]),
      "connection_id" => selected_record_id(socket.assigns[:selected_lore_connection]),
      "skill_id" => selected_record_id(socket.assigns[:selected_skill]),
      "spell_id" => selected_record_id(socket.assigns[:selected_spell]),
      "civilization_id" => selected_record_id(socket.assigns[:selected_civilization]),
      "timeline_id" => selected_record_id(socket.assigns[:selected_timeline]),
      "calendar_id" => selected_record_id(socket.assigns[:selected_calendar])
    }
  end

  defp selected_continent_id(socket) do
    case socket.assigns[:selected_path] do
      %{continent: %{id: continent_id}} ->
        continent_id

      _path ->
        nil
    end
  end

  defp selected_province_id(socket) do
    case socket.assigns[:selected_path] do
      %{province: %{id: province_id}} ->
        province_id

      _path ->
        nil
    end
  end

  defp selected_hold_id(socket) do
    case socket.assigns[:selected_hold] do
      nil ->
        nil

      hold ->
        hold.id
    end
  end

  defp selected_location_id(socket) do
    case socket.assigns[:selected_location] do
      nil ->
        nil

      location ->
        location.id
    end
  end

  defp selected_record_id(nil) do
    nil
  end

  defp selected_record_id(record) do
    record.id
  end

  defp select_hold(_holds, nil) do
    nil
  end

  defp select_hold(_holds, "") do
    nil
  end

  defp select_hold(holds, hold_id) do
    Enum.find(holds, &(&1.id == hold_id))
  end

  defp select_location(_locations, nil) do
    nil
  end

  defp select_location(_locations, "") do
    nil
  end

  defp select_location(locations, location_id) do
    Enum.find(locations, &(&1.id == location_id))
  end

  defp select_record(_records, nil) do
    nil
  end

  defp select_record(_records, "") do
    nil
  end

  defp select_record(records, record_id) do
    Enum.find(records, &(&1.id == record_id))
  end

  defp get_continent_in_world(socket, continent_id) do
    get_record_in_options(
      socket.assigns.continent_options,
      continent_id,
      &Worlds.get_continent!/1
    )
  end

  defp get_province_in_world(socket, province_id) do
    get_record_in_options(socket.assigns.province_options, province_id, &Worlds.get_province!/1)
  end

  defp get_guild_in_world(socket, guild_id) do
    get_record_in_options(socket.assigns.guild_options, guild_id, &Worlds.get_guild!/1)
  end

  defp get_god_in_world(socket, god_id) do
    get_record_in_options(socket.assigns.god_options, god_id, &Worlds.get_god!/1)
  end

  defp get_race_in_world(socket, race_id) do
    get_record_in_options(socket.assigns.race_options, race_id, &Worlds.get_race!/1)
  end

  defp get_hold_in_world(socket, hold_id) do
    get_record_in_options(option_list(socket.assigns.holds), hold_id, &Worlds.get_hold!/1)
  end

  defp get_character_in_world(socket, character_id) do
    get_record_in_options(
      socket.assigns.character_options,
      character_id,
      &Worlds.get_character!/1
    )
  end

  defp get_civilization_in_world(socket, civilization_id) do
    get_record_in_options(
      socket.assigns.civilization_options,
      civilization_id,
      &Worlds.get_civilization!/1
    )
  end

  defp get_document_in_world(socket, document_id) do
    get_record_in_options(
      socket.assigns.document_options,
      document_id,
      &Worlds.get_document!/1
    )
  end

  defp get_lore_connection_in_world(socket, lore_connection_id) do
    get_record_in_options(
      socket.assigns.lore_connection_options,
      lore_connection_id,
      &Worlds.get_lore_connection!/1
    )
  end

  defp get_calendar_in_world(socket, calendar_id) do
    get_record_in_options(socket.assigns.calendar_options, calendar_id, &Worlds.get_calendar!/1)
  end

  defp get_timeline_in_world(socket, timeline_id) do
    get_record_in_options(socket.assigns.timeline_options, timeline_id, &Worlds.get_timeline!/1)
  end

  defp get_optional_god_in_world(socket, god_id) do
    get_optional_record_in_options(socket.assigns.god_options, god_id, &Worlds.get_god!/1)
  end

  defp get_optional_character_in_world(socket, character_id) do
    get_optional_record_in_options(
      socket.assigns.character_options,
      character_id,
      &Worlds.get_character!/1
    )
  end

  defp get_optional_character_role_in_world(socket, character_role_id) do
    get_optional_record_in_options(
      socket.assigns.character_role_options,
      character_role_id,
      &Worlds.get_character_role!/1
    )
  end

  defp get_optional_race_in_world(socket, race_id) do
    get_optional_record_in_options(socket.assigns.race_options, race_id, &Worlds.get_race!/1)
  end

  defp get_optional_guild_in_world(socket, guild_id) do
    get_optional_record_in_options(socket.assigns.guild_options, guild_id, &Worlds.get_guild!/1)
  end

  defp get_optional_civilization_in_world(socket, civilization_id) do
    get_optional_record_in_options(
      socket.assigns.civilization_options,
      civilization_id,
      &Worlds.get_civilization!/1
    )
  end

  defp get_optional_occupation_in_world(socket, occupation_id) do
    get_optional_record_in_options(
      socket.assigns.occupation_options,
      occupation_id,
      &Worlds.get_occupation!/1
    )
  end

  defp get_optional_skill_in_world(socket, skill_id) do
    get_optional_record_in_options(socket.assigns.skill_options, skill_id, &Worlds.get_skill!/1)
  end

  defp get_skill_in_world(socket, skill_id) do
    get_record_in_options(socket.assigns.skill_options, skill_id, &Worlds.get_skill!/1)
  end

  defp get_skill_level_in_selected_skill(socket, skill_level_id) do
    if socket.assigns.selected_skill &&
         Enum.any?(skill_levels(socket.assigns.selected_skill), &(&1.id == skill_level_id)) do
      {:ok, Worlds.get_skill_level!(skill_level_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_selected_skill_tree(%{assigns: %{selected_skill: %{skill_tree: %{} = skill_tree}}}) do
    {:ok, skill_tree}
  end

  defp get_selected_skill_tree(_socket) do
    {:error, :skill_tree_not_selected}
  end

  defp get_skill_perk_in_selected_skill(socket, perk_id) do
    if socket.assigns.selected_skill &&
         Enum.any?(skill_tree_perks(socket.assigns.selected_skill), &(&1.id == perk_id)) do
      {:ok, Worlds.get_skill_tree_perk!(perk_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_creature_type_in_world(socket, creature_type_id) do
    get_record_in_options(
      socket.assigns.creature_type_options,
      creature_type_id,
      &Worlds.get_creature_type!/1
    )
  end

  defp get_optional_creature_type_in_world(socket, creature_type_id) do
    get_optional_record_in_options(
      socket.assigns.creature_type_options,
      creature_type_id,
      &Worlds.get_creature_type!/1
    )
  end

  defp get_creature_in_world(socket, creature_id) do
    get_record_in_options(socket.assigns.creature_options, creature_id, &Worlds.get_creature!/1)
  end

  defp get_location_in_world(socket, location_id) do
    get_record_in_options(
      socket.assigns.all_location_options,
      location_id,
      &Worlds.get_location!/1
    )
  end

  defp get_creature_location_in_world(socket, creature_location_id) do
    if Enum.any?(socket.assigns.creature_locations, &(&1.id == creature_location_id)) do
      {:ok, Worlds.get_creature_location!(creature_location_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_spell_in_world(socket, spell_id) do
    get_record_in_options(socket.assigns.spell_options, spell_id, &Worlds.get_spell!/1)
  end

  defp get_item_in_world(socket, item_id) do
    get_record_in_options(socket.assigns.item_options, item_id, &Worlds.get_item!/1)
  end

  defp get_effect_in_world(socket, effect_id) do
    get_record_in_options(socket.assigns.effect_options, effect_id, &Worlds.get_effect!/1)
  end

  defp get_political_office_in_world(socket, political_office_id) do
    get_record_in_options(
      socket.assigns.political_office_options,
      political_office_id,
      &Worlds.get_political_office!/1
    )
  end

  defp get_optional_timeline_era_in_world(socket, timeline_era_id) do
    get_optional_record_in_options(
      socket.assigns.timeline_era_options,
      timeline_era_id,
      &Worlds.get_timeline_era!/1
    )
  end

  defp get_optional_location_in_world(socket, location_id) do
    get_optional_record_in_options(
      socket.assigns.all_location_options,
      location_id,
      &Worlds.get_location!/1
    )
  end

  defp get_selected_hold(socket, hold_id) do
    case socket.assigns.selected_hold do
      %{id: ^hold_id} = hold ->
        {:ok, hold}

      _other_hold ->
        {:error, :hold_not_selected}
    end
  end

  defp get_selected_hold(%{assigns: %{selected_hold: %{} = hold}}) do
    {:ok, hold}
  end

  defp get_selected_hold(_socket) do
    {:error, :hold_not_selected}
  end

  defp get_selected_continent(%{assigns: %{selected_path: %{continent: %{} = continent}}}) do
    {:ok, continent}
  end

  defp get_selected_continent(_socket) do
    {:error, :continent_not_selected}
  end

  defp get_selected_province(%{assigns: %{selected_path: %{province: %{} = province}}}) do
    {:ok, province}
  end

  defp get_selected_province(_socket) do
    {:error, :province_not_selected}
  end

  defp get_location_type_in_world(socket, location_type_id) do
    get_record_in_options(
      socket.assigns.location_type_options,
      location_type_id,
      &Worlds.get_location_type!/1
    )
  end

  defp get_selected_location(%{assigns: %{selected_location: %{} = location}}) do
    {:ok, location}
  end

  defp get_selected_location(_socket) do
    {:error, :location_not_selected}
  end

  defp get_selected_calendar(%{assigns: %{selected_calendar: %{} = calendar}}) do
    {:ok, calendar}
  end

  defp get_selected_calendar(_socket) do
    {:error, :calendar_not_selected}
  end

  defp get_selected_skill(%{assigns: %{selected_skill: %{} = skill}}) do
    {:ok, skill}
  end

  defp get_selected_skill(_socket) do
    {:error, :skill_not_selected}
  end

  defp get_selected_spell(%{assigns: %{selected_spell: %{} = spell}}) do
    {:ok, spell}
  end

  defp get_selected_spell(_socket) do
    {:error, :spell_not_selected}
  end

  defp get_selected_item(%{assigns: %{selected_item: %{} = item}}) do
    {:ok, item}
  end

  defp get_selected_item(_socket) do
    {:error, :item_not_selected}
  end

  defp get_selected_character(%{assigns: %{selected_character: %{} = character}}) do
    {:ok, character}
  end

  defp get_selected_character(_socket) do
    {:error, :character_not_selected}
  end

  defp get_selected_creature(%{assigns: %{selected_creature: %{} = creature}}) do
    {:ok, creature}
  end

  defp get_selected_creature(_socket) do
    {:error, :creature_not_selected}
  end

  defp get_selected_document(%{assigns: %{selected_document: %{} = document}}) do
    {:ok, document}
  end

  defp get_selected_document(_socket) do
    {:error, :document_not_selected}
  end

  defp get_selected_lore_connection(%{
         assigns: %{selected_lore_connection: %{} = lore_connection}
       }) do
    {:ok, lore_connection}
  end

  defp get_selected_lore_connection(_socket) do
    {:error, :lore_connection_not_selected}
  end

  defp get_parent_location_in_selected_hold(_socket, parent_location_id)
       when parent_location_id in [nil, ""] do
    {:ok, nil}
  end

  defp get_parent_location_in_selected_hold(socket, parent_location_id) do
    get_record_in_options(
      option_list(socket.assigns.selected_hold_locations),
      parent_location_id,
      &Worlds.get_location!/1
    )
  end

  defp get_record_in_options(options, record_id, fetch_record) do
    if option_id?(options, record_id) do
      {:ok, fetch_record.(record_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_optional_record_in_options(_options, record_id, _fetch_record)
       when record_id in [nil, ""] do
    {:ok, nil}
  end

  defp get_optional_record_in_options(options, record_id, fetch_record) do
    get_record_in_options(options, record_id, fetch_record)
  end

  defp get_guild_influence_in_world(socket, guild_influence_id) do
    if Enum.any?(flat_guild_influences(socket.assigns.guilds), &(&1.id == guild_influence_id)) do
      {:ok, Worlds.get_guild_influence!(guild_influence_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_calendar_month_in_selected_calendar(socket, month_id) do
    if socket.assigns.selected_calendar &&
         Enum.any?(calendar_months(socket.assigns.selected_calendar), &(&1.id == month_id)) do
      {:ok, Worlds.get_calendar_month!(month_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_commerce_in_selected_hold(socket, commerce_id) do
    if socket.assigns.selected_hold &&
         Enum.any?(
           selected_hold_commerce_entries(socket.assigns.selected_hold),
           &(&1.id == commerce_id)
         ) do
      {:ok, Worlds.get_hold_commerce_entry!(commerce_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_inventory_category_in_selected_character(socket, inventory_category_id) do
    if socket.assigns.selected_character &&
         Enum.any?(
           character_inventory_categories(socket.assigns.selected_character),
           &(&1.id == inventory_category_id)
         ) do
      {:ok, Worlds.get_inventory_category!(inventory_category_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_optional_inventory_category_in_selected_character(_socket, inventory_category_id)
       when inventory_category_id in [nil, ""] do
    {:ok, nil}
  end

  defp get_optional_inventory_category_in_selected_character(socket, inventory_category_id) do
    get_inventory_category_in_selected_character(socket, inventory_category_id)
  end

  defp get_inventory_item_in_selected_character(socket, inventory_item_id) do
    if socket.assigns.selected_character &&
         Enum.any?(
           character_inventory_items(socket.assigns.selected_character),
           &(&1.id == inventory_item_id)
         ) do
      {:ok, Worlds.get_inventory_item!(inventory_item_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_item_effect_in_selected_item(socket, item_effect_id) do
    if socket.assigns.selected_item &&
         Enum.any?(item_effects(socket.assigns.selected_item), &(&1.id == item_effect_id)) do
      {:ok, Worlds.get_item_effect!(item_effect_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_timeline_era_in_world(socket, timeline_era_id) do
    get_record_in_options(
      socket.assigns.timeline_era_options,
      timeline_era_id,
      &Worlds.get_timeline_era!/1
    )
  end

  defp get_timeline_event_in_world(socket, timeline_event_id) do
    get_record_in_options(
      socket.assigns.timeline_event_options,
      timeline_event_id,
      &Worlds.get_timeline_event!/1
    )
  end

  defp guild_influence_refs(nil, nil) do
    {:error, :missing_influence_target}
  end

  defp guild_influence_refs(%{}, %{}) do
    {:error, :too_many_influence_targets}
  end

  defp guild_influence_refs(god, character) do
    {:ok, %{god: god, character: character}}
  end

  defp political_office_refs(socket, %{"scope" => "province"} = params) do
    with {:ok, province} <- get_province_in_world(socket, params["province_id"]),
         {:ok, character} <- get_optional_character_in_world(socket, params["character_id"]) do
      {:ok, %{province: province, character: character}}
    end
  end

  defp political_office_refs(socket, %{"scope" => "hold"} = params) do
    with {:ok, hold} <- get_selected_hold(socket, params["hold_id"]),
         {:ok, character} <- get_optional_character_in_world(socket, params["character_id"]) do
      {:ok, %{hold: hold, character: character}}
    end
  end

  defp political_office_refs(_socket, _params) do
    {:error, :invalid_political_scope}
  end

  defp document_refs(socket, params) do
    with {:ok, author_character} <-
           get_optional_character_in_world(socket, params["author_character_id"]),
         {:ok, location} <- get_optional_location_in_world(socket, params["location_id"]),
         {:ok, guild} <- get_optional_guild_in_world(socket, params["guild_id"]),
         {:ok, god} <- get_optional_god_in_world(socket, params["god_id"]),
         {:ok, race} <- get_optional_race_in_world(socket, params["race_id"]),
         {:ok, civilization} <-
           get_optional_civilization_in_world(socket, params["civilization_id"]) do
      {:ok,
       %{
         author_character: author_character,
         location: location,
         guild: guild,
         god: god,
         race: race,
         civilization: civilization
       }}
    end
  end

  defp lore_connection_refs(socket, params) do
    with {:ok, source} <- lore_connection_endpoint(socket, params["source_entity"]),
         {:ok, target} <- lore_connection_endpoint(socket, params["target_entity"]) do
      {:ok, %{source: source, target: target}}
    end
  end

  defp lore_connection_endpoint(_socket, value) when value in [nil, ""] do
    {:error, :lore_connection_endpoint_required}
  end

  defp lore_connection_endpoint(socket, value) do
    case String.split(value, ":", parts: 2) do
      [kind, record_id] ->
        lore_connection_endpoint_record(socket, kind, record_id)

      _invalid ->
        {:error, :invalid_lore_connection_endpoint}
    end
  end

  defp lore_connection_endpoint_record(socket, "character", record_id) do
    with {:ok, record} <- get_character_in_world(socket, record_id) do
      {:ok, {:character, record}}
    end
  end

  defp lore_connection_endpoint_record(socket, "civilization", record_id) do
    with {:ok, record} <- get_civilization_in_world(socket, record_id) do
      {:ok, {:civilization, record}}
    end
  end

  defp lore_connection_endpoint_record(socket, "continent", record_id) do
    with {:ok, record} <- get_continent_in_world(socket, record_id) do
      {:ok, {:continent, record}}
    end
  end

  defp lore_connection_endpoint_record(socket, "god", record_id) do
    with {:ok, record} <- get_god_in_world(socket, record_id) do
      {:ok, {:god, record}}
    end
  end

  defp lore_connection_endpoint_record(socket, "guild", record_id) do
    with {:ok, record} <- get_guild_in_world(socket, record_id) do
      {:ok, {:guild, record}}
    end
  end

  defp lore_connection_endpoint_record(socket, "hold", record_id) do
    with {:ok, record} <- get_hold_in_world(socket, record_id) do
      {:ok, {:hold, record}}
    end
  end

  defp lore_connection_endpoint_record(socket, "location", record_id) do
    with {:ok, record} <- get_location_in_world(socket, record_id) do
      {:ok, {:location, record}}
    end
  end

  defp lore_connection_endpoint_record(socket, "province", record_id) do
    with {:ok, record} <- get_province_in_world(socket, record_id) do
      {:ok, {:province, record}}
    end
  end

  defp lore_connection_endpoint_record(socket, "race", record_id) do
    with {:ok, record} <- get_race_in_world(socket, record_id) do
      {:ok, {:race, record}}
    end
  end

  defp lore_connection_endpoint_record(_socket, _kind, _record_id) do
    {:error, :invalid_lore_connection_endpoint}
  end

  defp select_path(_continents, nil, nil, nil) do
    %{continent: nil, province: nil}
  end

  defp select_path(continents, selected_hold, _selected_province, _selected_continent)
       when not is_nil(selected_hold) do
    Enum.reduce_while(continents, %{continent: nil, province: nil}, fn continent, _acc ->
      case Enum.find(continent.provinces, fn province ->
             Enum.any?(province.holds, &(&1.id == selected_hold.id))
           end) do
        nil ->
          {:cont, %{continent: nil, province: nil}}

        province ->
          {:halt, %{continent: continent, province: province}}
      end
    end)
  end

  defp select_path(continents, nil, selected_province, _selected_continent)
       when not is_nil(selected_province) do
    Enum.reduce_while(continents, %{continent: nil, province: selected_province}, fn
      continent, _acc ->
        if Enum.any?(continent.provinces, &(&1.id == selected_province.id)) do
          {:halt, %{continent: continent, province: selected_province}}
        else
          {:cont, %{continent: nil, province: selected_province}}
        end
    end)
  end

  defp select_path(_continents, nil, nil, selected_continent) do
    %{continent: selected_continent, province: nil}
  end

  defp flat_provinces(continents) do
    continents
    |> Enum.flat_map(& &1.provinces)
    |> sorted()
  end

  defp flat_holds(provinces) do
    provinces
    |> Enum.flat_map(& &1.holds)
    |> sorted()
  end

  defp flat_locations(holds) do
    holds
    |> Enum.flat_map(&selected_hold_locations/1)
    |> Enum.uniq_by(& &1.id)
    |> sorted()
  end

  defp flat_calendars(continents) do
    continents
    |> Enum.flat_map(& &1.calendars)
    |> sorted()
  end

  defp flat_timeline_eras(timelines) do
    timelines
    |> Enum.flat_map(& &1.eras)
    |> Enum.sort_by(&{&1.position, &1.name})
  end

  defp flat_timeline_events(timelines) do
    timelines
    |> Enum.flat_map(&timeline_events/1)
    |> Enum.sort_by(&{&1.position, &1.name})
  end

  defp flat_creature_locations(creatures) do
    creatures
    |> Enum.flat_map(& &1.creature_locations)
    |> Enum.sort_by(&{record_name(&1.creature), record_name(&1.location)})
  end

  defp selected_hold_commerce_entries(nil) do
    []
  end

  defp selected_hold_commerce_entries(hold) do
    hold.commerce_entries
    |> Enum.sort_by(&{&1.kind, &1.name})
  end

  defp selected_province_political_offices(nil) do
    []
  end

  defp selected_province_political_offices(province) do
    province.political_offices
    |> Enum.sort_by(&{&1.office, record_name(&1.character)})
  end

  defp selected_hold_political_offices(nil) do
    []
  end

  defp selected_hold_political_offices(hold) do
    hold.political_offices
    |> Enum.sort_by(&{&1.office, record_name(&1.character)})
  end

  defp selected_political_offices(
         _selected_province,
         %{} = _selected_hold,
         _province_offices,
         hold_offices
       ) do
    hold_offices
  end

  defp selected_political_offices(%{} = _selected_province, nil, province_offices, _hold_offices) do
    province_offices
  end

  defp selected_political_offices(
         _selected_province,
         _selected_hold,
         _province_offices,
         _hold_offices
       ) do
    []
  end

  defp selected_hold_locations(nil) do
    []
  end

  defp selected_hold_locations(hold) do
    hold.locations
    |> Enum.flat_map(&locations_with_loaded_children/1)
    |> Enum.uniq_by(& &1.id)
    |> sorted_locations_with_roots_first()
  end

  defp locations_with_loaded_children(location) do
    children =
      if Ecto.assoc_loaded?(location.child_locations) do
        location.child_locations
      else
        []
      end

    [location | children]
  end

  defp data_form(name, attrs \\ %{}) do
    attrs
    |> Map.merge(%{"name" => "", "description" => "", "visibility" => "known"}, fn
      _key, value, _default -> value
    end)
    |> to_form(as: name)
  end

  defp continent_form_attrs(nil) do
    %{"visibility" => "known"}
  end

  defp continent_form_attrs(continent) do
    %{
      "name" => continent.name,
      "description" => continent.description,
      "map_x" => continent.map_x,
      "map_y" => continent.map_y,
      "visibility" => continent.visibility,
      "currency_name" => continent_currency_name(continent),
      "currency_description" => continent_currency_description(continent)
    }
  end

  defp continent_attrs(params) do
    Map.take(params, ["name", "description", "map_x", "map_y", "visibility"])
  end

  defp continent_currency_attrs(params) do
    %{
      "name" => Map.get(params, "currency_name"),
      "description" => Map.get(params, "currency_description")
    }
  end

  defp province_form_attrs(nil, continent_id) do
    %{"continent_id" => continent_id, "visibility" => "known"}
  end

  defp province_form_attrs(province, _continent_id) do
    %{
      "continent_id" => province.continent_id,
      "name" => province.name,
      "terrain" => province.terrain,
      "climate" => province.climate,
      "map_x" => province.map_x,
      "map_y" => province.map_y,
      "visibility" => province.visibility,
      "description" => province.description
    }
  end

  defp hold_form_attrs(nil, _selected_province, province_id) do
    %{"province_id" => province_id, "visibility" => "known"}
  end

  defp hold_form_attrs(hold, selected_province, _province_id) do
    %{
      "province_id" => hold.province_id,
      "name" => hold.name,
      "terrain" => hold.terrain,
      "climate" => hold.climate,
      "map_x" => hold.map_x,
      "map_y" => hold.map_y,
      "visibility" => hold.visibility,
      "description" => hold.description,
      "province_capital" => to_string(province_capital_hold?(selected_province, hold))
    }
  end

  defp character_form_attrs(nil) do
    %{
      "character_role_id" => nil,
      "race_id" => nil,
      "gender" => nil,
      "guild_id" => nil,
      "home_location_id" => nil,
      "occupation_id" => nil,
      "skill_id" => nil,
      "status" => "alive"
    }
  end

  defp character_form_attrs(character) do
    %{
      "name" => character.name,
      "character_role_id" => character.character_role_id,
      "gender" => character.gender,
      "title" => character.title,
      "role" => character.role,
      "politics" => character.politics,
      "status" => character.status || "alive",
      "race_id" => character.race_id,
      "guild_id" => character.guild_id,
      "home_location_id" => character.home_location_id,
      "occupation_id" => nil,
      "skill_id" => nil,
      "description" => character.description
    }
  end

  defp character_attrs(params, character_role) do
    params
    |> Map.drop([
      "character_role_id",
      "race_id",
      "guild_id",
      "home_location_id",
      "occupation_id",
      "skill_id"
    ])
    |> Map.put("role", character_role_name(character_role))
  end

  defp province_capital_hold?(%{capital_hold_id: hold_id}, %{id: hold_id}) do
    true
  end

  defp province_capital_hold?(_province, _hold) do
    false
  end

  defp assign_race_form(socket, params) do
    params = race_form_attrs(params)

    socket
    |> assign(:race_form_params, params)
    |> assign(:race_form, data_form(:race, params))
  end

  defp race_form_attrs(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.merge(%{"name" => "", "description" => ""}, fn _key, value, _default -> value end)
      |> Map.put_new("civilization_id", nil)

    Map.put(
      attrs,
      "traits",
      race_trait_attrs_list(Map.get(attrs, "traits", Map.get(attrs, :traits)))
    )
  end

  defp race_trait_attrs_list(nil) do
    [race_trait_attrs()]
  end

  defp race_trait_attrs_list(traits) when is_list(traits) do
    Enum.map(traits, &race_trait_attrs/1)
  end

  defp race_trait_attrs_list(traits) when is_map(traits) do
    traits
    |> Enum.sort_by(fn {index, _attrs} -> sortable_form_index(index) end)
    |> Enum.map(fn {_index, attrs} -> race_trait_attrs(attrs) end)
  end

  defp race_trait_attrs_list(_traits) do
    [race_trait_attrs()]
  end

  defp race_trait_attrs(category \\ "perk")

  defp race_trait_attrs(category) when category in ["power", "perk", :power, :perk] do
    %{"category" => category, "name" => "", "description" => ""}
  end

  defp race_trait_attrs(attrs) when is_map(attrs) do
    %{
      "category" => Map.get(attrs, "category", Map.get(attrs, :category, "perk")),
      "name" => Map.get(attrs, "name", Map.get(attrs, :name, "")),
      "description" => Map.get(attrs, "description", Map.get(attrs, :description, ""))
    }
  end

  defp race_trait_attrs(_attrs) do
    race_trait_attrs("perk")
  end

  defp delete_race_trait_at(traits, index) do
    case Integer.parse(to_string(index)) do
      {index, ""} when index >= 0 ->
        List.delete_at(traits, index)

      _other ->
        traits
    end
  end

  defp sortable_form_index(index) do
    index = to_string(index)

    case Integer.parse(index) do
      {number, ""} -> {0, number}
      _other -> {1, index}
    end
  end

  defp location_edit_attrs(nil, _selected_hold) do
    %{}
  end

  defp location_edit_attrs(location, selected_hold) do
    %{
      "name" => location.name,
      "description" => location.description,
      "map_x" => location.map_x,
      "map_y" => location.map_y,
      "visibility" => location.visibility,
      "location_type_id" => location.location_type_id,
      "capital" => to_string(selected_hold && selected_hold.capital_location_id == location.id)
    }
  end

  defp calendar_edit_attrs(nil) do
    %{}
  end

  defp calendar_edit_attrs(calendar) do
    %{
      "name" => calendar.name,
      "description" => calendar.description,
      "days_per_week" => calendar.days_per_week,
      "era" => calendar.era,
      "year_start_angle" => calendar.year_start_angle,
      "perihelion_day" => calendar.perihelion_day
    }
  end

  defp document_edit_attrs(nil) do
    %{}
  end

  defp document_edit_attrs(document) do
    %{
      "title" => document.title,
      "kind" => document.kind,
      "source" => document.source,
      "summary" => document.summary,
      "content" => document.content,
      "author_character_id" => selected_record_id(document.author_character),
      "location_id" => selected_record_id(document.location),
      "guild_id" => selected_record_id(document.guild),
      "god_id" => selected_record_id(document.god),
      "race_id" => selected_record_id(document.race),
      "civilization_id" => selected_record_id(document.civilization)
    }
  end

  defp lore_connection_edit_attrs(nil) do
    %{}
  end

  defp lore_connection_edit_attrs(lore_connection) do
    %{
      "name" => lore_connection.name,
      "connection_type" => lore_connection.connection_type,
      "status" => lore_connection.status,
      "started_at" => lore_connection.started_at,
      "ended_at" => lore_connection.ended_at,
      "description" => lore_connection.description,
      "source_entity" => lore_connection_endpoint_value(lore_connection, :source),
      "target_entity" => lore_connection_endpoint_value(lore_connection, :target)
    }
  end

  defp skill_edit_attrs(nil) do
    %{}
  end

  defp skill_edit_attrs(skill) do
    %{
      "name" => skill.name,
      "category" => skill.category,
      "description" => skill.description
    }
  end

  defp spell_edit_attrs(nil) do
    %{}
  end

  defp spell_edit_attrs(spell) do
    %{
      "name" => spell.name,
      "school" => spell.school,
      "level" => spell.level,
      "magicka_cost" => spell.magicka_cost,
      "source" => spell.source,
      "description" => spell.description
    }
  end

  defp creature_edit_attrs(nil) do
    %{}
  end

  defp creature_edit_attrs(creature) do
    %{
      "name" => creature.name,
      "creature_type_id" => creature.creature_type_id,
      "habitat" => creature.habitat,
      "temperament" => creature.temperament,
      "danger_level" => creature.danger_level,
      "description" => creature.description
    }
  end

  defp item_edit_attrs(nil) do
    %{}
  end

  defp item_edit_attrs(item) do
    %{
      "name" => item.name,
      "category" => item.category,
      "kind" => item.kind,
      "material" => item.material,
      "hands" => item.hands,
      "damage" => item.damage,
      "critical_damage" => item.critical_damage,
      "weight" => item.weight,
      "value" => item.value,
      "source" => item.source,
      "description" => item.description
    }
  end

  defp item_category_options do
    [
      {"Apparel", "apparel"},
      {"Books", "book"},
      {"Crafting Materials", "crafting_material"},
      {"Food", "food"},
      {"Ingredients", "ingredient"},
      {"Keys", "key"},
      {"Misc", "misc"},
      {"Poisons", "poison"},
      {"Potions", "potion"},
      {"Scrolls", "scroll"},
      {"Tools", "tool"},
      {"Weapons", "weapon"}
    ]
  end

  defp document_kind_options do
    [
      {"Book", "book"},
      {"Contract", "contract"},
      {"Journal", "journal"},
      {"Law", "law"},
      {"Letter", "letter"},
      {"Map", "map"},
      {"Note", "note"},
      {"Other", "other"},
      {"Prophecy", "prophecy"},
      {"Recipe", "recipe"},
      {"Record", "record"},
      {"Rumor", "rumor"}
    ]
  end

  defp item_category_label(nil) do
    "None"
  end

  defp item_category_label(category) do
    item_category_options()
    |> Enum.find_value(category, fn {label, value} ->
      if value == category do
        label
      end
    end)
  end

  defp grouped_items(items) do
    items
    |> Enum.group_by(& &1.category)
    |> Enum.sort_by(fn {category, _category_items} ->
      {item_category_position(category), item_category_label(category)}
    end)
  end

  defp grouped_characters(characters) do
    characters
    |> Enum.group_by(&character_race_group_name/1)
    |> Enum.sort_by(fn {race, _characters} -> String.downcase(race) end)
    |> Enum.map(fn {race, characters} -> {race, sorted_characters_by_role(characters)} end)
  end

  defp character_race_group_name(%{race: %{name: name}}) when name not in [nil, ""] do
    name
  end

  defp character_race_group_name(_character) do
    "No Race"
  end

  defp sorted_characters_by_role(characters) do
    Enum.sort_by(characters, fn character ->
      {String.downcase(character_role_sort_value(character)), String.downcase(character.name)}
    end)
  end

  defp character_role_sort_value(character) do
    character
    |> character_role_name()
    |> case do
      nil -> ""
      role -> role
    end
  end

  defp grouped_documents(documents) do
    documents
    |> Enum.group_by(& &1.kind)
    |> Enum.sort_by(fn {kind, _kind_documents} -> display_value(kind) end)
  end

  defp grouped_lore_connections(lore_connections) do
    lore_connections
    |> Enum.group_by(&lore_connection_endpoint_label(&1, :source))
    |> Enum.sort_by(fn {source, _source_lore_connections} ->
      source
    end)
  end

  defp grouped_gods(gods) do
    gods
    |> Enum.group_by(& &1.pantheon)
    |> Enum.sort_by(fn {pantheon, _pantheon_gods} -> display_value(pantheon) end)
  end

  defp grouped_spells(spells) do
    spells
    |> Enum.group_by(& &1.school)
    |> Enum.sort_by(fn {school, _school_spells} -> display_value(school) end)
  end

  defp grouped_skills(skills) do
    skills
    |> Enum.group_by(& &1.category)
    |> Enum.sort_by(fn {category, _category_skills} -> display_value(category) end)
  end

  defp grouped_creatures(creatures) do
    creatures
    |> Enum.group_by(&record_name(&1.creature_type))
    |> Enum.sort_by(fn {creature_type, _type_creatures} -> creature_type end)
  end

  defp toggle_folded_group(open_folded_groups, key) do
    if MapSet.member?(open_folded_groups, key) do
      MapSet.delete(open_folded_groups, key)
    else
      MapSet.put(open_folded_groups, key)
    end
  end

  defp folded_group_open?(open_folded_groups, section, value) do
    MapSet.member?(open_folded_groups, folded_group_key(section, value))
  end

  defp folded_group_key(section, value) do
    "#{section}:#{value_key(value)}"
  end

  defp folded_group_dom_id(section, value) do
    "folded-#{section}-#{dom_key(value)}"
  end

  defp value_key(nil) do
    "none"
  end

  defp value_key(value) do
    to_string(value)
  end

  defp dom_key(value) do
    value
    |> value_key()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> case do
      "" ->
        "none"

      key ->
        key
    end
  end

  defp item_category_position(category) do
    item_category_options()
    |> Enum.find_index(fn {_label, value} -> value == category end)
    |> case do
      nil ->
        999

      index ->
        index
    end
  end

  defp character_status_label(status) do
    Character.status_options()
    |> Enum.find_value(display_value(status), fn {label, value} ->
      if value == status do
        label
      end
    end)
  end

  defp character_role_name(%{character_role: %{name: name}}) do
    name
  end

  defp character_role_name(%CharacterRole{name: name}) do
    name
  end

  defp character_role_name(%{role: role}) do
    role
  end

  defp character_role_name(_character_or_role) do
    nil
  end

  defp character_gender_label(gender) do
    Character.gender_options()
    |> Enum.find_value(display_value(gender), fn {label, value} ->
      if value == gender do
        label
      end
    end)
  end

  defp political_office_edit_attrs(nil) do
    %{}
  end

  defp political_office_edit_attrs(political_office) do
    %{
      "id" => political_office.id,
      "character_id" => selected_record_id(political_office.character),
      "office" => political_office.office,
      "politics" => political_office.politics,
      "description" => political_office.description
    }
  end

  defp option_list(records) do
    records
    |> Enum.map(&{&1.name, &1.id})
    |> sort_options()
  end

  defp option_list(records, label_fun) do
    records
    |> Enum.map(&{label_fun.(&1), &1.id})
    |> sort_options()
  end

  defp political_office_options(records) do
    records
    |> Enum.map(fn political_office ->
      {political_office_label(political_office), political_office.id}
    end)
    |> sort_options()
  end

  defp political_office_label(%{scope: "province"} = political_office) do
    "#{political_office.office} / #{record_name(political_office.province)}"
  end

  defp political_office_label(%{scope: "hold"} = political_office) do
    "#{political_office.office} / #{record_name(political_office.hold)}"
  end

  defp lore_connection_entity_options(
         characters,
         civilizations,
         continents,
         gods,
         guilds,
         holds,
         locations,
         provinces,
         races
       ) do
    [
      lore_connection_entity_group("Character", "character", characters),
      lore_connection_entity_group("Guild", "guild", guilds),
      lore_connection_entity_group("God", "god", gods),
      lore_connection_entity_group("Race", "race", races),
      lore_connection_entity_group("Civilization", "civilization", civilizations),
      lore_connection_entity_group("Location", "location", locations),
      lore_connection_entity_group("Hold", "hold", holds),
      lore_connection_entity_group("Province", "province", provinces),
      lore_connection_entity_group("Continent", "continent", continents)
    ]
    |> List.flatten()
  end

  defp lore_connection_entity_group(label, kind, records) do
    records
    |> Enum.map(fn record ->
      {"#{label} / #{record.name}", "#{kind}:#{record.id}"}
    end)
    |> sort_options()
  end

  defp sort_options(options) do
    Enum.sort_by(options, fn {label, _value} ->
      label
      |> to_string()
      |> String.downcase()
    end)
  end

  defp first_lore_connection_entity([{_label, value} | _options]) do
    value
  end

  defp first_lore_connection_entity([]) do
    nil
  end

  defp lore_connection_name(lore_connection) do
    lore_connection.name || lore_connection_label(lore_connection)
  end

  defp lore_connection_label(lore_connection) do
    "#{lore_connection_endpoint_label(lore_connection, :source)} #{lore_connection.connection_type} #{lore_connection_endpoint_label(lore_connection, :target)}"
  end

  defp lore_connection_endpoint_label(lore_connection, side) do
    lore_connection
    |> lore_connection_endpoint_record(side)
    |> case do
      {kind, record} ->
        "#{lore_connection_kind_label(kind)} / #{record.name}"

      nil ->
        "Unassigned"
    end
  end

  defp lore_connection_endpoint_value(lore_connection, side) do
    lore_connection
    |> lore_connection_endpoint_record(side)
    |> case do
      {kind, record} ->
        "#{kind}:#{record.id}"

      nil ->
        nil
    end
  end

  defp lore_connection_endpoint_record(lore_connection, :source) do
    lore_connection_endpoint_record(lore_connection, "source")
  end

  defp lore_connection_endpoint_record(lore_connection, :target) do
    lore_connection_endpoint_record(lore_connection, "target")
  end

  defp lore_connection_endpoint_record(lore_connection, side) do
    [
      {:character, Map.get(lore_connection, :"#{side}_character")},
      {:guild, Map.get(lore_connection, :"#{side}_guild")},
      {:god, Map.get(lore_connection, :"#{side}_god")},
      {:race, Map.get(lore_connection, :"#{side}_race")},
      {:civilization, Map.get(lore_connection, :"#{side}_civilization")},
      {:location, Map.get(lore_connection, :"#{side}_location")},
      {:hold, Map.get(lore_connection, :"#{side}_hold")},
      {:province, Map.get(lore_connection, :"#{side}_province")},
      {:continent, Map.get(lore_connection, :"#{side}_continent")}
    ]
    |> Enum.find(fn {_kind, record} -> record end)
  end

  defp lore_connection_kind_label(:character) do
    "Character"
  end

  defp lore_connection_kind_label(:civilization) do
    "Civilization"
  end

  defp lore_connection_kind_label(:continent) do
    "Continent"
  end

  defp lore_connection_kind_label(:god) do
    "God"
  end

  defp lore_connection_kind_label(:guild) do
    "Guild"
  end

  defp lore_connection_kind_label(:hold) do
    "Hold"
  end

  defp lore_connection_kind_label(:location) do
    "Location"
  end

  defp lore_connection_kind_label(:province) do
    "Province"
  end

  defp lore_connection_kind_label(:race) do
    "Race"
  end

  defp first_id([record | _records]) do
    record.id
  end

  defp first_id([]) do
    nil
  end

  defp first_record([record | _records]) do
    record
  end

  defp first_record([]) do
    nil
  end

  defp selected_or_first_id(nil, records) do
    first_id(records)
  end

  defp selected_or_first_id(record, _records) do
    record.id
  end

  defp option_id?(options, record_id) do
    Enum.any?(options, fn {_label, id} -> id == record_id end)
  end

  defp normalize_section(section)
       when section in ~w(bestiary calendar characters civilizations connections documents geography gods guilds items races skills spells timeline) do
    section
  end

  defp normalize_section(_section) do
    "geography"
  end

  defp section_label("bestiary") do
    "Bestiary"
  end

  defp section_label("races") do
    "Races"
  end

  defp section_label("guilds") do
    "Guilds"
  end

  defp section_label("gods") do
    "Gods"
  end

  defp section_label("characters") do
    "Characters"
  end

  defp section_label("skills") do
    "Skills"
  end

  defp section_label("spells") do
    "Spells"
  end

  defp section_label("items") do
    "Items"
  end

  defp section_label("civilizations") do
    "Civilizations"
  end

  defp section_label("documents") do
    "Documents"
  end

  defp section_label("connections") do
    "Connections"
  end

  defp section_label("calendar") do
    "Calendar"
  end

  defp section_label("timeline") do
    "Timeline"
  end

  defp section_label(_section) do
    "Geography"
  end

  defp selected_expanded_action(socket, section, params, opts) do
    selected_record_action = selected_record_action(section, params, opts)

    cond do
      selected_record_action ->
        selected_record_action

      socket.assigns[:section] == section ->
        socket.assigns[:expanded_action]

      true ->
        default_expanded_action(section)
    end
  end

  defp selected_record_action("geography", params, opts) do
    if Keyword.get(opts, :select_action, false) do
      geography_record_action(params)
    end
  end

  defp selected_record_action("characters", %{"character_id" => character_id}, opts)
       when character_id not in [nil, ""] do
    if Keyword.get(opts, :select_action, false) do
      "character"
    end
  end

  defp selected_record_action(_section, _params, _opts) do
    nil
  end

  defp geography_record_action(%{"location_id" => location_id})
       when location_id not in [nil, ""] do
    "location_edit"
  end

  defp geography_record_action(%{"hold_id" => hold_id}) when hold_id not in [nil, ""] do
    "hold"
  end

  defp geography_record_action(%{"province_id" => province_id})
       when province_id not in [nil, ""] do
    "province"
  end

  defp geography_record_action(%{"continent_id" => continent_id})
       when continent_id not in [nil, ""] do
    "continent"
  end

  defp geography_record_action(_params) do
    nil
  end

  defp default_expanded_action("races") do
    "race"
  end

  defp default_expanded_action("guilds") do
    nil
  end

  defp default_expanded_action("gods") do
    "god"
  end

  defp default_expanded_action("characters") do
    "character"
  end

  defp default_expanded_action("skills") do
    "skill"
  end

  defp default_expanded_action("spells") do
    "spell"
  end

  defp default_expanded_action("items") do
    "item"
  end

  defp default_expanded_action("bestiary") do
    "creature"
  end

  defp default_expanded_action("civilizations") do
    "civilization"
  end

  defp default_expanded_action("documents") do
    "document"
  end

  defp default_expanded_action("connections") do
    "lore_connection"
  end

  defp default_expanded_action("calendar") do
    "calendar"
  end

  defp default_expanded_action("timeline") do
    "timeline"
  end

  defp default_expanded_action(_section) do
    "continent"
  end

  defp selected_skill_detail_tab(socket) do
    socket.assigns
    |> Map.get(:skill_detail_tab)
    |> normalize_skill_detail_tab()
  end

  defp selected_timeline_detail_tab(socket) do
    socket.assigns
    |> Map.get(:timeline_detail_tab)
    |> normalize_timeline_detail_tab()
  end

  defp normalize_skill_detail_tab(tab) when tab in ~w(levels perks) do
    tab
  end

  defp normalize_skill_detail_tab(_tab) do
    "levels"
  end

  defp skill_detail_tab_for_action("skill_level", _current_tab) do
    "levels"
  end

  defp skill_detail_tab_for_action("skill_perk", _current_tab) do
    "perks"
  end

  defp skill_detail_tab_for_action(_action, current_tab) do
    normalize_skill_detail_tab(current_tab)
  end

  defp normalize_timeline_detail_tab(tab) when tab in ~w(eras events) do
    tab
  end

  defp normalize_timeline_detail_tab(_tab) do
    "eras"
  end

  defp timeline_detail_tab_for_action("timeline_era", _current_tab) do
    "eras"
  end

  defp timeline_detail_tab_for_action("timeline_event", _current_tab) do
    "events"
  end

  defp timeline_detail_tab_for_action(_action, current_tab) do
    normalize_timeline_detail_tab(current_tab)
  end

  defp race_traits(race, category) do
    race.traits
    |> Enum.filter(&(&1.category == category))
    |> sorted()
  end

  defp race_civilizations(race) do
    race.civilization_races
    |> Enum.map(& &1.civilization)
    |> Enum.reject(&is_nil/1)
    |> sorted()
  end

  defp character_occupations(nil) do
    []
  end

  defp character_occupations(character) do
    character.character_occupations
    |> Enum.sort_by(&{!&1.primary, &1.occupation.name})
  end

  defp character_skills(nil) do
    []
  end

  defp character_skills(character) do
    character.character_skills
    |> Enum.sort_by(& &1.skill.name)
  end

  defp character_inventory_categories(nil) do
    []
  end

  defp character_inventory_categories(character) do
    character.inventory_categories
    |> Enum.sort_by(&{&1.position, &1.name})
  end

  defp character_inventory_items(nil) do
    []
  end

  defp character_inventory_items(character) do
    character.inventory_items
    |> Enum.sort_by(&{inventory_category_position(&1), inventory_item_name(&1)})
  end

  defp item_effects(nil) do
    []
  end

  defp item_effects(item) do
    item.item_effects
    |> Enum.sort_by(&{&1.position, record_name(&1.effect)})
  end

  defp inventory_category_position(%{inventory_category: %{position: position}}) do
    position
  end

  defp inventory_category_position(_inventory_item) do
    999
  end

  defp inventory_item_name(%{name: name}) when name not in [nil, ""] do
    name
  end

  defp inventory_item_name(%{item: %{name: name}}) do
    name
  end

  defp inventory_item_name(_inventory_item) do
    "Custom Item"
  end

  defp calendar_months(nil) do
    []
  end

  defp calendar_months(calendar) do
    calendar.months
    |> Enum.sort_by(& &1.position)
  end

  defp creature_locations(nil) do
    []
  end

  defp creature_locations(creature) do
    creature.creature_locations
    |> Enum.sort_by(&{record_name(&1.location), &1.presence || ""})
  end

  defp timeline_eras(nil) do
    []
  end

  defp timeline_eras(timeline) do
    timeline.eras
    |> Enum.sort_by(&{&1.position, &1.name})
  end

  defp timeline_events(nil) do
    []
  end

  defp timeline_events(timeline) do
    timeline.events
    |> Enum.sort_by(fn event ->
      {timeline_event_era_position(timeline, event), event.year || 0, event.position, event.name}
    end)
  end

  defp next_calendar_month_position(nil) do
    1
  end

  defp next_calendar_month_position(calendar) do
    calendar
    |> calendar_months()
    |> Enum.map(& &1.position)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp next_timeline_era_position(nil) do
    1
  end

  defp next_timeline_era_position(timeline) do
    timeline
    |> timeline_eras()
    |> Enum.map(& &1.position)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp next_timeline_event_position(nil) do
    1
  end

  defp next_timeline_event_position(timeline) do
    timeline
    |> timeline_events()
    |> Enum.map(& &1.position)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp next_inventory_category_position(nil) do
    1
  end

  defp next_inventory_category_position(character) do
    character
    |> character_inventory_categories()
    |> Enum.map(& &1.position)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp skill_levels(nil) do
    []
  end

  defp skill_levels(skill) do
    skill.levels
    |> Enum.sort_by(&{&1.rank, &1.minimum_value || 0, &1.name})
  end

  defp skill_tree_perks(nil) do
    []
  end

  defp skill_tree_perks(%{skill_tree: nil}) do
    []
  end

  defp skill_tree_perks(%{skill_tree: skill_tree}) do
    skill_tree.perks
    |> Enum.sort_by(&{&1.position, &1.required_level || 0, &1.name})
  end

  defp next_skill_level_rank(nil) do
    1
  end

  defp next_skill_level_rank(skill) do
    skill
    |> skill_levels()
    |> Enum.map(& &1.rank)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp next_skill_level_minimum(nil) do
    15
  end

  defp next_skill_level_minimum(skill) do
    skill
    |> skill_levels()
    |> Enum.map(&(&1.minimum_value || 0))
    |> Enum.max(fn -> 0 end)
    |> then(&next_skyrim_skill_threshold/1)
  end

  defp next_skyrim_skill_threshold(value) when value < 15 do
    15
  end

  defp next_skyrim_skill_threshold(value) when value < 25 do
    25
  end

  defp next_skyrim_skill_threshold(value) when value < 50 do
    50
  end

  defp next_skyrim_skill_threshold(value) when value < 75 do
    75
  end

  defp next_skyrim_skill_threshold(_value) do
    100
  end

  defp next_skill_perk_required_level(nil) do
    0
  end

  defp next_skill_perk_required_level(skill) do
    skill
    |> skill_tree_perks()
    |> Enum.map(&(&1.required_level || 0))
    |> Enum.max(fn -> 0 end)
  end

  defp next_skill_perk_position(nil) do
    1
  end

  defp next_skill_perk_position(skill) do
    skill
    |> skill_tree_perks()
    |> Enum.map(& &1.position)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp next_item_effect_position(nil) do
    1
  end

  defp next_item_effect_position(item) do
    item
    |> item_effects()
    |> Enum.map(& &1.position)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp commerce_total(entries) do
    Enum.reduce(entries, 0, fn entry, total ->
      amount = entry.amount || 0

      case entry.kind do
        "income" -> total + amount
        "asset" -> total + amount
        "expense" -> total - amount
        "liability" -> total - amount
        _kind -> total
      end
    end)
  end

  defp commerce_total_label(entries, continent) do
    "#{commerce_total(entries)} net #{commerce_currency(entries, continent)}"
  end

  defp commerce_currency(entries, continent) do
    entries
    |> Enum.map(& &1.currency)
    |> Enum.find(&present?/1)
    |> case do
      nil -> continent_currency_name(continent) || "Coins"
      currency -> currency
    end
  end

  defp guild_influences(nil) do
    []
  end

  defp guild_influences(guild) do
    guild.guild_influences
    |> Enum.sort_by(&{&1.relationship, influence_target(&1)})
  end

  defp flat_guild_influences(guilds) do
    Enum.flat_map(guilds, &guild_influences/1)
  end

  defp influence_target(%{god: %{name: name}}) do
    name
  end

  defp influence_target(%{character: %{name: name}}) do
    name
  end

  defp influence_target(_influence) do
    "Unknown"
  end

  defp record_name(%{name: name}) do
    name
  end

  defp record_name(_record) do
    "None"
  end

  defp display_value(nil) do
    "None"
  end

  defp display_value("") do
    "None"
  end

  defp display_value(value) do
    to_string(value)
  end

  defp calendar_days_label(nil) do
    "None"
  end

  defp calendar_days_label(days) do
    "#{days} days"
  end

  defp calendar_month_days(nil) do
    0
  end

  defp calendar_month_days(calendar) do
    calendar
    |> calendar_months()
    |> Enum.reduce(0, fn month, total -> total + month.days end)
  end

  defp calendar_orbit_match_label(_calendar, %{orbital_period_days: nil}) do
    "No orbit set"
  end

  defp calendar_orbit_match_label(calendar, %{orbital_period_days: orbit_days}) do
    month_days = calendar_month_days(calendar)

    if month_days == orbit_days do
      "Aligned"
    else
      "#{month_days - orbit_days} days"
    end
  end

  defp calendar_day_label(nil) do
    "None"
  end

  defp calendar_day_label(day) do
    "Day #{day}"
  end

  defp calendar_degrees_label(nil) do
    "None"
  end

  defp calendar_degrees_label(degrees) do
    "#{degrees} deg"
  end

  defp continent_currency_name(%{currency: %{name: name}}) do
    if present?(name) do
      name
    end
  end

  defp continent_currency_name(_continent) do
    nil
  end

  defp continent_currency_description(%{currency: %{description: description}}) do
    description
  end

  defp continent_currency_description(_continent) do
    nil
  end

  defp present?(nil) do
    false
  end

  defp present?("") do
    false
  end

  defp present?(_value) do
    true
  end

  defp era_years(%{starts_at_year: nil, ends_at_year: nil}) do
    "Undated"
  end

  defp era_years(%{starts_at_year: starts_at_year, ends_at_year: nil}) do
    "#{starts_at_year}+"
  end

  defp era_years(%{starts_at_year: nil, ends_at_year: ends_at_year}) do
    "Until #{ends_at_year}"
  end

  defp era_years(%{starts_at_year: starts_at_year, ends_at_year: ends_at_year}) do
    "#{starts_at_year} to #{ends_at_year}"
  end

  defp timeline_event_year(%{year: nil}, _timeline) do
    "Undated"
  end

  defp timeline_event_year(%{year: year} = event, timeline) do
    case timeline_event_era(event, timeline) do
      %{abbreviation: abbreviation} when abbreviation not in [nil, ""] ->
        "#{abbreviation} #{year}"

      _era ->
        to_string(year)
    end
  end

  defp timeline_event_era_name(event, timeline) do
    event
    |> timeline_event_era(timeline)
    |> record_name()
  end

  defp timeline_event_era(%{timeline_era_id: nil}, _timeline) do
    nil
  end

  defp timeline_event_era(%{timeline_era_id: timeline_era_id}, timeline) do
    Enum.find(timeline_eras(timeline), &(&1.id == timeline_era_id))
  end

  defp timeline_event_era_position(timeline, event) do
    case timeline_event_era(event, timeline) do
      %{position: position} ->
        position

      _era ->
        999
    end
  end

  defp sorted(records) do
    Enum.sort_by(records, & &1.name)
  end

  defp sorted_by_title(records) do
    Enum.sort_by(records, & &1.title)
  end

  defp sorted_lore_connections(records) do
    Enum.sort_by(records, &lore_connection_name/1)
  end

  defp sidebar_continents(continents) do
    Enum.sort_by(continents, fn continent ->
      {continent.provinces == [], continent.name}
    end)
  end

  defp sorted_locations_with_roots_first(locations) do
    Enum.sort_by(locations, fn location ->
      {location.parent_location_id != nil, location.name}
    end)
  end

  defp parent_location_name(%{parent_location_id: nil}, _locations) do
    "None"
  end

  defp parent_location_name(location, locations) do
    locations
    |> Enum.find(&(&1.id == location.parent_location_id))
    |> case do
      nil ->
        "None"

      parent ->
        parent.name
    end
  end

  defp selected_path(%{continent: nil, province: nil}) do
    "Unknown"
  end

  defp selected_path(%{continent: continent, province: province}) do
    "#{continent.name} / #{province.name}"
  end

  defp selected_continent?(%{continent: %{id: continent_id}}, %{id: continent_id}) do
    true
  end

  defp selected_continent?(_selected_path, _continent) do
    false
  end

  defp selected_province?(%{province: %{id: province_id}}, %{id: province_id}) do
    true
  end

  defp selected_province?(_selected_path, _province) do
    false
  end

  defp details_subtitle(_selected_path, _hold, %{} = location) do
    location.name
  end

  defp details_subtitle(_selected_path, %{} = hold, nil) do
    hold.name
  end

  defp details_subtitle(%{province: %{} = province}, nil, nil) do
    province.name
  end

  defp details_subtitle(%{continent: %{} = continent}, nil, nil) do
    continent.name
  end

  defp details_subtitle(_selected_path, nil, nil) do
    "Nothing selected"
  end

  defp continent_hold_count(continent) do
    continent.provinces
    |> Enum.flat_map(& &1.holds)
    |> length()
    |> display_value()
  end

  defp continent_location_count(continent) do
    continent.provinces
    |> Enum.flat_map(& &1.holds)
    |> Enum.flat_map(&selected_hold_locations/1)
    |> length()
    |> display_value()
  end

  defp province_location_count(province) do
    province.holds
    |> Enum.flat_map(&selected_hold_locations/1)
    |> length()
    |> display_value()
  end

  defp map_coordinate_label(%{map_x: nil, map_y: nil}) do
    "Unmapped"
  end

  defp map_coordinate_label(%{map_x: map_x, map_y: map_y}) do
    "X #{display_value(map_x)}, Y #{display_value(map_y)}"
  end

  defp child_locations(location, locations) do
    Enum.filter(locations, &(&1.parent_location_id == location.id))
  end

  defp terrain_icon(nil) do
    nil
  end

  defp terrain_icon(value) do
    case to_string(value) do
      "coast" -> "hero-globe-alt"
      "forest" -> "hero-squares-2x2"
      "highlands" -> "hero-arrow-trending-up"
      "marsh" -> "hero-cloud-arrow-down"
      "mountain" -> "hero-arrow-trending-up"
      "plains" -> "hero-minus"
      "riverlands" -> "hero-arrow-path"
      "snowfield" -> "hero-sparkles"
      "tundra" -> "hero-globe-alt"
      "volcanic" -> "hero-fire"
      "wetlands" -> "hero-cloud-arrow-down"
      _value -> "hero-map"
    end
  end

  defp climate_icon(nil) do
    nil
  end

  defp climate_icon(value) do
    case to_string(value) do
      "arctic" -> "hero-sparkles"
      "coastal" -> "hero-globe-alt"
      "cold" -> "hero-cloud"
      "dry" -> "hero-sun"
      "temperate" -> "hero-sun"
      "volcanic" -> "hero-fire"
      "wet" -> "hero-cloud-arrow-down"
      _value -> "hero-cloud"
    end
  end

  defp visibility_icon(nil) do
    "hero-eye"
  end

  defp visibility_icon(value) do
    case to_string(value) do
      "known" -> "hero-eye"
      "rumored" -> "hero-chat-bubble-left-ellipsis"
      "hidden" -> "hero-eye-slash"
      "lost" -> "hero-question-mark-circle"
      _value -> "hero-map"
    end
  end

  defp visibility_label(nil) do
    "Known"
  end

  defp visibility_label(value) do
    Geography.label(value)
  end

  defp normalize_theme(theme) when theme in ~w(system light dark) do
    theme
  end

  defp normalize_theme(_theme) do
    "system"
  end

  defp daisy_theme("dark") do
    "dark"
  end

  defp daisy_theme(_theme) do
    "light"
  end

  attr :action, :string, required: true
  attr :expanded_action, :string, default: nil
  attr :icon, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  defp action_section(assigns) do
    ~H"""
    <section class="stone-border border-b last:border-b-0">
      <button
        type="button"
        phx-click="show_action"
        phx-value-action={@action}
        class={[
          "flex w-full items-center justify-between gap-3 px-3 py-2 text-left transition hover:bg-zinc-50",
          @expanded_action == @action && "stone-selected"
        ]}
        aria-expanded={to_string(@expanded_action == @action)}
      >
        <span class="flex min-w-0 items-center gap-2">
          <.icon name={@icon} class="stone-muted size-4 shrink-0" />
          <span class="stone-heading truncate text-sm font-medium">{@title}</span>
        </span>
        <.icon
          name={if(@expanded_action == @action, do: "hero-chevron-down", else: "hero-chevron-right")}
          class="stone-muted size-4 shrink-0"
        />
      </button>
      <div :if={@expanded_action == @action} class="stone-border border-t px-4 py-3">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :count, :integer, required: true
  attr :open, :boolean, default: false
  attr :toggle_key, :string, required: true
  slot :inner_block, required: true

  defp folded_group(assigns) do
    ~H"""
    <details id={@id} class="group" open={@open}>
      <summary
        class="flex cursor-pointer list-none items-center justify-between gap-2 px-3 py-2 text-[11px] font-semibold uppercase text-zinc-500 transition hover:bg-zinc-50"
        phx-click="toggle_folded_group"
        phx-value-key={@toggle_key}
      >
        <span class="flex min-w-0 items-center gap-2">
          <.icon name="hero-chevron-right" class="size-3.5 shrink-0 group-open:hidden" />
          <.icon name="hero-chevron-down" class="hidden size-3.5 shrink-0 group-open:inline" />
          <span class="truncate">{@label}</span>
        </span>
        <span>{@count}</span>
      </summary>
      {render_slot(@inner_block)}
    </details>
    """
  end

  attr :patch, :string, required: true
  attr :selected, :boolean, required: true
  attr :label, :string, required: true

  defp section_menu_link(assigns) do
    ~H"""
    <.link
      patch={@patch}
      class={[
        "block px-3 py-2 text-sm transition hover:bg-zinc-50",
        @selected && "stone-selected stone-heading",
        !@selected && "stone-muted"
      ]}
    >
      {@label}
    </.link>
    """
  end

  attr :id, :string, required: true
  attr :record, :map, required: true

  defp geography_badges(assigns) do
    ~H"""
    <div
      :if={@record.terrain || @record.climate}
      id={@id}
      class={[
        "mt-1 grid min-w-0 gap-1",
        @record.terrain && @record.climate && "grid-cols-2",
        !(@record.terrain && @record.climate) && "grid-cols-1"
      ]}
    >
      <span
        :if={@record.terrain}
        id={@id <> "-terrain"}
        class="inline-flex min-w-0 items-center gap-1 rounded border border-zinc-200 bg-white px-1.5 py-0.5 text-[11px] font-medium text-zinc-600"
        title={"Terrain: #{Geography.label(@record.terrain)}"}
        aria-label={"Terrain: #{Geography.label(@record.terrain)}"}
      >
        <.icon name={terrain_icon(@record.terrain)} class="size-3 shrink-0" />
        <span class="truncate">{Geography.label(@record.terrain)}</span>
      </span>
      <span
        :if={@record.climate}
        id={@id <> "-climate"}
        class="inline-flex min-w-0 items-center gap-1 rounded border border-zinc-200 bg-white px-1.5 py-0.5 text-[11px] font-medium text-zinc-600"
        title={"Climate: #{Geography.label(@record.climate)}"}
        aria-label={"Climate: #{Geography.label(@record.climate)}"}
      >
        <.icon name={climate_icon(@record.climate)} class="size-3 shrink-0" />
        <span class="truncate">{Geography.label(@record.climate)}</span>
      </span>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :empty_message, :string, required: true
  attr :offices, :list, required: true
  attr :record, :map, required: true
  attr :world, :map, required: true

  defp political_office_group(assigns) do
    ~H"""
    <section id={@id} class="rounded-md border border-zinc-200 bg-white px-3 py-2">
      <div>
        <p class="text-[11px] font-semibold uppercase text-zinc-500">
          {@title}
        </p>
        <p class="mt-0.5 text-sm font-medium text-zinc-800">
          {@subtitle}
        </p>
      </div>
      <div class="mt-1 flex flex-col divide-y divide-zinc-100">
        <div :if={@offices == []} class="py-2 text-sm text-zinc-500">
          {@empty_message}
        </div>
        <div
          :for={office <- @offices}
          class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
        >
          <.link
            patch={political_office_patch(@world, @record, office)}
            class="block min-w-0 rounded px-1 py-0.5 transition hover:bg-zinc-50"
          >
            <div class="text-sm font-medium text-zinc-800">
              {office.office}
            </div>
            <p class="text-xs text-zinc-500">
              {record_name(office.character)} / {display_value(office.politics)}
            </p>
          </.link>
          <button
            type="button"
            phx-click="delete_political_office"
            phx-value-id={office.id}
            data-confirm={"Delete #{office.office}?"}
            class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
            aria-label={"Delete #{office.office}"}
          >
            <.icon name="hero-trash" class="size-4" />
          </button>
        </div>
      </div>
    </section>
    """
  end

  defp political_office_patch(world, %Province{} = province, office) do
    ~p"/worlds/#{world}/dashboard?province_id=#{province.id}&political_office_id=#{office.id}"
  end

  defp political_office_patch(world, %Hold{} = hold, office) do
    ~p"/worlds/#{world}/dashboard?hold_id=#{hold.id}&political_office_id=#{office.id}"
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, default: nil

  defp detail(assigns) do
    ~H"""
    <div class="stone-panel-muted rounded-md border px-3 py-2">
      <p class="stone-muted flex items-center gap-1.5 text-[11px] font-semibold uppercase">
        <.icon :if={@icon} name={@icon} class="size-3.5 shrink-0" />
        <span>{@label}</span>
      </p>
      <p class="stone-heading mt-1 text-sm font-medium">{@value}</p>
    </div>
    """
  end
end
