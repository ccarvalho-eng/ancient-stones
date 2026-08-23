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
                <nav
                  :if={@selected_world}
                  id="maps-breadcrumb"
                  class="stone-muted mb-0.5 flex items-center gap-1.5 text-xs font-medium"
                  aria-label="Breadcrumb"
                >
                  <.link navigate={~p"/worlds"} class="stone-breadcrumb-link">Worlds</.link>
                  <.icon name="hero-chevron-right" class="size-3.5" />
                  <span>{@selected_world.name}</span>
                  <.icon name="hero-chevron-right" class="size-3.5" />
                  <span class="stone-heading">Maps</span>
                </nav>
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
                    class="stone-button group rounded-md border p-4 transition hover:-translate-y-0.5 hover:shadow-md"
                  >
                    <.link
                      id={"map-open-#{map.id}"}
                      navigate={~p"/worlds/#{map.world_id}/dashboard?section=map&map_id=#{map.id}"}
                      class="block"
                    >
                      <div class="flex items-start justify-between gap-3">
                        <div class="min-w-0">
                          <p class="stone-muted text-[10px] font-semibold uppercase tracking-[0.16em]">
                            {map_world_name(map, @selected_world)}
                          </p>
                          <h3 class="stone-heading mt-1 truncate text-base font-semibold">
                            {map.name}
                          </h3>
                        </div>
                        <span class="rounded-full border px-2 py-1 text-[10px] font-semibold uppercase tracking-wide">
                          {map.kind}
                        </span>
                      </div>
                      <p class="stone-muted mt-4 flex items-center gap-1.5 text-xs">
                        <.icon name="hero-arrow-turn-down-right" class="size-3.5" />
                        {if map.parent_map, do: "Inside #{map.parent_map.name}", else: "Outer map"}
                      </p>
                      <p
                        :if={map.description not in [nil, ""]}
                        class="stone-muted mt-2 line-clamp-2 text-xs"
                      >
                        {map.description}
                      </p>
                    </.link>
                    <div class="mt-4 flex items-center justify-between gap-3">
                      <.link
                        navigate={~p"/worlds/#{map.world_id}/dashboard?section=map&map_id=#{map.id}"}
                        class="stone-heading inline-flex items-center gap-1 text-xs font-semibold"
                      >
                        Open editor
                        <.icon
                          name="hero-arrow-right"
                          class="size-3.5 transition group-hover:translate-x-0.5"
                        />
                      </.link>
                      <button
                        id={"map-delete-#{map.id}"}
                        type="button"
                        phx-click="delete_map"
                        phx-value-id={map.id}
                        phx-value-world-id={map.world_id}
                        data-confirm="Delete this map? Inner maps will become outer maps."
                        aria-label={"Delete #{map.name}"}
                        class="stone-danger-button inline-flex items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-xs font-semibold transition"
                      >
                        <.icon name="hero-trash" class="size-3.5" /> Delete
                      </button>
                    </div>
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
end
