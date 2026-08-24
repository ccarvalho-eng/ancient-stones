defmodule AncientStonesWeb.MapLive.Index do
  use AncientStonesWeb, :live_view

  alias AncientStones.Maps
  alias AncientStones.Worlds

  def mount(_params, _session, socket) do
    worlds = Worlds.list_worlds()

    {:ok,
     socket
     |> assign(:page_title, "Maps")
     |> assign(:theme, "system")
     |> assign(:worlds, worlds)
     |> assign(:selected_world, nil)
     |> assign(:map_count, 0)
     |> assign(:editing_map_id, nil)
     |> assign(:map_name_form, nil)
     |> assign(:world_filter_form, to_form(%{"world_id" => ""}, as: :world_filter))
     |> stream(:maps, [])}
  end

  def handle_params(params, _uri, socket) do
    selected_world = Enum.find(socket.assigns.worlds, &(&1.id == params["world_id"]))
    maps = if selected_world, do: Maps.list_world_maps(selected_world), else: Maps.list_maps()

    {:noreply,
     socket
     |> assign(:selected_world, selected_world)
     |> assign(:map_count, length(maps))
     |> assign(:editing_map_id, nil)
     |> assign(:map_name_form, nil)
     |> assign(
       :world_filter_form,
       to_form(%{"world_id" => selected_world_id(selected_world)}, as: :world_filter)
     )
     |> stream(:maps, maps, reset: true)}
  end

  def handle_event("filter_world", %{"world_filter" => %{"world_id" => ""}}, socket) do
    {:noreply, push_patch(socket, to: ~p"/maps")}
  end

  def handle_event("filter_world", %{"world_filter" => %{"world_id" => world_id}}, socket) do
    {:noreply, push_patch(socket, to: ~p"/maps?world_id=#{world_id}")}
  end

  def handle_event("edit_map_name", %{"id" => id, "world-id" => world_id}, socket) do
    world = Enum.find(socket.assigns.worlds, &(&1.id == world_id))

    case world && Maps.get_world_map(world, id) do
      nil ->
        {:noreply, put_flash(socket, :error, "The map could not be found.")}

      map_document ->
        {:noreply,
         socket
         |> assign(:editing_map_id, map_document.id)
         |> assign(
           :map_name_form,
           map_document
           |> Maps.change_world_map()
           |> to_form(as: :map_name)
         )
         |> stream(:maps, maps_for(socket.assigns.selected_world), reset: true)}
    end
  end

  def handle_event("cancel_map_name_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_map_id, nil)
     |> assign(:map_name_form, nil)
     |> stream(:maps, maps_for(socket.assigns.selected_world), reset: true)}
  end

  def handle_event(
        "save_map_name",
        %{
          "_lock_version" => lock_version,
          "_map_id" => id,
          "_world_id" => world_id,
          "map_name" => attrs
        },
        socket
      ) do
    world = Enum.find(socket.assigns.worlds, &(&1.id == world_id))

    map_document =
      world
      |> then(&(&1 && Maps.get_world_map(&1, id)))
      |> put_submitted_lock_version(lock_version)

    case map_document && Maps.update_world_map(map_document, Map.take(attrs, ["name"])) do
      {:ok, _map_document} ->
        maps = maps_for(socket.assigns.selected_world)

        {:noreply,
         socket
         |> assign(:editing_map_id, nil)
         |> assign(:map_name_form, nil)
         |> put_flash(:info, "Map name updated.")
         |> stream(:maps, maps, reset: true)}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:map_name_form, to_form(changeset, as: :map_name))
          |> stream(:maps, maps_for(socket.assigns.selected_world), reset: true)

        socket =
          if stale_map_changeset?(changeset) do
            put_flash(
              socket,
              :error,
              "This map was updated elsewhere. Reload it before renaming."
            )
          else
            socket
          end

        {:noreply, socket}

      _error ->
        {:noreply, put_flash(socket, :error, "The map name could not be updated.")}
    end
  end

  def handle_event("delete_map", %{"id" => id, "world-id" => world_id}, socket) do
    world = Enum.find(socket.assigns.worlds, &(&1.id == world_id))
    map_document = world && Maps.get_world_map(world, id)

    case map_document && Maps.delete_world_map(map_document) do
      {:ok, _map_document} ->
        maps = maps_for(socket.assigns.selected_world)

        {:noreply,
         socket
         |> assign(:map_count, length(maps))
         |> put_flash(:info, "Map deleted.")
         |> stream(:maps, maps, reset: true)}

      _error ->
        {:noreply, put_flash(socket, :error, "The map could not be deleted.")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        id="maps-index"
        class={["stone-page min-h-screen px-4 py-5", "stone-theme-#{@theme}"]}
        data-theme="light"
        phx-hook="AncientStonesTheme"
      >
        <div class="stone-shell mx-auto grid max-w-[1400px] overflow-hidden rounded-lg border shadow-sm lg:grid-cols-[240px_minmax(0,1fr)]">
          <aside class="stone-sidebar stone-muted border-r">
            <div class="stone-border flex h-16 items-center border-b px-4">
              <div class="flex items-center gap-3">
                <div class="stone-brand-mark">
                  <.icon name="hero-cube-transparent" class="size-5" />
                </div>
                <div>
                  <h1 class="stone-heading text-lg font-semibold leading-5">Ancient Stones</h1>
                  <p class="stone-muted mt-0.5 text-[11px] font-medium uppercase tracking-wide">
                    Builder Console
                  </p>
                </div>
              </div>
            </div>

            <nav class="p-3 text-sm">
              <div class="stone-muted px-3 pb-2 text-[11px] font-semibold uppercase tracking-wide">
                Workspace
              </div>
              <.link
                id="worlds-navigation"
                navigate={~p"/worlds"}
                class="stone-button flex items-center gap-2 rounded-md border px-3 py-2 font-medium"
              >
                <.icon name="hero-globe-alt" class="size-4" /> Worlds / Planets
              </.link>
              <.link
                id="maps-navigation"
                navigate={~p"/maps"}
                class="stone-selected mt-1 flex items-center justify-between gap-2 rounded-md border px-3 py-2 font-medium"
              >
                <span class="flex items-center gap-2">
                  <.icon name="hero-map" class="size-4" /> Maps
                </span>
                <strong class="text-xs font-semibold">{@map_count}</strong>
              </.link>
            </nav>
          </aside>

          <div class="stone-workspace min-w-0">
            <header class="stone-topbar flex h-16 items-center justify-between border-b px-5">
              <div>
                <h2 class="stone-heading text-sm font-semibold">Maps</h2>
                <p class="stone-muted text-xs">Open outer and inner maps in the world editor.</p>
              </div>
              <.theme_switcher theme={@theme} />
            </header>

            <main class="min-h-[800px] p-4">
              <.form
                for={@world_filter_form}
                id="map-world-filter"
                phx-change="filter_world"
                class="stone-panel mb-4 rounded-md border p-4"
              >
                <.input
                  field={@world_filter_form[:world_id]}
                  type="select"
                  label="World"
                  options={[{"All worlds", ""} | Enum.map(@worlds, &{&1.name, &1.id})]}
                />
                <div
                  :if={@selected_world}
                  id="maps-world-context"
                  class="mt-3 flex flex-wrap items-center justify-between gap-2 border-t border-stone-200 pt-3 dark:border-stone-700"
                >
                  <p class="text-sm text-stone-600 dark:text-stone-300">
                    Showing maps for
                    <strong class="font-semibold text-stone-950 dark:text-stone-50">{@selected_world.name}</strong>
                  </p>
                  <.link
                    id="maps-clear-world-filter"
                    navigate={~p"/maps"}
                    class="rounded border border-stone-300 px-2.5 py-1.5 text-xs font-semibold text-stone-700 transition hover:border-stone-500 hover:bg-stone-100 dark:border-stone-600 dark:text-stone-200 dark:hover:border-stone-400 dark:hover:bg-stone-800"
                  >
                    Show all worlds
                  </.link>
                </div>
              </.form>

              <section class="stone-panel overflow-hidden rounded-md border">
                <.panel_header
                  title="Map library"
                  subtitle="Choose a map to continue building it."
                  count={@map_count}
                  label="maps"
                />

                <div
                  id="maps"
                  phx-update="stream"
                  class="grid gap-3 p-4 md:grid-cols-2 xl:grid-cols-3"
                >
                  <div
                    id="maps-empty"
                    class="stone-muted hidden rounded-md border border-dashed p-8 text-center only:block md:col-span-2 xl:col-span-3"
                  >
                    <.icon name="hero-map" class="mx-auto size-8 opacity-50" />
                    <p class="stone-heading mt-3 text-sm font-semibold">No maps yet</p>
                    <p class="mt-1 text-xs">Open a world and create its first map.</p>
                  </div>

                  <article
                    :for={{id, map} <- @streams.maps}
                    id={id}
                    class="stone-button group flex h-full flex-col rounded-md border p-4 transition hover:-translate-y-0.5 hover:shadow-md"
                  >
                    <%= if @editing_map_id == map.id do %>
                      <.form
                        for={@map_name_form}
                        id={"map-name-form-#{map.id}"}
                        phx-submit="save_map_name"
                        class="flex flex-1 flex-col"
                      >
                        <input type="hidden" name="_map_id" value={map.id} />
                        <input type="hidden" name="_world_id" value={map.world_id} />
                        <input type="hidden" name="_lock_version" value={map.lock_version} />
                        <.input field={@map_name_form[:name]} label="Map name" required />
                        <div class="mt-auto flex items-center justify-end gap-2 pt-4">
                          <button
                            id={"map-name-cancel-#{map.id}"}
                            type="button"
                            phx-click="cancel_map_name_edit"
                            class="stone-button rounded-md border px-3 py-2 text-xs font-semibold transition"
                          >
                            Cancel
                          </button>
                          <button
                            id={"map-name-save-#{map.id}"}
                            type="submit"
                            class="stone-primary-button rounded-md border px-3 py-2 text-xs font-semibold transition"
                          >
                            Save
                          </button>
                        </div>
                      </.form>
                    <% else %>
                      <.link
                        id={"map-open-#{map.id}"}
                        navigate={~p"/worlds/#{map.world_id}/dashboard?section=map&map_id=#{map.id}"}
                        class="block flex-1"
                      >
                        <div class="flex items-start justify-between gap-3">
                          <div class="min-w-0">
                            <p class="stone-muted text-[10px] font-semibold uppercase tracking-[0.16em]">
                              {map_world_name(map, @selected_world)}
                            </p>
                            <h3
                              id={"map-name-#{map.id}"}
                              class="stone-heading mt-1 truncate text-base font-semibold"
                            >
                              {map.name}
                            </h3>
                          </div>
                          <span class="rounded-full border px-2 py-1 text-[10px] font-semibold uppercase tracking-wide">
                            {map.kind}
                          </span>
                        </div>
                        <p class="stone-muted mt-4 flex items-center gap-1.5 text-xs">
                          <.icon name="hero-arrow-turn-down-right" class="size-3.5" />
                          {if map.parent_map,
                            do: "Inside #{map.parent_map.name}",
                            else: "Outer map"}
                        </p>
                        <p
                          :if={map.description not in [nil, ""]}
                          class="stone-muted mt-2 line-clamp-2 text-xs"
                        >
                          {map.description}
                        </p>
                      </.link>
                      <div class="mt-auto flex flex-wrap items-center justify-between gap-3 pt-4">
                        <.link
                          navigate={
                            ~p"/worlds/#{map.world_id}/dashboard?section=map&map_id=#{map.id}"
                          }
                          class="stone-heading inline-flex items-center gap-1 text-xs font-semibold"
                        >
                          Open editor
                          <.icon
                            name="hero-arrow-right"
                            class="size-3.5 transition group-hover:translate-x-0.5"
                          />
                        </.link>
                        <div class="flex items-center gap-2">
                          <button
                            id={"map-name-edit-#{map.id}"}
                            type="button"
                            phx-click="edit_map_name"
                            phx-value-id={map.id}
                            phx-value-world-id={map.world_id}
                            class="stone-button inline-flex items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-xs font-semibold transition"
                          >
                            <.icon name="hero-pencil-square" class="size-3.5" /> Edit
                          </button>
                          <button
                            id={"map-delete-#{map.id}"}
                            type="button"
                            phx-click="delete_map"
                            phx-value-id={map.id}
                            phx-value-world-id={map.world_id}
                            data-confirm="Delete this map? Inner maps will become outer maps."
                            aria-label={"Delete #{map.name}"}
                            class="stone-button inline-flex shrink-0 items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-xs font-semibold transition"
                          >
                            <.icon name="hero-trash" class="size-3.5" /> Delete
                          </button>
                        </div>
                      </div>
                    <% end %>
                  </article>
                </div>
              </section>
            </main>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp selected_world_id(nil) do
    ""
  end

  defp selected_world_id(world) do
    world.id
  end

  defp maps_for(nil) do
    Maps.list_maps()
  end

  defp maps_for(world) do
    Maps.list_world_maps(world)
  end

  defp map_world_name(_map, selected_world) when not is_nil(selected_world) do
    selected_world.name
  end

  defp map_world_name(map, _selected_world) do
    map.world.name
  end

  defp put_submitted_lock_version(nil, _lock_version) do
    nil
  end

  defp put_submitted_lock_version(map_document, lock_version) do
    case Integer.parse(lock_version) do
      {parsed_lock_version, ""} -> %{map_document | lock_version: parsed_lock_version}
      _error -> nil
    end
  end

  defp stale_map_changeset?(changeset) do
    Keyword.has_key?(changeset.errors, :lock_version)
  end
end
