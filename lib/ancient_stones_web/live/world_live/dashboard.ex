defmodule AncientStonesWeb.WorldLive.Dashboard do
  use AncientStonesWeb, :live_view

  alias AncientStones.Worlds
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Geography

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, page_title: "World Details", theme: "light", expanded_action: "continent")}
  end

  def handle_params(%{"id" => id} = params, _uri, socket) do
    {:noreply, assign_dashboard(socket, id, params)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        class={["stone-page min-h-screen px-4 py-5", "stone-theme-#{@theme}"]}
        data-theme={daisy_theme(@theme)}
        id="geography-dashboard"
      >
        <div class="stone-shell mx-auto max-w-[1500px] overflow-hidden rounded-lg border shadow-sm">
          <div class="stone-topbar stone-border border-b px-5 py-3">
            <div class="flex items-center justify-between gap-4">
              <div class="flex items-center gap-4">
                <div class="flex items-center gap-3">
                  <div class="stone-brand-mark">
                    <.icon name="hero-cube-transparent" class="size-5" />
                  </div>
                  <div>
                    <p class="stone-muted text-[11px] font-medium uppercase tracking-wide">
                      Ancient Stones
                    </p>
                    <h1 class="stone-heading text-lg font-semibold leading-5">World Details</h1>
                  </div>
                </div>

                <div class="hidden h-8 border-l border-zinc-200 md:block"></div>

                <div>
                  <nav
                    class="stone-muted flex items-center gap-1.5 text-xs font-medium"
                    aria-label="Breadcrumb"
                  >
                    <.link navigate={~p"/worlds"} class="hover:text-zinc-800">
                      Worlds
                    </.link>
                    <.icon name="hero-chevron-right" class="size-3.5" />
                    <span class="stone-heading">{@world.name}</span>
                  </nav>
                  <details
                    id="section-menu"
                    class="group relative mt-0.5"
                    phx-click-away={JS.remove_attribute("open", to: "#section-menu")}
                  >
                    <summary class="stone-heading flex cursor-pointer list-none items-center gap-2 text-base font-semibold">
                      {section_label(@section)}
                      <.icon
                        name="hero-chevron-down"
                        class="stone-muted size-4 transition group-open:rotate-180"
                      />
                    </summary>
                    <div class="stone-menu absolute z-20 mt-2 w-48 overflow-hidden rounded-md border">
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard"}
                        selected={@section == "geography"}
                        label="Geography"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=races"}
                        selected={@section == "races"}
                        label="Races"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=guilds"}
                        selected={@section == "guilds"}
                        label="Guilds"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=gods"}
                        selected={@section == "gods"}
                        label="Gods"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=civilizations"}
                        selected={@section == "civilizations"}
                        label="Civilizations"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=characters"}
                        selected={@section == "characters"}
                        label="Characters"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=skills"}
                        selected={@section == "skills"}
                        label="Skills"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=spells"}
                        selected={@section == "spells"}
                        label="Spells"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=items"}
                        selected={@section == "items"}
                        label="Items"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=bestiary"}
                        selected={@section == "bestiary"}
                        label="Bestiary"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=calendar"}
                        selected={@section == "calendar"}
                        label="Calendar"
                      />
                      <.section_menu_link
                        patch={~p"/worlds/#{@world}/dashboard?section=timeline"}
                        selected={@section == "timeline"}
                        label="Timeline"
                      />
                    </div>
                  </details>
                </div>
              </div>

              <div class="flex items-center gap-2">
                <.theme_switcher theme={@theme} />
              </div>
            </div>
          </div>

          <%= if @section == "geography" do %>
            <div class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[260px_300px_minmax(0,1fr)_340px]">
              <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                <div class="border-b border-zinc-200 px-4 py-3">
                  <h2 class="text-sm font-semibold text-zinc-800">Geography</h2>
                  <p class="text-xs text-zinc-500">Continents, provinces, and holds</p>
                </div>
                <div class="max-h-[720px] space-y-3 overflow-y-auto p-3 text-sm">
                  <div
                    :for={continent <- sidebar_continents(@continents)}
                    class={[
                      "overflow-hidden rounded-md border border-zinc-200 bg-white shadow-sm",
                      selected_continent?(@selected_path, continent) && "stone-selected"
                    ]}
                  >
                    <div class="flex items-stretch bg-zinc-50">
                      <.link
                        patch={~p"/worlds/#{@world}/dashboard?continent_id=#{continent.id}"}
                        class="block min-w-0 flex-1 px-3 py-2.5 transition hover:bg-zinc-100"
                      >
                        <p class="text-[11px] font-semibold uppercase tracking-wide text-zinc-500">
                          Continent
                        </p>
                        <div class="mt-0.5 truncate text-sm font-semibold text-zinc-800">
                          {continent.name}
                        </div>
                      </.link>
                      <button
                        type="button"
                        phx-click="delete_continent"
                        phx-value-id={continent.id}
                        data-confirm={"Delete #{continent.name} and all nested geography?"}
                        class="stone-muted inline-flex w-10 shrink-0 items-center justify-center border-l border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                        aria-label={"Delete #{continent.name}"}
                      >
                        <.icon name="hero-trash" class="size-3.5" />
                      </button>
                    </div>

                    <div class="space-y-2 border-t border-zinc-100 bg-white p-2">
                      <div
                        :for={province <- sorted(continent.provinces)}
                        class={[
                          "overflow-hidden rounded-md border border-zinc-100 bg-zinc-50",
                          selected_province?(@selected_path, province) && "stone-selected"
                        ]}
                      >
                        <div class="flex items-stretch">
                          <.link
                            patch={~p"/worlds/#{@world}/dashboard?province_id=#{province.id}"}
                            class="block min-w-0 flex-1 px-3 py-2 transition hover:bg-zinc-100"
                          >
                            <p class="text-[11px] font-semibold uppercase tracking-wide text-zinc-500">
                              Province
                            </p>
                            <div class="mt-0.5 truncate text-sm font-medium text-zinc-800">
                              {province.name}
                            </div>
                          </.link>
                          <button
                            type="button"
                            phx-click="delete_province"
                            phx-value-id={province.id}
                            data-confirm={"Delete #{province.name} and all nested holds and locations?"}
                            class="stone-muted inline-flex w-10 shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                            aria-label={"Delete #{province.name}"}
                          >
                            <.icon name="hero-trash" class="size-3.5" />
                          </button>
                        </div>

                        <div
                          :if={province.holds != []}
                          class="border-t border-zinc-100 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wide text-zinc-500"
                        >
                          Holds
                        </div>
                        <div class="space-y-1.5 border-t border-zinc-100 bg-white p-2">
                          <div
                            :for={hold <- sorted(province.holds)}
                            class={[
                              "flex items-stretch overflow-hidden rounded-md border transition",
                              @selected_hold && @selected_hold.id == hold.id &&
                                "border-zinc-300 bg-zinc-100",
                              (!@selected_hold || @selected_hold.id != hold.id) &&
                                "border-zinc-100 bg-white"
                            ]}
                          >
                            <.link
                              patch={~p"/worlds/#{@world}/dashboard?hold_id=#{hold.id}"}
                              class="block min-w-0 flex-1 px-3 py-2 transition hover:bg-zinc-50"
                            >
                              <div class="flex items-center justify-between gap-2">
                                <span class="truncate font-medium text-zinc-800">
                                  {hold.name}
                                </span>
                                <span
                                  :if={hold.capital_location}
                                  class="shrink-0 text-xs text-zinc-500"
                                >
                                  {hold.capital_location.name}
                                </span>
                              </div>
                              <div class="mt-1 flex gap-1 text-[11px] text-zinc-500">
                                <span :if={hold.terrain}>{Geography.label(hold.terrain)}</span>
                                <span :if={hold.climate}>/ {Geography.label(hold.climate)}</span>
                              </div>
                            </.link>
                            <button
                              type="button"
                              phx-click="delete_hold"
                              phx-value-id={hold.id}
                              data-confirm={"Delete #{hold.name} and its locations?"}
                              class="stone-muted inline-flex w-10 shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                              aria-label={"Delete #{hold.name}"}
                            >
                              <.icon name="hero-trash" class="size-3.5" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </aside>

              <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                  <div>
                    <h2 class="text-sm font-semibold text-zinc-800">Locations</h2>
                    <p class="text-xs text-zinc-500">
                      {if @selected_hold, do: @selected_hold.name, else: "Select a hold"}
                    </p>
                  </div>
                  <.link
                    patch={~p"/worlds/#{@world}/dashboard"}
                    class="text-xs font-medium text-zinc-500 hover:text-zinc-800"
                  >
                    Clear
                  </.link>
                </div>

                <div id="location-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                  <div
                    :if={is_nil(@selected_hold)}
                    class="px-4 py-8 text-center text-sm text-zinc-500"
                  >
                    Select a hold in the geography tree.
                  </div>

                  <div
                    :for={location <- @selected_hold_locations}
                    class={[
                      "flex items-stretch overflow-hidden rounded-md stone-record-card border",
                      @selected_location && @selected_location.id == location.id && "stone-selected"
                    ]}
                  >
                    <.link
                      patch={
                        ~p"/worlds/#{@world}/dashboard?hold_id=#{@selected_hold.id}&location_id=#{location.id}"
                      }
                      class="block min-w-0 flex-1 px-3 py-2 text-left transition hover:bg-zinc-50"
                    >
                      <div class="flex items-start justify-between gap-3">
                        <div class={["min-w-0", location.parent_location_id && "pl-3"]}>
                          <div class="truncate text-sm font-medium text-zinc-800">
                            {location.name}
                          </div>
                          <p class="mt-0.5 text-xs text-zinc-500">
                            {location.location_type.name}
                          </p>
                        </div>
                        <span
                          :if={@selected_hold.capital_location_id == location.id}
                          class="shrink-0 rounded border border-zinc-200 bg-zinc-50 px-1.5 py-0.5 text-[11px] font-medium text-zinc-600"
                        >
                          Capital
                        </span>
                      </div>
                    </.link>
                    <button
                      type="button"
                      phx-click="delete_location"
                      phx-value-id={location.id}
                      data-confirm={"Delete #{location.name}?"}
                      class="stone-muted inline-flex w-10 shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                      aria-label={"Delete #{location.name}"}
                    >
                      <.icon name="hero-trash" class="size-4" />
                    </button>
                  </div>
                </div>
              </section>

              <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                <section>
                  <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                    <div>
                      <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                      <p class="text-xs text-zinc-500">
                        {details_subtitle(@selected_path, @selected_hold, @selected_location)}
                      </p>
                    </div>
                  </div>

                  <div class="max-h-[720px] overflow-y-auto p-4">
                    <div
                      :if={
                        is_nil(@selected_path.continent) && is_nil(@selected_hold) &&
                          is_nil(@selected_location)
                      }
                      class="py-8 text-center text-sm text-zinc-500"
                    >
                      Select a continent, province, hold, or location to inspect its details.
                    </div>

                    <div
                      :if={@selected_path.continent && is_nil(@selected_path.province)}
                      id="continent-details"
                      class="mb-4 space-y-4"
                    >
                      <div>
                        <h3 class="text-lg font-semibold text-zinc-800">
                          {@selected_path.continent.name}
                        </h3>
                        <p class="mt-1 text-sm leading-6 text-zinc-600">
                          {@selected_path.continent.description || "No description yet."}
                        </p>
                      </div>

                      <div class="grid gap-3 text-sm sm:grid-cols-2">
                        <.detail
                          label="Provinces"
                          value={display_value(length(@selected_path.continent.provinces))}
                        />
                        <.detail
                          label="Holds"
                          value={continent_hold_count(@selected_path.continent)}
                        />
                        <.detail
                          label="Locations"
                          value={continent_location_count(@selected_path.continent)}
                        />
                      </div>
                    </div>

                    <div
                      :if={
                        @selected_path.province && is_nil(@selected_hold) &&
                          is_nil(@selected_location)
                      }
                      id="province-details"
                      class="mb-4 space-y-4"
                    >
                      <div>
                        <h3 class="text-lg font-semibold text-zinc-800">
                          {@selected_path.province.name}
                        </h3>
                        <p class="mt-1 text-sm leading-6 text-zinc-600">
                          {@selected_path.province.description || "No description yet."}
                        </p>
                      </div>

                      <div class="grid gap-3 text-sm sm:grid-cols-2">
                        <.detail label="Continent" value={@selected_path.continent.name} />
                        <.detail
                          label="Terrain"
                          value={Geography.label(@selected_path.province.terrain)}
                        />
                        <.detail
                          label="Climate"
                          value={Geography.label(@selected_path.province.climate)}
                        />
                        <.detail
                          label="Holds"
                          value={display_value(length(@selected_path.province.holds))}
                        />
                        <.detail
                          label="Locations"
                          value={province_location_count(@selected_path.province)}
                        />
                      </div>
                    </div>

                    <div
                      :if={@selected_hold && is_nil(@selected_location)}
                      id="hold-details"
                      class="mb-4 space-y-4"
                    >
                      <div>
                        <h3 class="text-lg font-semibold text-zinc-800">{@selected_hold.name}</h3>
                        <p class="mt-1 text-sm leading-6 text-zinc-600">
                          {@selected_hold.description || "No description yet."}
                        </p>
                      </div>

                      <div class="grid gap-3 text-sm sm:grid-cols-2">
                        <.detail label="Region" value={selected_path(@selected_path)} />
                        <.detail label="Terrain" value={Geography.label(@selected_hold.terrain)} />
                        <.detail label="Climate" value={Geography.label(@selected_hold.climate)} />
                        <.detail
                          label="Capital"
                          value={record_name(@selected_hold.capital_location)}
                        />
                      </div>
                    </div>

                    <div
                      :if={@selected_hold && is_nil(@selected_location)}
                      id="political-office-details"
                      class="mb-4 rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                    >
                      <div class="flex items-center justify-between gap-3">
                        <div>
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">
                            Politics
                          </p>
                          <p class="mt-0.5 text-sm font-medium text-zinc-800">
                            {selected_path(@selected_path)}
                          </p>
                        </div>
                      </div>

                      <div class="mt-3">
                        <p class="text-[11px] font-semibold uppercase text-zinc-500">
                          Province Offices
                        </p>
                        <div class="mt-1 flex flex-col divide-y divide-zinc-100">
                          <div
                            :if={@selected_province_political_offices == []}
                            class="py-2 text-sm text-zinc-500"
                          >
                            No province offices have been added.
                          </div>
                          <div
                            :for={office <- @selected_province_political_offices}
                            class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                          >
                            <.link
                              patch={
                                ~p"/worlds/#{@world}/dashboard?hold_id=#{@selected_hold.id}&political_office_id=#{office.id}"
                              }
                              class="block min-w-0 rounded px-1 py-0.5 transition hover:bg-white"
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
                      </div>

                      <div class="mt-3">
                        <p class="text-[11px] font-semibold uppercase text-zinc-500">
                          Hold Offices
                        </p>
                        <div class="mt-1 flex flex-col divide-y divide-zinc-100">
                          <div
                            :if={@selected_hold_political_offices == []}
                            class="py-2 text-sm text-zinc-500"
                          >
                            No hold offices have been added.
                          </div>
                          <div
                            :for={office <- @selected_hold_political_offices}
                            class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                          >
                            <.link
                              patch={
                                ~p"/worlds/#{@world}/dashboard?hold_id=#{@selected_hold.id}&political_office_id=#{office.id}"
                              }
                              class="block min-w-0 rounded px-1 py-0.5 transition hover:bg-white"
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
                      </div>
                    </div>

                    <div
                      :if={@selected_hold && is_nil(@selected_location)}
                      id="hold-commerce-details"
                      class="mb-4 rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                    >
                      <div class="flex items-center justify-between gap-3">
                        <div>
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">
                            Hold Commerce
                          </p>
                          <p class="mt-0.5 text-sm font-medium text-zinc-800">
                            {@selected_hold.name}
                          </p>
                        </div>
                        <span class="rounded border border-zinc-200 bg-white px-2 py-1 text-xs font-medium text-zinc-600">
                          {commerce_total(@selected_hold_commerce_entries)} net Septims
                        </span>
                      </div>
                      <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                        <div
                          :if={@selected_hold_commerce_entries == []}
                          class="py-2 text-sm text-zinc-500"
                        >
                          No commerce entries have been added for this hold.
                        </div>
                        <div
                          :for={entry <- @selected_hold_commerce_entries}
                          class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                        >
                          <div>
                            <div class="text-sm font-medium text-zinc-800">{entry.name}</div>
                            <p class="text-xs text-zinc-500">
                              {Geography.label(entry.kind)} / {display_value(entry.category)} / {display_value(
                                entry.amount
                              )} {display_value(entry.currency)}
                            </p>
                          </div>
                          <button
                            type="button"
                            phx-click="delete_commerce"
                            phx-value-id={entry.id}
                            data-confirm={"Delete #{entry.name}?"}
                            class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                            aria-label={"Delete #{entry.name}"}
                          >
                            <.icon name="hero-trash" class="size-4" />
                          </button>
                        </div>
                      </div>
                    </div>

                    <div :if={@selected_location} id="location-details" class="space-y-4">
                      <div>
                        <h3 class="text-lg font-semibold text-zinc-800">{@selected_location.name}</h3>
                        <p class="mt-1 text-sm leading-6 text-zinc-600">
                          {@selected_location.description || "No description yet."}
                        </p>
                      </div>

                      <div class="grid gap-3 text-sm sm:grid-cols-2">
                        <.detail label="Type" value={@selected_location.location_type.name} />
                        <.detail label="Hold" value={@selected_hold.name} />
                        <.detail label="Region" value={selected_path(@selected_path)} />
                        <.detail
                          label="Capital"
                          value={
                            if @selected_hold.capital_location_id == @selected_location.id,
                              do: "Yes",
                              else: "No"
                          }
                        />
                        <.detail
                          label="Parent"
                          value={parent_location_name(@selected_location, @selected_hold_locations)}
                        />
                      </div>

                      <div
                        :if={@selected_location.location_type.description}
                        class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                      >
                        <p class="text-[11px] font-semibold uppercase text-zinc-500">
                          Type Description
                        </p>
                        <p class="mt-1 text-sm leading-6 text-zinc-600">
                          {@selected_location.location_type.description}
                        </p>
                      </div>

                      <div
                        :if={child_locations(@selected_location, @selected_hold_locations) != []}
                        class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                      >
                        <p class="text-[11px] font-semibold uppercase text-zinc-500">
                          Child Locations
                        </p>
                        <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                          <div
                            :for={
                              child_location <-
                                child_locations(
                                  @selected_location,
                                  @selected_hold_locations
                                )
                            }
                            class="py-1.5 text-sm text-zinc-700 first:pt-0 last:pb-0"
                          >
                            {child_location.name}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </section>
              </main>

              <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                  <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                  <p class="mt-1 text-xs text-zinc-500">Create or edit selected geography records.</p>
                </div>

                <div id="action-list" class="max-h-[720px] overflow-y-auto">
                  <.action_section
                    action="continent"
                    expanded_action={@expanded_action}
                    icon="hero-globe-alt"
                    title="Add Continent"
                  >
                    <.form
                      for={@continent_form}
                      id="continent-form"
                      phx-submit="create_continent"
                      class="space-y-2"
                    >
                      <.input field={@continent_form[:name]} type="text" label="Name" required />
                      <.input
                        field={@continent_form[:description]}
                        type="textarea"
                        label="Description"
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Create
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    :if={@continent_options != []}
                    action="province"
                    expanded_action={@expanded_action}
                    icon="hero-map"
                    title="Add Province"
                  >
                    <.form
                      for={@province_form}
                      id="province-form"
                      phx-submit="create_province"
                      class="space-y-2"
                    >
                      <.input
                        field={@province_form[:continent_id]}
                        type="select"
                        label="Continent"
                        options={@continent_options}
                      />
                      <.input field={@province_form[:name]} type="text" label="Name" required />
                      <.input
                        field={@province_form[:terrain]}
                        type="select"
                        label="Terrain"
                        prompt="None"
                        options={Geography.terrain_options()}
                      />
                      <.input
                        field={@province_form[:climate]}
                        type="select"
                        label="Climate"
                        prompt="None"
                        options={Geography.climate_options()}
                      />
                      <.input
                        field={@province_form[:description]}
                        type="textarea"
                        label="Description"
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Create
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    :if={@province_options != []}
                    action="hold"
                    expanded_action={@expanded_action}
                    icon="hero-building-office-2"
                    title="Add Hold"
                  >
                    <.form for={@hold_form} id="hold-form" phx-submit="create_hold" class="space-y-2">
                      <.input
                        field={@hold_form[:province_id]}
                        type="select"
                        label="Province"
                        options={@province_options}
                      />
                      <.input field={@hold_form[:name]} type="text" label="Name" required />
                      <.input
                        field={@hold_form[:terrain]}
                        type="select"
                        label="Terrain"
                        prompt="None"
                        options={Geography.terrain_options()}
                      />
                      <.input
                        field={@hold_form[:climate]}
                        type="select"
                        label="Climate"
                        prompt="None"
                        options={Geography.climate_options()}
                      />
                      <.input field={@hold_form[:description]} type="textarea" label="Description" />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Create
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    action="location_type"
                    expanded_action={@expanded_action}
                    icon="hero-tag"
                    title="Add Location Type"
                  >
                    <.form
                      for={@location_type_form}
                      id="location-type-form"
                      phx-submit="create_location_type"
                      class="space-y-2"
                    >
                      <.input
                        field={@location_type_form[:parent_id]}
                        type="select"
                        label="Parent"
                        prompt="Root type"
                        options={@location_type_options}
                      />
                      <.input field={@location_type_form[:name]} type="text" label="Name" required />
                      <.input
                        field={@location_type_form[:description]}
                        type="textarea"
                        label="Description"
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Create
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    :if={@location_type_options != []}
                    action="delete_location_type"
                    expanded_action={@expanded_action}
                    icon="hero-trash"
                    title="Delete Location Type"
                  >
                    <.form
                      for={@location_type_delete_form}
                      id="delete-location-type-form"
                      phx-submit="delete_location_type"
                      class="space-y-2"
                    >
                      <.input
                        field={@location_type_delete_form[:id]}
                        type="select"
                        label="Type"
                        options={@location_type_options}
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Delete
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    :if={@selected_hold && @location_type_options != []}
                    action="location"
                    expanded_action={@expanded_action}
                    icon="hero-map-pin"
                    title="Add Location"
                  >
                    <.form
                      for={@location_form}
                      id="location-form"
                      phx-submit="create_location"
                      class="space-y-2"
                    >
                      <.input
                        field={@location_form[:hold_id]}
                        type="select"
                        label="Hold"
                        options={@selected_hold_options}
                      />
                      <.input
                        field={@location_form[:location_type_id]}
                        type="select"
                        label="Type"
                        options={@location_type_options}
                      />
                      <.input
                        field={@location_form[:parent_location_id]}
                        type="select"
                        label="Parent"
                        prompt="Root location"
                        options={@location_options}
                      />
                      <.input field={@location_form[:name]} type="text" label="Name" required />
                      <.input
                        field={@location_form[:description]}
                        type="textarea"
                        label="Description"
                      />
                      <.input
                        field={@location_form[:capital]}
                        type="checkbox"
                        label="Capital of selected hold"
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Create
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    :if={@selected_location && @location_type_options != []}
                    action="location_edit"
                    expanded_action={@expanded_action}
                    icon="hero-pencil-square"
                    title="Edit Location"
                  >
                    <.form
                      for={@location_edit_form}
                      id="location-edit-form"
                      phx-submit="update_location"
                      class="space-y-2"
                    >
                      <.input
                        field={@location_edit_form[:location_type_id]}
                        type="select"
                        label="Type"
                        options={@location_type_options}
                      />
                      <.input field={@location_edit_form[:name]} type="text" label="Name" required />
                      <.input
                        field={@location_edit_form[:description]}
                        type="textarea"
                        label="Description"
                      />
                      <.input
                        field={@location_edit_form[:capital]}
                        type="checkbox"
                        label="Capital of selected hold"
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Save
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    :if={@selected_hold}
                    action="commerce"
                    expanded_action={@expanded_action}
                    icon="hero-banknotes"
                    title="Add Commerce"
                  >
                    <.form
                      for={@commerce_form}
                      id="commerce-form"
                      phx-submit="create_commerce"
                      class="space-y-2"
                    >
                      <.input field={@commerce_form[:name]} type="text" label="Name" required />
                      <.input
                        field={@commerce_form[:kind]}
                        type="select"
                        label="Kind"
                        options={[
                          {"Income", "income"},
                          {"Expense", "expense"},
                          {"Asset", "asset"},
                          {"Liability", "liability"}
                        ]}
                      />
                      <.input field={@commerce_form[:category]} type="text" label="Category" />
                      <.input field={@commerce_form[:amount]} type="number" label="Amount" />
                      <.input field={@commerce_form[:currency]} type="text" label="Currency" />
                      <.input field={@commerce_form[:frequency]} type="text" label="Frequency" />
                      <.input
                        field={@commerce_form[:description]}
                        type="textarea"
                        label="Description"
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Create
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    :if={@selected_hold}
                    action="political_office"
                    expanded_action={@expanded_action}
                    icon="hero-scale"
                    title="Add Political Office"
                  >
                    <.form
                      for={@political_office_form}
                      id="political-office-form"
                      phx-submit="create_political_office"
                      class="space-y-2"
                    >
                      <.input
                        field={@political_office_form[:scope]}
                        type="select"
                        label="Scope"
                        options={[{"Hold", "hold"}, {"Province", "province"}]}
                      />
                      <.input
                        field={@political_office_form[:hold_id]}
                        type="select"
                        label="Hold"
                        options={@selected_hold_options}
                      />
                      <.input
                        field={@political_office_form[:province_id]}
                        type="select"
                        label="Province"
                        options={@province_options}
                      />
                      <.input
                        field={@political_office_form[:character_id]}
                        type="select"
                        label="Character"
                        prompt="Vacant"
                        options={@character_options}
                      />
                      <.input
                        field={@political_office_form[:office]}
                        type="text"
                        label="Office"
                        required
                      />
                      <.input
                        field={@political_office_form[:politics]}
                        type="text"
                        label="Politics"
                      />
                      <.input
                        field={@political_office_form[:description]}
                        type="textarea"
                        label="Description"
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Create
                      </.button>
                    </.form>
                  </.action_section>

                  <.action_section
                    :if={@selected_political_office}
                    action="political_office_edit"
                    expanded_action={@expanded_action}
                    icon="hero-pencil-square"
                    title="Edit Political Office"
                  >
                    <.form
                      for={@political_office_edit_form}
                      id="political-office-edit-form"
                      phx-submit="update_political_office"
                      class="space-y-2"
                    >
                      <.input
                        field={@political_office_edit_form[:id]}
                        type="select"
                        label="Office"
                        options={@political_office_options}
                      />
                      <.input
                        field={@political_office_edit_form[:character_id]}
                        type="select"
                        label="Character"
                        prompt="Vacant"
                        options={@character_options}
                      />
                      <.input
                        field={@political_office_edit_form[:office]}
                        type="text"
                        label="Office Name"
                        required
                      />
                      <.input
                        field={@political_office_edit_form[:politics]}
                        type="text"
                        label="Politics"
                      />
                      <.input
                        field={@political_office_edit_form[:description]}
                        type="textarea"
                        label="Description"
                      />
                      <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                        Save
                      </.button>
                    </.form>
                  </.action_section>
                </div>
              </aside>
            </div>
          <% else %>
            <%= cond do %>
              <% @section == "races" -> %>
                <div
                  id="races-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Races</h2>
                        <p class="text-xs text-zinc-500">World peoples and playable ancestries</p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@races)}
                      </span>
                    </div>

                    <div id="race-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div :if={@races == []} class="px-4 py-8 text-center text-sm text-zinc-500">
                        No races have been added to this world.
                      </div>

                      <div
                        :for={race <- @races}
                        class={[
                          "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                          @selected_race && @selected_race.id == race.id && "stone-selected"
                        ]}
                      >
                        <.link
                          patch={~p"/worlds/#{@world}/dashboard?section=races&race_id=#{race.id}"}
                          class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                        >
                          <div class="truncate text-sm font-semibold text-zinc-800">{race.name}</div>
                          <p class="mt-1 line-clamp-2 text-sm leading-6 text-zinc-600">
                            {race.description || "No description yet."}
                          </p>
                        </.link>
                        <button
                          type="button"
                          phx-click="delete_race"
                          phx-value-id={race.id}
                          data-confirm={"Delete #{race.name}?"}
                          class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                          aria-label={"Delete #{race.name}"}
                        >
                          <.icon name="hero-trash" class="size-4" />
                        </button>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_race, do: @selected_race.name, else: "No race selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div :if={is_nil(@selected_race)} class="py-8 text-center text-sm text-zinc-500">
                        Select a race to inspect its description.
                      </div>

                      <div :if={@selected_race} id="race-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">{@selected_race.name}</h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_race.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail label="World" value={@world.name} />
                          <.detail label="Section" value="Race" />
                        </div>

                        <div
                          :if={race_traits(@selected_race, "power") != []}
                          class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                        >
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">Powers</p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :for={trait <- race_traits(@selected_race, "power")}
                              class="py-2 first:pt-0 last:pb-0"
                            >
                              <div class="text-sm font-medium text-zinc-800">{trait.name}</div>
                              <p class="mt-0.5 text-sm leading-6 text-zinc-600">
                                {trait.description || "No description yet."}
                              </p>
                            </div>
                          </div>
                        </div>

                        <div
                          :if={race_traits(@selected_race, "perk") != []}
                          class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                        >
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">Perks</p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :for={trait <- race_traits(@selected_race, "perk")}
                              class="py-2 first:pt-0 last:pb-0"
                            >
                              <div class="text-sm font-medium text-zinc-800">{trait.name}</div>
                              <p class="mt-0.5 text-sm leading-6 text-zinc-600">
                                {trait.description || "No description yet."}
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create records for this section.</p>
                    </div>

                    <div id="race-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="race"
                        expanded_action={@expanded_action}
                        icon="hero-user-group"
                        title="Add Race"
                      >
                        <.form
                          for={@race_form}
                          id="race-form"
                          phx-submit="create_race"
                          class="space-y-2"
                        >
                          <.input field={@race_form[:name]} type="text" label="Name" required />
                          <.input
                            field={@race_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "guilds" -> %>
                <div
                  id="guilds-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Guilds</h2>
                        <p class="text-xs text-zinc-500">Orders, colleges, clans, and factions</p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@guilds)}
                      </span>
                    </div>

                    <div id="guild-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div :if={@guilds == []} class="px-4 py-8 text-center text-sm text-zinc-500">
                        No guilds have been added to this world.
                      </div>

                      <div
                        :for={guild <- @guilds}
                        class={[
                          "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                          @selected_guild && @selected_guild.id == guild.id && "stone-selected"
                        ]}
                      >
                        <.link
                          patch={~p"/worlds/#{@world}/dashboard?section=guilds&guild_id=#{guild.id}"}
                          class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                        >
                          <div class="truncate text-sm font-semibold text-zinc-800">
                            {guild.name}
                          </div>
                          <p class="mt-1 line-clamp-2 text-sm leading-6 text-zinc-600">
                            {guild.description || "No description yet."}
                          </p>
                        </.link>
                        <button
                          type="button"
                          phx-click="delete_guild"
                          phx-value-id={guild.id}
                          data-confirm={"Delete #{guild.name}?"}
                          class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                          aria-label={"Delete #{guild.name}"}
                        >
                          <.icon name="hero-trash" class="size-4" />
                        </button>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_guild, do: @selected_guild.name, else: "No guild selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_guild)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select a guild to inspect its description.
                      </div>

                      <div :if={@selected_guild} id="guild-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">
                            {@selected_guild.name}
                          </h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_guild.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail label="World" value={@world.name} />
                          <.detail label="Leader" value={display_value(@selected_guild.leader)} />
                          <.detail
                            label="Headquarters"
                            value={display_value(@selected_guild.headquarters)}
                          />
                          <.detail label="Alignment" value={display_value(@selected_guild.alignment)} />
                        </div>

                        <div
                          :if={guild_influences(@selected_guild) != []}
                          class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                        >
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">
                            Influences
                          </p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :for={influence <- guild_influences(@selected_guild)}
                              class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                            >
                              <div>
                                <div class="text-sm font-medium text-zinc-800">
                                  {influence_target(influence)}
                                </div>
                                <p class="text-xs text-zinc-500">
                                  {influence.relationship}
                                </p>
                              </div>
                              <button
                                type="button"
                                phx-click="delete_guild_influence"
                                phx-value-id={influence.id}
                                data-confirm={"Delete #{influence.relationship} relationship?"}
                                class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label="Delete guild influence"
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create records for this section.</p>
                    </div>

                    <div id="guild-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="guild"
                        expanded_action={@expanded_action}
                        icon="hero-shield-check"
                        title="Add Guild"
                      >
                        <.form
                          for={@guild_form}
                          id="guild-form"
                          phx-submit="create_guild"
                          class="space-y-2"
                        >
                          <.input field={@guild_form[:name]} type="text" label="Name" required />
                          <.input
                            field={@guild_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.input field={@guild_form[:leader]} type="text" label="Leader" />
                          <.input
                            field={@guild_form[:headquarters]}
                            type="text"
                            label="Headquarters"
                          />
                          <.input field={@guild_form[:alignment]} type="text" label="Alignment" />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@guild_options != [] && (@god_options != [] || @character_options != [])}
                        action="guild_influence"
                        expanded_action={@expanded_action}
                        icon="hero-link"
                        title="Add Influence"
                      >
                        <.form
                          for={@guild_influence_form}
                          id="guild-influence-form"
                          phx-submit="create_guild_influence"
                          class="space-y-2"
                        >
                          <.input
                            field={@guild_influence_form[:guild_id]}
                            type="select"
                            label="Guild"
                            options={@guild_options}
                          />
                          <.input
                            field={@guild_influence_form[:god_id]}
                            type="select"
                            label="God"
                            prompt="None"
                            options={@god_options}
                          />
                          <.input
                            field={@guild_influence_form[:character_id]}
                            type="select"
                            label="Character"
                            prompt="None"
                            options={@character_options}
                          />
                          <.input
                            field={@guild_influence_form[:relationship]}
                            type="text"
                            label="Relationship"
                            required
                          />
                          <.input
                            field={@guild_influence_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "gods" -> %>
                <div
                  id="gods-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Gods</h2>
                        <p class="text-xs text-zinc-500">Pantheons, patrons, and domains</p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@gods)}
                      </span>
                    </div>

                    <div id="god-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div :if={@gods == []} class="px-4 py-8 text-center text-sm text-zinc-500">
                        No gods have been added to this world.
                      </div>

                      <div
                        :for={{pantheon, pantheon_gods} <- grouped_gods(@gods)}
                        class="overflow-hidden rounded-md border border-zinc-200 bg-white"
                      >
                        <details class="group">
                          <summary class="flex cursor-pointer list-none items-center justify-between gap-2 px-3 py-2 text-[11px] font-semibold uppercase text-zinc-500 transition hover:bg-zinc-50">
                            <span class="flex min-w-0 items-center gap-2">
                              <.icon
                                name="hero-chevron-right"
                                class="size-3.5 shrink-0 group-open:hidden"
                              />
                              <.icon
                                name="hero-chevron-down"
                                class="hidden size-3.5 shrink-0 group-open:inline"
                              />
                              <span class="truncate">{display_value(pantheon)}</span>
                            </span>
                            <span>{length(pantheon_gods)}</span>
                          </summary>
                          <div class="space-y-1.5 border-t border-zinc-100 p-1.5">
                            <div
                              :for={god <- pantheon_gods}
                              class={[
                                "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                                @selected_god && @selected_god.id == god.id && "stone-selected"
                              ]}
                            >
                              <.link
                                patch={~p"/worlds/#{@world}/dashboard?section=gods&god_id=#{god.id}"}
                                class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                              >
                                <div class="truncate text-sm font-semibold text-zinc-800">
                                  {god.name}
                                </div>
                                <p class="mt-1 text-xs font-medium text-zinc-500">
                                  {display_value(god.domain)}
                                </p>
                              </.link>
                              <button
                                type="button"
                                phx-click="delete_god"
                                phx-value-id={god.id}
                                data-confirm={"Delete #{god.name}?"}
                                class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{god.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </details>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_god, do: @selected_god.name, else: "No god selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div :if={is_nil(@selected_god)} class="py-8 text-center text-sm text-zinc-500">
                        Select a god to inspect pantheon and domains.
                      </div>

                      <div :if={@selected_god} id="god-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">{@selected_god.name}</h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_god.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail label="Pantheon" value={display_value(@selected_god.pantheon)} />
                          <.detail label="Domain" value={display_value(@selected_god.domain)} />
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create records for this section.</p>
                    </div>

                    <div id="god-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="god"
                        expanded_action={@expanded_action}
                        icon="hero-sparkles"
                        title="Add God"
                      >
                        <.form
                          for={@god_form}
                          id="god-form"
                          phx-submit="create_god"
                          class="space-y-2"
                        >
                          <.input field={@god_form[:name]} type="text" label="Name" required />
                          <.input field={@god_form[:pantheon]} type="text" label="Pantheon" />
                          <.input field={@god_form[:domain]} type="text" label="Domain" />
                          <.input
                            field={@god_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "civilizations" -> %>
                <div
                  id="civilizations-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Civilizations</h2>
                        <p class="text-xs text-zinc-500">
                          Ancient peoples, lost cultures, and legacies
                        </p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@civilizations)}
                      </span>
                    </div>

                    <div
                      id="civilization-list"
                      class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5"
                    >
                      <div
                        :if={@civilizations == []}
                        class="px-4 py-8 text-center text-sm text-zinc-500"
                      >
                        No civilizations have been added to this world.
                      </div>

                      <div
                        :for={civilization <- @civilizations}
                        class={[
                          "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                          @selected_civilization && @selected_civilization.id == civilization.id &&
                            "bg-zinc-100"
                        ]}
                      >
                        <.link
                          patch={
                            ~p"/worlds/#{@world}/dashboard?section=civilizations&civilization_id=#{civilization.id}"
                          }
                          class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                        >
                          <div class="truncate text-sm font-semibold text-zinc-800">
                            {civilization.name}
                          </div>
                          <p class="mt-1 text-xs font-medium text-zinc-500">
                            {display_value(civilization.status)}
                          </p>
                        </.link>
                        <button
                          type="button"
                          phx-click="delete_civilization"
                          phx-value-id={civilization.id}
                          data-confirm={"Delete #{civilization.name}?"}
                          class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                          aria-label={"Delete #{civilization.name}"}
                        >
                          <.icon name="hero-trash" class="size-4" />
                        </button>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_civilization,
                            do: @selected_civilization.name,
                            else: "No civilization selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_civilization)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select a civilization to inspect era, status, and legacy.
                      </div>

                      <div :if={@selected_civilization} id="civilization-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">
                            {@selected_civilization.name}
                          </h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_civilization.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail
                            label="Timeline Era"
                            value={record_name(@selected_civilization.timeline_era)}
                          />
                          <.detail label="Era Note" value={display_value(@selected_civilization.era)} />
                          <.detail
                            label="Status"
                            value={display_value(@selected_civilization.status)}
                          />
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create records for this section.</p>
                    </div>

                    <div id="civilization-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="civilization"
                        expanded_action={@expanded_action}
                        icon="hero-building-library"
                        title="Add Civilization"
                      >
                        <.form
                          for={@civilization_form}
                          id="civilization-form"
                          phx-submit="create_civilization"
                          class="space-y-2"
                        >
                          <.input
                            field={@civilization_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input
                            field={@civilization_form[:timeline_era_id]}
                            type="select"
                            label="Timeline Era"
                            prompt="None"
                            options={@timeline_era_options}
                          />
                          <.input field={@civilization_form[:era]} type="text" label="Era Note" />
                          <.input field={@civilization_form[:status]} type="text" label="Status" />
                          <.input
                            field={@civilization_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "characters" -> %>
                <div
                  id="characters-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Characters</h2>
                        <p class="text-xs text-zinc-500">People, offices, allegiances, and homes</p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@characters)}
                      </span>
                    </div>

                    <div id="character-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div :if={@characters == []} class="px-4 py-8 text-center text-sm text-zinc-500">
                        No characters have been added to this world.
                      </div>

                      <div
                        :for={{race, race_characters} <- grouped_characters(@characters)}
                        class="overflow-hidden rounded-md border border-zinc-200 bg-white"
                      >
                        <details class="group">
                          <summary class="flex cursor-pointer list-none items-center justify-between gap-2 px-3 py-2 text-[11px] font-semibold uppercase text-zinc-500 transition hover:bg-zinc-50">
                            <span class="flex min-w-0 items-center gap-2">
                              <.icon
                                name="hero-chevron-right"
                                class="size-3.5 shrink-0 group-open:hidden"
                              />
                              <.icon
                                name="hero-chevron-down"
                                class="hidden size-3.5 shrink-0 group-open:inline"
                              />
                              <span class="truncate">{race}</span>
                            </span>
                            <span>{length(race_characters)}</span>
                          </summary>
                          <div class="space-y-1.5 border-t border-zinc-100 p-1.5">
                            <div
                              :for={character <- race_characters}
                              class={[
                                "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                                @selected_character && @selected_character.id == character.id &&
                                  "stone-selected"
                              ]}
                            >
                              <.link
                                patch={
                                  ~p"/worlds/#{@world}/dashboard?section=characters&character_id=#{character.id}"
                                }
                                class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                              >
                                <div class="truncate text-sm font-semibold text-zinc-800">
                                  {character.name}
                                </div>
                                <p class="mt-1 text-xs font-medium text-zinc-500">
                                  {display_value(character.role)}
                                </p>
                              </.link>
                              <button
                                type="button"
                                phx-click="delete_character"
                                phx-value-id={character.id}
                                data-confirm={"Delete #{character.name}?"}
                                class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{character.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </details>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_character,
                            do: @selected_character.name,
                            else: "No character selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_character)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select a character to inspect role, politics, and location.
                      </div>

                      <div :if={@selected_character} id="character-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">
                            {@selected_character.name}
                          </h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_character.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail label="Title" value={display_value(@selected_character.title)} />
                          <.detail label="Role" value={display_value(@selected_character.role)} />
                          <.detail
                            label="Politics"
                            value={display_value(@selected_character.politics)}
                          />
                          <.detail
                            label="Status"
                            value={character_status_label(@selected_character.status)}
                          />
                          <.detail label="Race" value={record_name(@selected_character.race)} />
                          <.detail label="Guild" value={record_name(@selected_character.guild)} />
                          <.detail
                            label="Home"
                            value={record_name(@selected_character.home_location)}
                          />
                        </div>

                        <div
                          :if={character_occupations(@selected_character) != []}
                          class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                        >
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">
                            Occupations
                          </p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :for={occupation <- character_occupations(@selected_character)}
                              class="py-2 first:pt-0 last:pb-0"
                            >
                              <div class="text-sm font-medium text-zinc-800">
                                {occupation.occupation.name}
                              </div>
                              <p class="text-xs text-zinc-500">
                                {display_value(occupation.rank)}
                              </p>
                            </div>
                          </div>
                        </div>

                        <div
                          :if={character_skills(@selected_character) != []}
                          class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2"
                        >
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">
                            Skills
                          </p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :for={skill <- character_skills(@selected_character)}
                              class="py-2 first:pt-0 last:pb-0"
                            >
                              <div class="text-sm font-medium text-zinc-800">
                                {skill.skill.name}
                              </div>
                              <p class="text-xs text-zinc-500">
                                {display_value(skill.level)}
                              </p>
                            </div>
                          </div>
                        </div>

                        <div class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2">
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">
                            Inventory
                          </p>

                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :if={@selected_character_inventory_categories == []}
                              class="py-2 text-sm text-zinc-500"
                            >
                              No inventory categories have been added.
                            </div>
                            <div
                              :for={category <- @selected_character_inventory_categories}
                              class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                            >
                              <div>
                                <div class="text-sm font-medium text-zinc-800">
                                  {category.position}. {category.name}
                                </div>
                                <p class="text-xs text-zinc-500">
                                  {category.description || "Inventory category"}
                                </p>
                              </div>
                              <button
                                type="button"
                                phx-click="delete_inventory_category"
                                phx-value-id={category.id}
                                data-confirm={"Delete #{category.name}?"}
                                class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{category.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>

                          <p class="mt-4 text-[11px] font-semibold uppercase text-zinc-500">
                            Items
                          </p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :if={@selected_character_inventory_items == []}
                              class="py-2 text-sm text-zinc-500"
                            >
                              No items have been added to this character.
                            </div>
                            <div
                              :for={inventory_item <- @selected_character_inventory_items}
                              class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                            >
                              <div>
                                <div class="text-sm font-medium text-zinc-800">
                                  {inventory_item_name(inventory_item)}
                                </div>
                                <p class="text-xs text-zinc-500">
                                  {display_value(record_name(inventory_item.inventory_category))} / qty {display_value(
                                    inventory_item.quantity
                                  )} / {if inventory_item.equipped, do: "equipped", else: "stored"}
                                </p>
                              </div>
                              <button
                                type="button"
                                phx-click="delete_inventory_item"
                                phx-value-id={inventory_item.id}
                                data-confirm={"Remove #{inventory_item_name(inventory_item)}?"}
                                class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Remove #{inventory_item_name(inventory_item)}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create records for this section.</p>
                    </div>

                    <div id="character-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="character"
                        expanded_action={@expanded_action}
                        icon="hero-identification"
                        title="Add Character"
                      >
                        <.form
                          for={@character_form}
                          id="character-form"
                          phx-submit="create_character"
                          class="space-y-2"
                        >
                          <.input field={@character_form[:name]} type="text" label="Name" required />
                          <.input field={@character_form[:title]} type="text" label="Title" />
                          <.input field={@character_form[:role]} type="text" label="Role" />
                          <.input
                            field={@character_form[:politics]}
                            type="text"
                            label="Politics"
                          />
                          <.input
                            field={@character_form[:status]}
                            type="select"
                            label="Status"
                            options={Character.status_options()}
                          />
                          <.input
                            field={@character_form[:race_id]}
                            type="select"
                            label="Race"
                            prompt="None"
                            options={@race_options}
                          />
                          <.input
                            field={@character_form[:guild_id]}
                            type="select"
                            label="Guild"
                            prompt="None"
                            options={@guild_options}
                          />
                          <.input
                            field={@character_form[:home_location_id]}
                            type="select"
                            label="Home Location"
                            prompt="None"
                            options={@all_location_options}
                          />
                          <.input
                            field={@character_form[:occupation_id]}
                            type="select"
                            label="Occupation"
                            prompt="None"
                            options={@occupation_options}
                          />
                          <.input
                            field={@character_form[:skill_id]}
                            type="select"
                            label="Skill"
                            prompt="None"
                            options={@skill_options}
                          />
                          <.input
                            field={@character_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_character}
                        action="inventory_category"
                        expanded_action={@expanded_action}
                        icon="hero-folder"
                        title="Add Inventory Category"
                      >
                        <.form
                          for={@inventory_category_form}
                          id="inventory-category-form"
                          phx-submit="create_inventory_category"
                          class="space-y-2"
                        >
                          <.input
                            field={@inventory_category_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input
                            field={@inventory_category_form[:position]}
                            type="number"
                            label="Position"
                          />
                          <.input
                            field={@inventory_category_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_character && @item_options != []}
                        action="inventory_item"
                        expanded_action={@expanded_action}
                        icon="hero-archive-box"
                        title="Add Character Item"
                      >
                        <.form
                          for={@inventory_item_form}
                          id="inventory-item-form"
                          phx-submit="create_inventory_item"
                          class="space-y-2"
                        >
                          <.input
                            field={@inventory_item_form[:item_id]}
                            type="select"
                            label="Catalog Item"
                            options={@item_options}
                          />
                          <.input
                            field={@inventory_item_form[:inventory_category_id]}
                            type="select"
                            label="Category"
                            prompt="None"
                            options={@character_inventory_category_options}
                          />
                          <.input
                            field={@inventory_item_form[:name]}
                            type="text"
                            label="Custom Name"
                          />
                          <.input
                            field={@inventory_item_form[:quantity]}
                            type="number"
                            label="Quantity"
                          />
                          <.input
                            field={@inventory_item_form[:equipped]}
                            type="checkbox"
                            label="Equipped"
                          />
                          <.input
                            field={@inventory_item_form[:notes]}
                            type="textarea"
                            label="Notes"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Add
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        action="occupation"
                        expanded_action={@expanded_action}
                        icon="hero-briefcase"
                        title="Add Occupation"
                      >
                        <.form
                          for={@occupation_form}
                          id="occupation-form"
                          phx-submit="create_occupation"
                          class="space-y-2"
                        >
                          <.input field={@occupation_form[:name]} type="text" label="Name" required />
                          <.input
                            field={@occupation_form[:category]}
                            type="text"
                            label="Category"
                          />
                          <.input
                            field={@occupation_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        action="skill"
                        expanded_action={@expanded_action}
                        icon="hero-sparkles"
                        title="Add Skill"
                      >
                        <.form
                          for={@skill_form}
                          id="skill-form"
                          phx-submit="create_skill"
                          class="space-y-2"
                        >
                          <.input field={@skill_form[:name]} type="text" label="Name" required />
                          <.input field={@skill_form[:category]} type="text" label="Category" />
                          <.input
                            field={@skill_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "skills" -> %>
                <div
                  id="skills-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Skills</h2>
                        <p class="text-xs text-zinc-500">
                          Abilities, training paths, and character proficiencies
                        </p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@skills)}
                      </span>
                    </div>

                    <div id="skill-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div :if={@skills == []} class="px-4 py-8 text-center text-sm text-zinc-500">
                        No skills have been added to this world.
                      </div>

                      <div
                        :for={{category, category_skills} <- grouped_skills(@skills)}
                        class="overflow-hidden rounded-md border border-zinc-200 bg-white"
                      >
                        <details class="group">
                          <summary class="flex cursor-pointer list-none items-center justify-between gap-2 px-3 py-2 text-[11px] font-semibold uppercase text-zinc-500 transition hover:bg-zinc-50">
                            <span class="flex min-w-0 items-center gap-2">
                              <.icon
                                name="hero-chevron-right"
                                class="size-3.5 shrink-0 group-open:hidden"
                              />
                              <.icon
                                name="hero-chevron-down"
                                class="hidden size-3.5 shrink-0 group-open:inline"
                              />
                              <span class="truncate">{display_value(category)}</span>
                            </span>
                            <span>{length(category_skills)}</span>
                          </summary>
                          <div class="space-y-1.5 border-t border-zinc-100 p-1.5">
                            <div
                              :for={skill <- category_skills}
                              class={[
                                "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                                @selected_skill && @selected_skill.id == skill.id &&
                                  "stone-selected"
                              ]}
                            >
                              <.link
                                patch={
                                  ~p"/worlds/#{@world}/dashboard?section=skills&skill_id=#{skill.id}"
                                }
                                class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                              >
                                <div class="truncate text-sm font-semibold text-zinc-800">
                                  {skill.name}
                                </div>
                                <p class="mt-1 line-clamp-2 text-xs leading-5 text-zinc-500">
                                  {skill.description || "No description yet."}
                                </p>
                              </.link>
                              <button
                                type="button"
                                phx-click="delete_skill"
                                phx-value-id={skill.id}
                                data-confirm={"Delete #{skill.name}?"}
                                class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{skill.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </details>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_skill, do: @selected_skill.name, else: "No skill selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_skill)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select a skill to inspect its category and description.
                      </div>

                      <div :if={@selected_skill} id="skill-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">{@selected_skill.name}</h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_skill.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail label="Category" value={display_value(@selected_skill.category)} />
                          <.detail label="Skill Tree" value={record_name(@selected_skill.skill_tree)} />
                        </div>

                        <div class="overflow-hidden rounded-md border border-zinc-200 bg-zinc-50">
                          <div class="flex items-center justify-between gap-3 border-b border-zinc-200 bg-white px-3 py-2">
                            <p class="text-[11px] font-semibold uppercase text-zinc-500">
                              Progression
                            </p>
                            <div
                              id="skill-progression-tabs"
                              class="flex overflow-hidden rounded border border-zinc-200 bg-zinc-50 p-0.5"
                            >
                              <button
                                type="button"
                                phx-click="set_skill_detail_tab"
                                phx-value-tab="levels"
                                class={[
                                  "rounded px-2.5 py-1 text-xs font-medium transition",
                                  @skill_detail_tab == "levels" && "bg-white text-zinc-800 shadow-sm",
                                  @skill_detail_tab != "levels" &&
                                    "text-zinc-500 hover:bg-white hover:text-zinc-700"
                                ]}
                              >
                                Levels
                              </button>
                              <button
                                type="button"
                                phx-click="set_skill_detail_tab"
                                phx-value-tab="perks"
                                class={[
                                  "rounded px-2.5 py-1 text-xs font-medium transition",
                                  @skill_detail_tab == "perks" && "bg-white text-zinc-800 shadow-sm",
                                  @skill_detail_tab != "perks" &&
                                    "text-zinc-500 hover:bg-white hover:text-zinc-700"
                                ]}
                              >
                                Perks
                              </button>
                            </div>
                          </div>

                          <div
                            :if={@skill_detail_tab == "levels"}
                            id="skill-levels-tab"
                            class="px-3 py-2"
                          >
                            <div class="flex flex-col divide-y divide-zinc-100">
                              <div
                                :if={skill_levels(@selected_skill) == []}
                                class="py-2 text-sm text-zinc-500"
                              >
                                No skill levels have been added.
                              </div>
                              <div
                                :for={level <- skill_levels(@selected_skill)}
                                class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                              >
                                <div>
                                  <div class="text-sm font-medium text-zinc-800">
                                    {level.rank}. {level.name}
                                  </div>
                                  <p class="text-xs text-zinc-500">
                                    Minimum skill {display_value(level.minimum_value)}
                                  </p>
                                </div>
                                <button
                                  type="button"
                                  phx-click="delete_skill_level"
                                  phx-value-id={level.id}
                                  data-confirm={"Delete #{level.name}?"}
                                  class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                  aria-label={"Delete #{level.name}"}
                                >
                                  <.icon name="hero-trash" class="size-4" />
                                </button>
                              </div>
                            </div>
                          </div>

                          <div
                            :if={@skill_detail_tab == "perks"}
                            id="skill-perks-tab"
                            class="px-3 py-2"
                          >
                            <div
                              :if={is_nil(@selected_skill.skill_tree)}
                              class="py-2 text-sm text-zinc-500"
                            >
                              No skill tree has been added.
                            </div>
                            <div
                              :if={@selected_skill.skill_tree}
                              class="flex flex-col divide-y divide-zinc-100"
                            >
                              <div
                                :if={skill_tree_perks(@selected_skill) == []}
                                class="py-2 text-sm text-zinc-500"
                              >
                                No perks have been added to this tree.
                              </div>
                              <div
                                :for={perk <- skill_tree_perks(@selected_skill)}
                                class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                              >
                                <div>
                                  <div class="text-sm font-medium text-zinc-800">
                                    {perk.position}. {perk.name}
                                  </div>
                                  <p class="text-xs text-zinc-500">
                                    Requires {display_value(perk.required_level)} / {display_value(
                                      perk.ranks
                                    )} ranks
                                  </p>
                                </div>
                                <button
                                  type="button"
                                  phx-click="delete_skill_perk"
                                  phx-value-id={perk.id}
                                  data-confirm={"Delete #{perk.name}?"}
                                  class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                  aria-label={"Delete #{perk.name}"}
                                >
                                  <.icon name="hero-trash" class="size-4" />
                                </button>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create and edit custom skills.</p>
                    </div>

                    <div id="skill-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="skill"
                        expanded_action={@expanded_action}
                        icon="hero-sparkles"
                        title="Add Skill"
                      >
                        <.form
                          for={@skill_form}
                          id="skill-form"
                          phx-submit="create_skill"
                          class="space-y-2"
                        >
                          <.input field={@skill_form[:name]} type="text" label="Name" required />
                          <.input field={@skill_form[:category]} type="text" label="Category" />
                          <.input
                            field={@skill_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_skill}
                        action="skill_level"
                        expanded_action={@expanded_action}
                        icon="hero-bars-3-bottom-left"
                        title="Add Skill Level"
                      >
                        <.form
                          for={@skill_level_form}
                          id="skill-level-form"
                          phx-submit="create_skill_level"
                          class="space-y-2"
                        >
                          <.input
                            field={@skill_level_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input field={@skill_level_form[:rank]} type="number" label="Rank" />
                          <.input
                            field={@skill_level_form[:minimum_value]}
                            type="number"
                            label="Minimum Skill"
                          />
                          <.input
                            field={@skill_level_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_skill && @selected_skill.skill_tree}
                        action="skill_perk"
                        expanded_action={@expanded_action}
                        icon="hero-star"
                        title="Add Perk"
                      >
                        <.form
                          for={@skill_perk_form}
                          id="skill-perk-form"
                          phx-submit="create_skill_perk"
                          class="space-y-2"
                        >
                          <.input
                            field={@skill_perk_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input
                            field={@skill_perk_form[:required_level]}
                            type="number"
                            label="Required Skill"
                          />
                          <.input field={@skill_perk_form[:ranks]} type="number" label="Ranks" />
                          <.input
                            field={@skill_perk_form[:position]}
                            type="number"
                            label="Position"
                          />
                          <.input
                            field={@skill_perk_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_skill}
                        action="skill_edit"
                        expanded_action={@expanded_action}
                        icon="hero-pencil-square"
                        title="Edit Skill"
                      >
                        <.form
                          for={@skill_edit_form}
                          id="skill-edit-form"
                          phx-submit="update_skill"
                          class="space-y-2"
                        >
                          <.input
                            field={@skill_edit_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input field={@skill_edit_form[:category]} type="text" label="Category" />
                          <.input
                            field={@skill_edit_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Save
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "spells" -> %>
                <div
                  id="spells-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Spells</h2>
                        <p class="text-xs text-zinc-500">
                          Magic schools, levels, costs, and spellbook entries
                        </p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@spells)}
                      </span>
                    </div>

                    <div id="spell-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div :if={@spells == []} class="px-4 py-8 text-center text-sm text-zinc-500">
                        No spells have been added to this world.
                      </div>

                      <div
                        :for={{school, school_spells} <- grouped_spells(@spells)}
                        class="overflow-hidden rounded-md border border-zinc-200 bg-white"
                      >
                        <details class="group">
                          <summary class="flex cursor-pointer list-none items-center justify-between gap-2 px-3 py-2 text-[11px] font-semibold uppercase text-zinc-500 transition hover:bg-zinc-50">
                            <span class="flex min-w-0 items-center gap-2">
                              <.icon
                                name="hero-chevron-right"
                                class="size-3.5 shrink-0 group-open:hidden"
                              />
                              <.icon
                                name="hero-chevron-down"
                                class="hidden size-3.5 shrink-0 group-open:inline"
                              />
                              <span class="truncate">{display_value(school)}</span>
                            </span>
                            <span>{length(school_spells)}</span>
                          </summary>
                          <div class="space-y-1.5 border-t border-zinc-100 p-1.5">
                            <div
                              :for={spell <- school_spells}
                              class={[
                                "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                                @selected_spell && @selected_spell.id == spell.id &&
                                  "stone-selected"
                              ]}
                            >
                              <.link
                                patch={
                                  ~p"/worlds/#{@world}/dashboard?section=spells&spell_id=#{spell.id}"
                                }
                                class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                              >
                                <div class="truncate text-sm font-semibold text-zinc-800">
                                  {spell.name}
                                </div>
                                <p class="mt-1 text-xs font-medium text-zinc-500">
                                  {display_value(spell.level)}
                                </p>
                              </.link>
                              <button
                                type="button"
                                phx-click="delete_spell"
                                phx-value-id={spell.id}
                                data-confirm={"Delete #{spell.name}?"}
                                class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{spell.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </details>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_spell, do: @selected_spell.name, else: "No spell selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_spell)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select a spell to inspect its school, level, cost, and source.
                      </div>

                      <div :if={@selected_spell} id="spell-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">{@selected_spell.name}</h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_spell.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail label="School" value={display_value(@selected_spell.school)} />
                          <.detail label="Level" value={display_value(@selected_spell.level)} />
                          <.detail
                            label="Magicka Cost"
                            value={display_value(@selected_spell.magicka_cost)}
                          />
                          <.detail label="Source" value={display_value(@selected_spell.source)} />
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create and edit custom spells.</p>
                    </div>

                    <div id="spell-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="spell"
                        expanded_action={@expanded_action}
                        icon="hero-bolt"
                        title="Add Spell"
                      >
                        <.form
                          for={@spell_form}
                          id="spell-form"
                          phx-submit="create_spell"
                          class="space-y-2"
                        >
                          <.input field={@spell_form[:name]} type="text" label="Name" required />
                          <.input field={@spell_form[:school]} type="text" label="School" />
                          <.input field={@spell_form[:level]} type="text" label="Level" />
                          <.input
                            field={@spell_form[:magicka_cost]}
                            type="number"
                            label="Magicka Cost"
                          />
                          <.input field={@spell_form[:source]} type="text" label="Source" />
                          <.input
                            field={@spell_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_spell}
                        action="spell_edit"
                        expanded_action={@expanded_action}
                        icon="hero-pencil-square"
                        title="Edit Spell"
                      >
                        <.form
                          for={@spell_edit_form}
                          id="spell-edit-form"
                          phx-submit="update_spell"
                          class="space-y-2"
                        >
                          <.input
                            field={@spell_edit_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input field={@spell_edit_form[:school]} type="text" label="School" />
                          <.input field={@spell_edit_form[:level]} type="text" label="Level" />
                          <.input
                            field={@spell_edit_form[:magicka_cost]}
                            type="number"
                            label="Magicka Cost"
                          />
                          <.input field={@spell_edit_form[:source]} type="text" label="Source" />
                          <.input
                            field={@spell_edit_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Save
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "items" -> %>
                <div
                  id="items-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Items</h2>
                        <p class="text-xs text-zinc-500">
                          Weapons, apparel, food, and inventory stock
                        </p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@items)}
                      </span>
                    </div>

                    <div id="item-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div :if={@items == []} class="px-4 py-8 text-center text-sm text-zinc-500">
                        No items have been added to this world.
                      </div>

                      <div
                        :for={{category, category_items} <- grouped_items(@items)}
                        class="overflow-hidden rounded-md border border-zinc-200 bg-white"
                      >
                        <details class="group">
                          <summary class="flex cursor-pointer list-none items-center justify-between gap-2 px-3 py-2 text-[11px] font-semibold uppercase text-zinc-500 transition hover:bg-zinc-50">
                            <span class="flex min-w-0 items-center gap-2">
                              <.icon
                                name="hero-chevron-right"
                                class="size-3.5 shrink-0 group-open:hidden"
                              />
                              <.icon
                                name="hero-chevron-down"
                                class="hidden size-3.5 shrink-0 group-open:inline"
                              />
                              <span class="truncate">{item_category_label(category)}</span>
                            </span>
                            <span>{length(category_items)}</span>
                          </summary>
                          <div class="space-y-1.5 border-t border-zinc-100 p-1.5">
                            <div
                              :for={item <- category_items}
                              class={[
                                "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                                @selected_item && @selected_item.id == item.id && "stone-selected"
                              ]}
                            >
                              <.link
                                patch={
                                  ~p"/worlds/#{@world}/dashboard?section=items&item_id=#{item.id}"
                                }
                                class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                              >
                                <div class="truncate text-sm font-semibold text-zinc-800">
                                  {item.name}
                                </div>
                                <p class="mt-1 text-xs font-medium text-zinc-500">
                                  {display_value(item.kind)}
                                </p>
                              </.link>
                              <button
                                type="button"
                                phx-click="delete_item"
                                phx-value-id={item.id}
                                data-confirm={"Delete #{item.name}?"}
                                class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{item.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </details>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_item, do: @selected_item.name, else: "No item selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_item)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select an item to inspect its category, stats, and source.
                      </div>

                      <div :if={@selected_item} id="item-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">{@selected_item.name}</h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_item.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail
                            label="Category"
                            value={item_category_label(@selected_item.category)}
                          />
                          <.detail label="Kind" value={display_value(@selected_item.kind)} />
                          <.detail label="Material" value={display_value(@selected_item.material)} />
                          <.detail label="Hands" value={display_value(@selected_item.hands)} />
                          <.detail label="Damage" value={display_value(@selected_item.damage)} />
                          <.detail
                            label="Critical Damage"
                            value={display_value(@selected_item.critical_damage)}
                          />
                          <.detail label="Weight" value={display_value(@selected_item.weight)} />
                          <.detail label="Value" value={display_value(@selected_item.value)} />
                          <.detail label="Source" value={display_value(@selected_item.source)} />
                        </div>

                        <div
                          id="item-effects"
                          class="overflow-hidden rounded-md border border-zinc-200 bg-zinc-50"
                        >
                          <div class="border-b border-zinc-200 bg-white px-3 py-2">
                            <p class="text-[11px] font-semibold uppercase text-zinc-500">
                              Effects
                            </p>
                          </div>
                          <div class="flex flex-col divide-y divide-zinc-100 px-3 py-2">
                            <div
                              :if={@selected_item_effects == []}
                              class="py-2 text-sm text-zinc-500"
                            >
                              No effects have been added to this item.
                            </div>
                            <div
                              :for={item_effect <- @selected_item_effects}
                              class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                            >
                              <div>
                                <div class="text-sm font-medium text-zinc-800">
                                  {item_effect.position}. {record_name(item_effect.effect)}
                                </div>
                                <p class="text-xs text-zinc-500">
                                  {display_value(item_effect.notes)}
                                </p>
                              </div>
                              <button
                                type="button"
                                phx-click="delete_item_effect"
                                phx-value-id={item_effect.id}
                                data-confirm={"Remove #{record_name(item_effect.effect)}?"}
                                class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Remove #{record_name(item_effect.effect)}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">
                        Create and edit reusable catalog items.
                      </p>
                    </div>

                    <div id="item-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="item"
                        expanded_action={@expanded_action}
                        icon="hero-archive-box"
                        title="Add Item"
                      >
                        <.form
                          for={@item_form}
                          id="item-form"
                          phx-submit="create_item"
                          class="space-y-2"
                        >
                          <.input field={@item_form[:name]} type="text" label="Name" required />
                          <.input
                            field={@item_form[:category]}
                            type="select"
                            label="Category"
                            options={item_category_options()}
                          />
                          <.input field={@item_form[:kind]} type="text" label="Kind" />
                          <.input field={@item_form[:material]} type="text" label="Material" />
                          <.input field={@item_form[:hands]} type="text" label="Hands" />
                          <.input field={@item_form[:damage]} type="number" label="Damage" />
                          <.input
                            field={@item_form[:critical_damage]}
                            type="number"
                            label="Critical Damage"
                          />
                          <.input field={@item_form[:weight]} type="number" label="Weight" step="0.1" />
                          <.input field={@item_form[:value]} type="number" label="Value" />
                          <.input field={@item_form[:source]} type="text" label="Source" />
                          <.input
                            field={@item_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_item}
                        action="item_edit"
                        expanded_action={@expanded_action}
                        icon="hero-pencil-square"
                        title="Edit Item"
                      >
                        <.form
                          for={@item_edit_form}
                          id="item-edit-form"
                          phx-submit="update_item"
                          class="space-y-2"
                        >
                          <.input
                            field={@item_edit_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input
                            field={@item_edit_form[:category]}
                            type="select"
                            label="Category"
                            options={item_category_options()}
                          />
                          <.input field={@item_edit_form[:kind]} type="text" label="Kind" />
                          <.input field={@item_edit_form[:material]} type="text" label="Material" />
                          <.input field={@item_edit_form[:hands]} type="text" label="Hands" />
                          <.input field={@item_edit_form[:damage]} type="number" label="Damage" />
                          <.input
                            field={@item_edit_form[:critical_damage]}
                            type="number"
                            label="Critical Damage"
                          />
                          <.input
                            field={@item_edit_form[:weight]}
                            type="number"
                            label="Weight"
                            step="0.1"
                          />
                          <.input field={@item_edit_form[:value]} type="number" label="Value" />
                          <.input field={@item_edit_form[:source]} type="text" label="Source" />
                          <.input
                            field={@item_edit_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Save
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        action="effect"
                        expanded_action={@expanded_action}
                        icon="hero-beaker"
                        title="Add Effect"
                      >
                        <.form
                          for={@effect_form}
                          id="effect-form"
                          phx-submit="create_effect"
                          class="space-y-2"
                        >
                          <.input field={@effect_form[:name]} type="text" label="Name" required />
                          <.input field={@effect_form[:category]} type="text" label="Category" />
                          <.input
                            field={@effect_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_item && @effect_options != []}
                        action="item_effect"
                        expanded_action={@expanded_action}
                        icon="hero-link"
                        title="Add Item Effect"
                      >
                        <.form
                          for={@item_effect_form}
                          id="item-effect-form"
                          phx-submit="create_item_effect"
                          class="space-y-2"
                        >
                          <.input
                            field={@item_effect_form[:effect_id]}
                            type="select"
                            label="Effect"
                            options={@effect_options}
                          />
                          <.input
                            field={@item_effect_form[:position]}
                            type="number"
                            label="Position"
                            required
                          />
                          <.input
                            field={@item_effect_form[:notes]}
                            type="textarea"
                            label="Notes"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Attach
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "bestiary" -> %>
                <div
                  id="bestiary-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Bestiary</h2>
                        <p class="text-xs text-zinc-500">Creature types, habitats, and lairs</p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@creatures)}
                      </span>
                    </div>

                    <div id="creature-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div
                        :if={@creatures == []}
                        class="px-4 py-8 text-center text-sm text-zinc-500"
                      >
                        No creatures have been added to this world.
                      </div>

                      <div
                        :for={{creature_type, type_creatures} <- grouped_creatures(@creatures)}
                        class="overflow-hidden rounded-md border border-zinc-200 bg-white"
                      >
                        <details class="group">
                          <summary class="flex cursor-pointer list-none items-center justify-between gap-2 px-3 py-2 text-[11px] font-semibold uppercase text-zinc-500 transition hover:bg-zinc-50">
                            <span class="flex min-w-0 items-center gap-2">
                              <.icon
                                name="hero-chevron-right"
                                class="size-3.5 shrink-0 group-open:hidden"
                              />
                              <.icon
                                name="hero-chevron-down"
                                class="hidden size-3.5 shrink-0 group-open:inline"
                              />
                              <span class="truncate">{creature_type}</span>
                            </span>
                            <span>{length(type_creatures)}</span>
                          </summary>
                          <div class="space-y-1.5 border-t border-zinc-100 p-1.5">
                            <div
                              :for={creature <- type_creatures}
                              class={[
                                "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                                @selected_creature && @selected_creature.id == creature.id &&
                                  "stone-selected"
                              ]}
                            >
                              <.link
                                patch={
                                  ~p"/worlds/#{@world}/dashboard?section=bestiary&creature_id=#{creature.id}"
                                }
                                class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                              >
                                <div class="truncate text-sm font-semibold text-zinc-800">
                                  {creature.name}
                                </div>
                                <p class="mt-1 text-xs font-medium text-zinc-500">
                                  {display_value(creature.danger_level)}
                                </p>
                              </.link>
                              <button
                                type="button"
                                phx-click="delete_creature"
                                phx-value-id={creature.id}
                                data-confirm={"Delete #{creature.name}?"}
                                class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{creature.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </details>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_creature,
                            do: @selected_creature.name,
                            else: "No creature selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_creature)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select a creature to inspect its habitat, temperament, and known locations.
                      </div>

                      <div :if={@selected_creature} id="creature-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">
                            {@selected_creature.name}
                          </h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_creature.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail
                            label="Type"
                            value={record_name(@selected_creature.creature_type)}
                          />
                          <.detail
                            label="Danger"
                            value={display_value(@selected_creature.danger_level)}
                          />
                          <.detail
                            label="Habitat"
                            value={display_value(@selected_creature.habitat)}
                          />
                          <.detail
                            label="Temperament"
                            value={display_value(@selected_creature.temperament)}
                          />
                        </div>

                        <div class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2">
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">
                            Known Locations
                          </p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :if={creature_locations(@selected_creature) == []}
                              class="py-2 text-sm text-zinc-500"
                            >
                              No location links have been added.
                            </div>
                            <div
                              :for={creature_location <- creature_locations(@selected_creature)}
                              class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                            >
                              <div>
                                <div class="text-sm font-medium text-zinc-800">
                                  {record_name(creature_location.location)}
                                </div>
                                <p class="text-xs text-zinc-500">
                                  {display_value(creature_location.presence)}
                                </p>
                              </div>
                              <button
                                type="button"
                                phx-click="delete_creature_location"
                                phx-value-id={creature_location.id}
                                data-confirm={"Remove #{record_name(creature_location.location)}?"}
                                class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label="Delete creature location"
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create and place custom creatures.</p>
                    </div>

                    <div id="bestiary-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="creature_type"
                        expanded_action={@expanded_action}
                        icon="hero-tag"
                        title="Add Creature Type"
                      >
                        <.form
                          for={@creature_type_form}
                          id="creature-type-form"
                          phx-submit="create_creature_type"
                          class="space-y-2"
                        >
                          <.input
                            field={@creature_type_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input
                            field={@creature_type_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        action="creature"
                        expanded_action={@expanded_action}
                        icon="hero-bug-ant"
                        title="Add Creature"
                      >
                        <.form
                          for={@creature_form}
                          id="creature-form"
                          phx-submit="create_creature"
                          class="space-y-2"
                        >
                          <.input
                            field={@creature_form[:creature_type_id]}
                            type="select"
                            label="Type"
                            prompt="None"
                            options={@creature_type_options}
                          />
                          <.input field={@creature_form[:name]} type="text" label="Name" required />
                          <.input field={@creature_form[:habitat]} type="text" label="Habitat" />
                          <.input
                            field={@creature_form[:temperament]}
                            type="text"
                            label="Temperament"
                          />
                          <.input
                            field={@creature_form[:danger_level]}
                            type="text"
                            label="Danger"
                          />
                          <.input
                            field={@creature_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_creature}
                        action="creature_edit"
                        expanded_action={@expanded_action}
                        icon="hero-pencil-square"
                        title="Edit Creature"
                      >
                        <.form
                          for={@creature_edit_form}
                          id="creature-edit-form"
                          phx-submit="update_creature"
                          class="space-y-2"
                        >
                          <.input
                            field={@creature_edit_form[:creature_type_id]}
                            type="select"
                            label="Type"
                            prompt="None"
                            options={@creature_type_options}
                          />
                          <.input
                            field={@creature_edit_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input field={@creature_edit_form[:habitat]} type="text" label="Habitat" />
                          <.input
                            field={@creature_edit_form[:temperament]}
                            type="text"
                            label="Temperament"
                          />
                          <.input
                            field={@creature_edit_form[:danger_level]}
                            type="text"
                            label="Danger"
                          />
                          <.input
                            field={@creature_edit_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Save
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@creature_options != [] && @all_location_options != []}
                        action="creature_location"
                        expanded_action={@expanded_action}
                        icon="hero-map-pin"
                        title="Add Location Link"
                      >
                        <.form
                          for={@creature_location_form}
                          id="creature-location-form"
                          phx-submit="create_creature_location"
                          class="space-y-2"
                        >
                          <.input
                            field={@creature_location_form[:creature_id]}
                            type="select"
                            label="Creature"
                            options={@creature_options}
                          />
                          <.input
                            field={@creature_location_form[:location_id]}
                            type="select"
                            label="Location"
                            options={@all_location_options}
                          />
                          <.input
                            field={@creature_location_form[:presence]}
                            type="text"
                            label="Presence"
                          />
                          <.input
                            field={@creature_location_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "calendar" -> %>
                <div
                  id="calendar-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Calendar</h2>
                        <p class="text-xs text-zinc-500">Continent-level calendars and months</p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@calendars)}
                      </span>
                    </div>

                    <div id="calendar-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div
                        :if={@calendars == []}
                        class="px-4 py-8 text-center text-sm text-zinc-500"
                      >
                        No calendars have been added to this world.
                      </div>

                      <div
                        :for={calendar <- @calendars}
                        class={[
                          "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                          @selected_calendar && @selected_calendar.id == calendar.id &&
                            "bg-zinc-100"
                        ]}
                      >
                        <.link
                          patch={
                            ~p"/worlds/#{@world}/dashboard?section=calendar&calendar_id=#{calendar.id}"
                          }
                          class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                        >
                          <div class="truncate text-sm font-semibold text-zinc-800">
                            {calendar.name}
                          </div>
                          <p class="mt-1 text-xs font-medium text-zinc-500">
                            {display_value(calendar.era)}
                          </p>
                        </.link>
                        <button
                          type="button"
                          phx-click="delete_calendar"
                          phx-value-id={calendar.id}
                          data-confirm={"Delete #{calendar.name}?"}
                          class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                          aria-label={"Delete #{calendar.name}"}
                        >
                          <.icon name="hero-trash" class="size-4" />
                        </button>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Details</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_calendar,
                            do: @selected_calendar.name,
                            else: "No calendar selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_calendar)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select a calendar to inspect months and structure.
                      </div>

                      <div :if={@selected_calendar} id="calendar-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">
                            {@selected_calendar.name}
                          </h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_calendar.description || "No description yet."}
                          </p>
                        </div>

                        <div class="grid gap-3 text-sm sm:grid-cols-2">
                          <.detail
                            label="Days Per Week"
                            value={to_string(@selected_calendar.days_per_week)}
                          />
                          <.detail label="Era" value={display_value(@selected_calendar.era)} />
                        </div>

                        <div class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2">
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">Months</p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :if={calendar_months(@selected_calendar) == []}
                              class="py-2 text-sm text-zinc-500"
                            >
                              No months have been added.
                            </div>
                            <div
                              :for={month <- calendar_months(@selected_calendar)}
                              class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                            >
                              <div>
                                <div class="text-sm font-medium text-zinc-800">
                                  {month.position}. {month.name}
                                </div>
                                <p class="text-xs text-zinc-500">{month.days} days</p>
                              </div>
                              <button
                                type="button"
                                phx-click="delete_calendar_month"
                                phx-value-id={month.id}
                                data-confirm={"Delete #{month.name}?"}
                                class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{month.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create and edit calendars.</p>
                    </div>

                    <div id="calendar-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="calendar"
                        expanded_action={@expanded_action}
                        icon="hero-calendar-days"
                        title="Add Calendar"
                      >
                        <.form
                          for={@calendar_form}
                          id="calendar-form"
                          phx-submit="create_calendar"
                          class="space-y-2"
                        >
                          <.input
                            field={@calendar_form[:continent_id]}
                            type="select"
                            label="Continent"
                            options={@continent_options}
                          />
                          <.input field={@calendar_form[:name]} type="text" label="Name" required />
                          <.input
                            field={@calendar_form[:days_per_week]}
                            type="number"
                            label="Days Per Week"
                          />
                          <.input field={@calendar_form[:era]} type="text" label="Era" />
                          <.input
                            field={@calendar_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_calendar}
                        action="calendar_edit"
                        expanded_action={@expanded_action}
                        icon="hero-pencil-square"
                        title="Edit Calendar"
                      >
                        <.form
                          for={@calendar_edit_form}
                          id="calendar-edit-form"
                          phx-submit="update_calendar"
                          class="space-y-2"
                        >
                          <.input
                            field={@calendar_edit_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input
                            field={@calendar_edit_form[:days_per_week]}
                            type="number"
                            label="Days Per Week"
                          />
                          <.input field={@calendar_edit_form[:era]} type="text" label="Era" />
                          <.input
                            field={@calendar_edit_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Save
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_calendar}
                        action="calendar_month"
                        expanded_action={@expanded_action}
                        icon="hero-list-bullet"
                        title="Add Month"
                      >
                        <.form
                          for={@calendar_month_form}
                          id="calendar-month-form"
                          phx-submit="create_calendar_month"
                          class="space-y-2"
                        >
                          <.input
                            field={@calendar_month_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input field={@calendar_month_form[:days]} type="number" label="Days" />
                          <.input
                            field={@calendar_month_form[:position]}
                            type="number"
                            label="Position"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
              <% @section == "timeline" -> %>
                <div
                  id="timeline-dashboard"
                  class="grid min-h-[700px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_340px]"
                >
                  <section class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Timelines</h2>
                        <p class="text-xs text-zinc-500">Historical era systems for this world</p>
                      </div>
                      <span class="rounded border border-zinc-200 bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600">
                        {length(@timelines)}
                      </span>
                    </div>

                    <div id="timeline-list" class="max-h-[720px] space-y-1.5 overflow-y-auto p-1.5">
                      <div
                        :if={@timelines == []}
                        class="px-4 py-8 text-center text-sm text-zinc-500"
                      >
                        No timelines have been added to this world.
                      </div>

                      <div
                        :for={timeline <- @timelines}
                        class={[
                          "grid grid-cols-[minmax(0,1fr)_44px] items-stretch overflow-hidden rounded-md stone-record-card border",
                          @selected_timeline && @selected_timeline.id == timeline.id &&
                            "bg-zinc-100"
                        ]}
                      >
                        <.link
                          patch={
                            ~p"/worlds/#{@world}/dashboard?section=timeline&timeline_id=#{timeline.id}"
                          }
                          class="block min-w-0 px-3 py-2 transition hover:bg-zinc-50"
                        >
                          <div class="truncate text-sm font-semibold text-zinc-800">
                            {timeline.name}
                          </div>
                          <p class="mt-1 text-xs font-medium text-zinc-500">
                            {length(timeline_eras(timeline))} eras
                          </p>
                        </.link>
                        <button
                          type="button"
                          phx-click="delete_timeline"
                          phx-value-id={timeline.id}
                          data-confirm={"Delete #{timeline.name}?"}
                          class="stone-muted inline-flex shrink-0 items-center justify-center border-l border-zinc-100 transition hover:bg-zinc-100 hover:text-zinc-700"
                          aria-label={"Delete #{timeline.name}"}
                        >
                          <.icon name="hero-trash" class="size-4" />
                        </button>
                      </div>
                    </div>
                  </section>

                  <main class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-3">
                      <div>
                        <h2 class="text-sm font-semibold text-zinc-800">Eras</h2>
                        <p class="text-xs text-zinc-500">
                          {if @selected_timeline,
                            do: @selected_timeline.name,
                            else: "No timeline selected"}
                        </p>
                      </div>
                    </div>

                    <div class="max-h-[720px] overflow-y-auto p-4">
                      <div
                        :if={is_nil(@selected_timeline)}
                        class="py-8 text-center text-sm text-zinc-500"
                      >
                        Select a timeline to inspect its eras.
                      </div>

                      <div :if={@selected_timeline} id="timeline-details" class="space-y-4">
                        <div>
                          <h3 class="text-lg font-semibold text-zinc-800">
                            {@selected_timeline.name}
                          </h3>
                          <p class="mt-1 text-sm leading-6 text-zinc-600">
                            {@selected_timeline.description || "No description yet."}
                          </p>
                        </div>

                        <div class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2">
                          <p class="text-[11px] font-semibold uppercase text-zinc-500">Eras</p>
                          <div class="mt-2 flex flex-col divide-y divide-zinc-100">
                            <div
                              :if={timeline_eras(@selected_timeline) == []}
                              class="py-2 text-sm text-zinc-500"
                            >
                              No eras have been added.
                            </div>
                            <div
                              :for={era <- timeline_eras(@selected_timeline)}
                              class="grid grid-cols-[minmax(0,1fr)_44px] items-center gap-2 py-2 first:pt-0 last:pb-0"
                            >
                              <div>
                                <div class="text-sm font-medium text-zinc-800">
                                  {era.position}. {era.name}
                                </div>
                                <p class="text-xs text-zinc-500">
                                  {era_years(era)}
                                </p>
                              </div>
                              <button
                                type="button"
                                phx-click="delete_timeline_era"
                                phx-value-id={era.id}
                                data-confirm={"Delete #{era.name}?"}
                                class="stone-muted inline-flex size-8 items-center justify-center rounded border border-zinc-200 transition hover:bg-zinc-100 hover:text-zinc-700"
                                aria-label={"Delete #{era.name}"}
                              >
                                <.icon name="hero-trash" class="size-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </main>

                  <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white">
                    <div class="rounded-md border border-zinc-200 bg-white px-4 py-3">
                      <h2 class="text-sm font-semibold text-zinc-800">Actions</h2>
                      <p class="mt-1 text-xs text-zinc-500">Create timelines and eras.</p>
                    </div>

                    <div id="timeline-action-list" class="max-h-[720px] overflow-y-auto">
                      <.action_section
                        action="timeline"
                        expanded_action={@expanded_action}
                        icon="hero-clock"
                        title="Add Timeline"
                      >
                        <.form
                          for={@timeline_form}
                          id="timeline-form"
                          phx-submit="create_timeline"
                          class="space-y-2"
                        >
                          <.input field={@timeline_form[:name]} type="text" label="Name" required />
                          <.input
                            field={@timeline_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>

                      <.action_section
                        :if={@selected_timeline}
                        action="timeline_era"
                        expanded_action={@expanded_action}
                        icon="hero-book-open"
                        title="Add Era"
                      >
                        <.form
                          for={@timeline_era_form}
                          id="timeline-era-form"
                          phx-submit="create_timeline_era"
                          class="space-y-2"
                        >
                          <.input
                            field={@timeline_era_form[:timeline_id]}
                            type="select"
                            label="Timeline"
                            options={@timeline_options}
                          />
                          <.input
                            field={@timeline_era_form[:name]}
                            type="text"
                            label="Name"
                            required
                          />
                          <.input
                            field={@timeline_era_form[:abbreviation]}
                            type="text"
                            label="Abbreviation"
                          />
                          <.input
                            field={@timeline_era_form[:position]}
                            type="number"
                            label="Position"
                          />
                          <.input
                            field={@timeline_era_form[:starts_at_year]}
                            type="number"
                            label="Starts At Year"
                          />
                          <.input
                            field={@timeline_era_form[:ends_at_year]}
                            type="number"
                            label="Ends At Year"
                          />
                          <.input
                            field={@timeline_era_form[:description]}
                            type="textarea"
                            label="Description"
                          />
                          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                            Create
                          </.button>
                        </.form>
                      </.action_section>
                    </div>
                  </aside>
                </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("create_continent", %{"continent" => params}, socket) do
    create_and_reload(socket, fn -> Worlds.create_continent(socket.assigns.world, params) end)
  end

  def handle_event("create_province", %{"province" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, continent} <- get_continent_in_world(socket, params["continent_id"]) do
        Worlds.create_province(continent, params)
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
    create_and_reload(socket, fn -> Worlds.create_race(socket.assigns.world, params) end)
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

  def handle_event("create_character", %{"character" => params}, socket) do
    create_and_reload(socket, fn ->
      with {:ok, race} <- get_optional_race_in_world(socket, params["race_id"]),
           {:ok, guild} <- get_optional_guild_in_world(socket, params["guild_id"]),
           {:ok, occupation} <- get_optional_occupation_in_world(socket, params["occupation_id"]),
           {:ok, skill} <- get_optional_skill_in_world(socket, params["skill_id"]),
           {:ok, home_location} <-
             get_optional_location_in_world(socket, params["home_location_id"]) do
        Worlds.create_character(socket.assigns.world, params,
          race: race,
          guild: guild,
          occupation: occupation,
          skill: skill,
          home_location: home_location
        )
      end
    end)
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
     )}
  end

  def handle_event("set_skill_detail_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :skill_detail_tab, normalize_skill_detail_tab(tab))}
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

  defp assign_dashboard(socket, world_id, params) do
    world = Worlds.get_world_dashboard!(world_id)
    section = normalize_section(params["section"])
    expanded_action = selected_expanded_action(socket, section)
    continents = sorted(world.continents)
    civilizations = sorted(world.civilizations)
    provinces = flat_provinces(continents)
    holds = flat_holds(provinces)
    locations = flat_locations(holds)
    calendars = flat_calendars(continents)
    characters = sorted(world.characters)
    creature_types = sorted(world.creature_types)
    creatures = sorted(world.creatures)
    creature_locations = flat_creature_locations(creatures)
    effects = sorted(world.effects)
    gods = sorted(world.gods)
    guilds = sorted(world.guilds)
    items = sorted(world.items)
    location_types = sorted(world.location_types)
    occupations = sorted(world.occupations)
    political_offices = world.political_offices
    races = sorted(world.races)
    skills = sorted(world.skills)
    spells = sorted(world.spells)
    timelines = sorted(world.timelines)
    timeline_eras = flat_timeline_eras(timelines)
    selected_calendar = select_record(calendars, params["calendar_id"]) || first_record(calendars)

    selected_character =
      select_record(characters, params["character_id"]) || first_record(characters)

    selected_character_inventory_categories =
      character_inventory_categories(selected_character)

    selected_character_inventory_items =
      character_inventory_items(selected_character)

    selected_creature = select_record(creatures, params["creature_id"]) || first_record(creatures)
    selected_god = select_record(gods, params["god_id"]) || first_record(gods)
    selected_guild = select_record(guilds, params["guild_id"]) || first_record(guilds)
    selected_item = select_record(items, params["item_id"]) || first_record(items)
    selected_item_effects = item_effects(selected_item)
    selected_race = select_record(races, params["race_id"]) || first_record(races)
    selected_skill = select_record(skills, params["skill_id"]) || first_record(skills)
    skill_detail_tab = selected_skill_detail_tab(socket)
    selected_spell = select_record(spells, params["spell_id"]) || first_record(spells)
    selected_timeline = select_record(timelines, params["timeline_id"]) || first_record(timelines)
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
      selected_province_political_offices ++ selected_hold_political_offices

    selected_political_office =
      select_record(selected_political_offices, params["political_office_id"]) ||
        first_record(selected_political_offices)

    selected_continent_id = selected_or_first_id(selected_path.continent, continents)
    selected_province_id = selected_or_first_id(selected_path.province, provinces)
    selected_hold_options = option_list(List.wrap(selected_hold))

    socket
    |> assign(:world, world)
    |> assign(:page_title, world.name)
    |> assign(:section, section)
    |> assign(:expanded_action, expanded_action)
    |> assign(:calendars, calendars)
    |> assign(:selected_calendar, selected_calendar)
    |> assign(:characters, characters)
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
    |> assign(:skills, skills)
    |> assign(:selected_skill, selected_skill)
    |> assign(:skill_detail_tab, skill_detail_tab)
    |> assign(:spells, spells)
    |> assign(:selected_spell, selected_spell)
    |> assign(:timelines, timelines)
    |> assign(:timeline_eras, timeline_eras)
    |> assign(:selected_timeline, selected_timeline)
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
    |> assign(
      :character_inventory_category_options,
      option_list(selected_character_inventory_categories)
    )
    |> assign(:civilization_options, option_list(civilizations))
    |> assign(:creature_type_options, option_list(creature_types))
    |> assign(:creature_options, option_list(creatures))
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
    |> assign(:skill_options, option_list(skills))
    |> assign(:spell_options, option_list(spells))
    |> assign(:timeline_options, option_list(timelines))
    |> assign(:timeline_era_options, option_list(timeline_eras))
    |> assign(:selected_hold_options, selected_hold_options)
    |> assign(:location_type_options, option_list(location_types))
    |> assign(:location_options, option_list(selected_hold_locations))
    |> assign(:continent_form, data_form(:continent))
    |> assign(:province_form, data_form(:province, %{"continent_id" => selected_continent_id}))
    |> assign(:hold_form, data_form(:hold, %{"province_id" => selected_province_id}))
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
        "currency" => "Septims",
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
    |> assign(:race_form, data_form(:race))
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
    |> assign(
      :character_form,
      data_form(:character, %{
        "race_id" => nil,
        "guild_id" => nil,
        "home_location_id" => nil,
        "occupation_id" => nil,
        "skill_id" => nil,
        "status" => "alive"
      })
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
  end

  defp reload_params(socket) do
    %{
      "section" => socket.assigns.section,
      "hold_id" => selected_hold_id(socket),
      "location_id" => selected_location_id(socket),
      "race_id" => selected_record_id(socket.assigns[:selected_race]),
      "guild_id" => selected_record_id(socket.assigns[:selected_guild]),
      "god_id" => selected_record_id(socket.assigns[:selected_god]),
      "character_id" => selected_record_id(socket.assigns[:selected_character]),
      "creature_id" => selected_record_id(socket.assigns[:selected_creature]),
      "item_id" => selected_record_id(socket.assigns[:selected_item]),
      "political_office_id" => selected_record_id(socket.assigns[:selected_political_office]),
      "skill_id" => selected_record_id(socket.assigns[:selected_skill]),
      "spell_id" => selected_record_id(socket.assigns[:selected_spell]),
      "civilization_id" => selected_record_id(socket.assigns[:selected_civilization]),
      "timeline_id" => selected_record_id(socket.assigns[:selected_timeline]),
      "calendar_id" => selected_record_id(socket.assigns[:selected_calendar])
    }
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

  defp get_optional_race_in_world(socket, race_id) do
    get_optional_record_in_options(socket.assigns.race_options, race_id, &Worlds.get_race!/1)
  end

  defp get_optional_guild_in_world(socket, guild_id) do
    get_optional_record_in_options(socket.assigns.guild_options, guild_id, &Worlds.get_guild!/1)
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
    |> Map.merge(%{"name" => "", "description" => ""}, fn _key, value, _default -> value end)
    |> to_form(as: name)
  end

  defp location_edit_attrs(nil, _selected_hold) do
    %{}
  end

  defp location_edit_attrs(location, selected_hold) do
    %{
      "name" => location.name,
      "description" => location.description,
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
      "era" => calendar.era
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
      {"Weapons", "weapon"},
      {"Apparel", "apparel"},
      {"Food", "food"},
      {"Ingredients", "ingredient"},
      {"Potions", "potion"},
      {"Poisons", "poison"},
      {"Books", "book"},
      {"Scrolls", "scroll"},
      {"Keys", "key"},
      {"Tools", "tool"},
      {"Crafting Materials", "crafting_material"},
      {"Misc", "misc"}
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
    |> Enum.group_by(&record_name(&1.race))
    |> Enum.sort_by(fn {race, _race_characters} -> race end)
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
    Enum.map(records, &{&1.name, &1.id})
  end

  defp political_office_options(records) do
    Enum.map(records, fn political_office ->
      {political_office_label(political_office), political_office.id}
    end)
  end

  defp political_office_label(%{scope: "province"} = political_office) do
    "#{political_office.office} / #{record_name(political_office.province)}"
  end

  defp political_office_label(%{scope: "hold"} = political_office) do
    "#{political_office.office} / #{record_name(political_office.hold)}"
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
       when section in ~w(bestiary calendar characters civilizations geography gods guilds items races skills spells timeline) do
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

  defp section_label("calendar") do
    "Calendar"
  end

  defp section_label("timeline") do
    "Timeline"
  end

  defp section_label(_section) do
    "Geography"
  end

  defp selected_expanded_action(socket, section) do
    case socket.assigns[:section] do
      ^section ->
        socket.assigns[:expanded_action]

      _previous_section ->
        default_expanded_action(section)
    end
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

  defp race_traits(race, category) do
    race.traits
    |> Enum.filter(&(&1.category == category))
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

  defp sorted(records) do
    Enum.sort_by(records, & &1.name)
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

  defp child_locations(location, locations) do
    Enum.filter(locations, &(&1.parent_location_id == location.id))
  end

  defp normalize_theme(theme) when theme in ~w(system light dark) do
    theme
  end

  defp normalize_theme(_theme) do
    "light"
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

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp detail(assigns) do
    ~H"""
    <div class="stone-panel-muted rounded-md border px-3 py-2">
      <p class="stone-muted text-[11px] font-semibold uppercase">{@label}</p>
      <p class="stone-heading mt-1 text-sm font-medium">{@value}</p>
    </div>
    """
  end
end
