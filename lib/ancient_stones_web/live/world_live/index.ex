defmodule AncientStonesWeb.WorldLive.Index do
  use AncientStonesWeb, :live_view

  alias AncientStones.Galaxies
  alias AncientStones.Maps
  alias AncientStones.Templates
  alias AncientStones.Worlds
  alias AncientStonesWeb.WorldLive.WorldFormComponents

  def mount(_params, _session, socket) do
    galaxies = Galaxies.list_galaxies()

    {:ok,
     socket
     |> assign(:page_title, "Worlds")
     |> assign(:theme, "system")
     |> assign(:library_tab, "galaxies")
     |> assign_index_records(galaxies)
     |> assign(:galaxy_options, option_list(galaxies))
     |> assign(:current_template, "blank")
     |> assign(:selected_world, nil)
     |> assign(:selected_galaxy, nil)
     |> assign(:world_form, world_form(galaxies))
     |> assign(:galaxy_form, galaxy_form())
     |> stream(:galaxies, galaxies)
     |> stream(:worlds, Worlds.list_worlds_without_galaxy())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        class={["stone-page min-h-screen px-4 py-5", "stone-theme-#{@theme}"]}
        data-theme={daisy_theme(@theme)}
        id="worlds-dashboard"
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
                navigate={~p"/worlds"}
                class="stone-selected flex items-center justify-between gap-2 rounded-md border px-3 py-2 font-medium"
              >
                <span class="flex items-center gap-2">
                  <.icon name="hero-globe-alt" class="size-4" /> Worlds / Planets
                </span>
                <strong class="text-xs font-semibold">{@inventory.worlds}</strong>
              </.link>
              <.link
                id="maps-navigation"
                navigate={~p"/maps"}
                class="stone-button mt-1 flex items-center justify-between gap-2 rounded-md border px-3 py-2 font-medium"
              >
                <span class="flex items-center gap-2">
                  <.icon name="hero-map" class="size-4" /> Maps
                </span>
                <strong class="text-xs font-semibold">{@inventory.maps}</strong>
              </.link>
              <span class="stone-muted mt-1 flex items-center justify-between gap-2 rounded-md px-3 py-2">
                <span class="flex items-center gap-2">
                  <.icon name="hero-sparkles" class="size-4" /> Galaxies
                </span>
                <strong class="text-xs font-semibold">{@inventory.galaxies}</strong>
              </span>
            </nav>
          </aside>

          <div class="stone-workspace min-w-0">
            <header class="stone-topbar flex h-16 items-center justify-between border-b px-5">
              <div>
                <h2 class="stone-heading text-sm font-semibold">Worlds</h2>
                <p class="stone-muted text-xs">Create galaxies and world-sized planets.</p>
              </div>
              <.theme_switcher theme={@theme} />
            </header>

            <main class="grid min-h-[800px] gap-4 p-4 xl:grid-cols-[minmax(0,1fr)_380px]">
              <section class="grid content-start gap-4">
                <div class="stone-panel flex flex-col overflow-hidden rounded-md border">
                  <.panel_header
                    title="Library"
                    subtitle="Browse galaxy containers and worlds without a galaxy."
                    count={@inventory.worlds}
                  />

                  <div
                    id="world-library-tabs"
                    class="stone-border flex flex-wrap items-center gap-2 border-b px-3 py-2"
                    role="tablist"
                    aria-label="World library"
                  >
                    <button
                      id="galaxies-tab"
                      type="button"
                      phx-click="set_library_tab"
                      phx-value-tab="galaxies"
                      role="tab"
                      aria-controls="galaxies-panel"
                      aria-selected={@library_tab == "galaxies"}
                      class={[
                        "inline-flex h-8 items-center gap-2 rounded-md border px-3 text-xs font-medium transition",
                        @library_tab == "galaxies" && "stone-selected",
                        @library_tab != "galaxies" && "stone-button"
                      ]}
                    >
                      <.icon name="hero-sparkles" class="size-3.5" /> Galaxies
                      <span class="stone-muted text-[11px] font-semibold">
                        {@inventory.galaxies}
                      </span>
                    </button>

                    <button
                      id="unassigned-worlds-tab"
                      type="button"
                      phx-click="set_library_tab"
                      phx-value-tab="unassigned_worlds"
                      role="tab"
                      aria-controls="unassigned-worlds-panel"
                      aria-selected={@library_tab == "unassigned_worlds"}
                      class={[
                        "inline-flex h-8 items-center gap-2 rounded-md border px-3 text-xs font-medium transition",
                        @library_tab == "unassigned_worlds" && "stone-selected",
                        @library_tab != "unassigned_worlds" && "stone-button"
                      ]}
                    >
                      <.icon name="hero-globe-alt" class="size-3.5" /> Unassigned Worlds
                      <span class="stone-muted text-[11px] font-semibold">
                        {@unassigned_world_count}
                      </span>
                    </button>
                  </div>

                  <div
                    id="galaxies-panel"
                    role="tabpanel"
                    aria-labelledby="galaxies-tab"
                    class={[@library_tab != "galaxies" && "hidden"]}
                  >
                    <div
                      id="galaxies"
                      phx-update="stream"
                      class="grid max-h-[760px] gap-2 overflow-auto p-3"
                    >
                      <.empty_stream_state
                        id="galaxies-empty"
                        message="No galaxies yet."
                        class="py-7"
                      />
                      <div
                        :for={{id, galaxy} <- @streams.galaxies}
                        id={id}
                        class="stone-record-card rounded-md border p-3"
                      >
                        <div class="flex items-start justify-between gap-3">
                          <button
                            id={"select-galaxy-#{galaxy.id}"}
                            type="button"
                            phx-click="select_galaxy"
                            phx-value-id={galaxy.id}
                            class="min-w-0 flex-1 rounded-md text-left transition hover:opacity-80 focus-visible:outline-2 focus-visible:outline-offset-2"
                            aria-label={"Edit #{galaxy.name}"}
                          >
                            <div class="flex items-center gap-2">
                              <span class="stone-panel-muted inline-flex size-7 items-center justify-center rounded-md border">
                                <.icon name="hero-sparkles" class="size-4" />
                              </span>
                              <h4 class="stone-heading truncate text-sm font-semibold">
                                {galaxy.name}
                              </h4>
                            </div>
                            <p class="stone-muted mt-2 line-clamp-2 text-sm">
                              {galaxy.description || "No description yet."}
                            </p>
                          </button>
                          <.danger_icon_button
                            phx-click="delete_galaxy"
                            phx-value-id={galaxy.id}
                            data-confirm={"Delete #{galaxy.name}?"}
                            label={"Delete #{galaxy.name}"}
                          />
                        </div>
                        <div class="stone-border mt-3 flex items-center justify-between border-t pt-3 text-xs">
                          <span class="stone-muted flex items-center gap-1.5">
                            <.icon name="hero-globe-alt" class="size-3.5" /> World children
                          </span>
                          <strong class="stone-heading font-semibold">{world_count(galaxy)}</strong>
                        </div>
                        <div
                          :if={world_count(galaxy) > 0}
                          class="stone-border mt-3 grid gap-2 border-t pt-3"
                        >
                          <div
                            :for={world <- sorted_worlds(galaxy.worlds)}
                            class="stone-child-record rounded-md border px-3 py-2"
                          >
                            <div class="flex items-start justify-between gap-3">
                              <button
                                id={"select-world-#{world.id}"}
                                type="button"
                                phx-click="select_world"
                                phx-value-id={world.id}
                                class="min-w-0 flex-1 rounded-md text-left focus-visible:outline-2 focus-visible:outline-offset-2"
                                aria-label={"Edit #{world.name}"}
                              >
                                <div class="stone-heading truncate text-sm font-medium">
                                  {world.name}
                                </div>
                                <p class="stone-muted mt-1 line-clamp-2 text-xs leading-5">
                                  {world.description || "No description yet."}
                                </p>
                                <.world_geography_stats counts={world_counts(@world_counts, world)} />
                              </button>
                              <div class="flex shrink-0 items-center gap-1.5">
                                <.danger_icon_button
                                  phx-click="delete_world"
                                  phx-value-id={world.id}
                                  data-confirm={"Delete #{world.name} and its geography?"}
                                  label={"Delete #{world.name}"}
                                  class="size-7"
                                />
                                <.link
                                  navigate={~p"/worlds/#{world}/dashboard"}
                                  class="stone-button inline-flex size-7 items-center justify-center rounded-md border transition"
                                  aria-label={"Open #{world.name}"}
                                  title={"Open #{world.name}"}
                                >
                                  <.icon name="hero-arrow-right" class="size-3.5" />
                                </.link>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div
                    id="unassigned-worlds-panel"
                    role="tabpanel"
                    aria-labelledby="unassigned-worlds-tab"
                    class={[@library_tab != "unassigned_worlds" && "hidden"]}
                  >
                    <div
                      id="worlds"
                      phx-update="stream"
                      class="grid max-h-[760px] gap-2 overflow-auto p-3"
                    >
                      <.empty_stream_state
                        id="worlds-empty"
                        message="No unassigned worlds."
                        class="py-7"
                      />
                      <div
                        :for={{id, world} <- @streams.worlds}
                        id={id}
                        class="stone-record-card rounded-md border p-3"
                      >
                        <div class="grid gap-3 md:grid-cols-[minmax(0,1fr)_auto]">
                          <button
                            id={"select-world-#{world.id}"}
                            type="button"
                            phx-click="select_world"
                            phx-value-id={world.id}
                            class="min-w-0 rounded-md text-left transition hover:opacity-80 focus-visible:outline-2 focus-visible:outline-offset-2"
                            aria-label={"Edit #{world.name}"}
                          >
                            <div class="flex flex-wrap items-center gap-2">
                              <h4 class="stone-heading truncate text-sm font-semibold">
                                {world.name}
                              </h4>
                              <span class="stone-panel-muted stone-muted inline-flex items-center gap-1 rounded border px-2 py-0.5 text-xs">
                                <.icon name="hero-sparkles" class="size-3" /> No galaxy
                              </span>
                            </div>
                            <p class="stone-muted mt-2 line-clamp-2 text-sm">
                              {world.description || "No description yet."}
                            </p>
                            <.world_geography_stats counts={world_counts(@world_counts, world)} />
                          </button>
                          <div class="flex items-start justify-end gap-2">
                            <.danger_icon_button
                              phx-click="delete_world"
                              phx-value-id={world.id}
                              data-confirm={"Delete #{world.name} and its geography?"}
                              label={"Delete #{world.name}"}
                            />
                            <.link
                              navigate={~p"/worlds/#{world}/dashboard"}
                              class="stone-button inline-flex h-8 items-center gap-1 rounded-md border px-2.5 text-xs font-medium transition"
                            >
                              Open <.icon name="hero-arrow-right" class="size-3.5" />
                            </.link>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </section>

              <aside class="grid content-start gap-4">
                <div class="stone-panel overflow-hidden rounded-md border">
                  <div class="stone-border border-b px-4 py-3">
                    <div class="stone-muted text-[11px] font-semibold uppercase tracking-wide">
                      Galaxy
                    </div>
                    <h3 class="stone-heading mt-1 text-sm font-semibold">
                      {if(@selected_galaxy, do: "Edit Galaxy", else: "Create Galaxy")}
                    </h3>
                    <p class="stone-muted mt-1 text-xs">
                      {if(@selected_galaxy,
                        do: "Update the selected galaxy details.",
                        else: "Use this first when the world belongs to a known cosmos."
                      )}
                    </p>
                  </div>

                  <.form
                    for={@galaxy_form}
                    id="dashboard-galaxy-form"
                    phx-submit={if(@selected_galaxy, do: "update_galaxy", else: "create_galaxy")}
                    class="space-y-3 p-4"
                  >
                    <.input field={@galaxy_form[:name]} type="text" label="Name" required />
                    <.input
                      field={@galaxy_form[:description]}
                      type="textarea"
                      label="Description"
                      rows="3"
                    />
                    <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition">
                      <span class="inline-flex items-center justify-center gap-2">
                        <%= if @selected_galaxy do %>
                          <.icon name="hero-check" class="size-4" /> Save
                        <% else %>
                          <.icon name="hero-plus" class="size-4" /> Create galaxy
                        <% end %>
                      </span>
                    </.button>
                    <button
                      :if={@selected_galaxy}
                      id="cancel-galaxy-edit"
                      type="button"
                      phx-click="clear_galaxy_selection"
                      class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition"
                    >
                      Cancel
                    </button>
                  </.form>
                </div>

                <div class="stone-panel overflow-hidden rounded-md border">
                  <div class="stone-border border-b px-4 py-3">
                    <div class="stone-muted text-[11px] font-semibold uppercase tracking-wide">
                      World
                    </div>
                    <h3 class="stone-heading mt-1 text-sm font-semibold">
                      {if(@selected_world, do: "Edit World", else: "Create World")}
                    </h3>
                    <p class="stone-muted mt-1 text-xs">
                      {if(@selected_world,
                        do: "Update the selected world details.",
                        else: "A world is the planet record. Templates can fill starter geography."
                      )}
                    </p>
                  </div>

                  <.form
                    for={@world_form}
                    id="dashboard-world-form"
                    phx-change={if(is_nil(@selected_world), do: "change_template")}
                    phx-submit={if(@selected_world, do: "update_world", else: "create_world")}
                    class="space-y-3 p-4"
                  >
                    <div :if={is_nil(@selected_world)} class="space-y-3">
                      <.input
                        field={@world_form[:template]}
                        type="select"
                        label="Template"
                        options={Templates.options()}
                      />
                      <.input field={@world_form[:template_galaxy]} type="hidden" />
                    </div>
                    <.input
                      field={@world_form[:galaxy_id]}
                      type="select"
                      label="Galaxy"
                      prompt={
                        if(@world_form[:template_galaxy].value in [nil, ""], do: "None", else: nil)
                      }
                      options={world_galaxy_options(@world_form, @galaxy_options)}
                    />
                    <div class="stone-border border-t pt-3">
                      <.input field={@world_form[:name]} type="text" label="Name" required />
                    </div>
                    <div class="space-y-3">
                      <.input
                        field={@world_form[:description]}
                        type="textarea"
                        label="Description"
                        rows="5"
                      />
                      <div class="grid gap-3 sm:grid-cols-3">
                        <.input
                          field={@world_form[:primary_star_name]}
                          type="text"
                          label="Star"
                          tooltip="Primary star or sun the world orbits."
                        />
                        <.input
                          field={@world_form[:orbital_period_days]}
                          type="number"
                          label="Orbit Days"
                          tooltip="Number of days in one full orbit around the primary star."
                        />
                        <.input
                          field={@world_form[:axial_tilt_degrees]}
                          type="number"
                          label="Axial Tilt"
                          step="0.01"
                          tooltip="Planet tilt in degrees. Earth is about 23.5 degrees."
                        />
                      </div>
                      <div class="grid gap-3 sm:grid-cols-3">
                        <.input
                          field={@world_form[:day_length_hours]}
                          type="number"
                          label="Day Hours"
                          step="0.01"
                          tooltip="Number of hours in one full day."
                        />
                        <.input
                          field={@world_form[:mean_radius_km]}
                          type="number"
                          label="Radius (km)"
                          tooltip="Mean planetary radius in kilometres."
                        />
                        <.input
                          field={@world_form[:map_projection]}
                          type="text"
                          label="Map Projection"
                          tooltip="Projection used by the world's primary map."
                        />
                      </div>
                      <details
                        id="world-advanced-physical-data"
                        class="stone-border rounded-md border"
                      >
                        <summary class="stone-heading cursor-pointer px-3 py-2 text-sm font-semibold">
                          Advanced physical data
                        </summary>
                        <div class="stone-border grid gap-3 border-t p-3 sm:grid-cols-2">
                          <div class="grid gap-3">
                            <.input
                              field={@world_form[:mass_earths]}
                              type="number"
                              label="Mass (Earths)"
                              step="0.00001"
                              tooltip="Planetary mass relative to Earth; 1 equals Earth's mass."
                            />
                            <.input
                              field={@world_form[:surface_gravity_m_s2]}
                              type="number"
                              label="Gravity (m/s²)"
                              step="0.0001"
                              tooltip="Surface acceleration due to gravity in metres per second squared; Earth is about 9.81 m/s²."
                            />
                            <.input
                              field={@world_form[:atmospheric_pressure_atm]}
                              type="number"
                              label="Pressure (atm)"
                              step="0.0001"
                              tooltip="Mean surface pressure in standard atmospheres; 1 atm is 101.325 kPa."
                            />
                            <.input
                              field={@world_form[:ocean_fraction]}
                              type="number"
                              label="Ocean Fraction"
                              step="0.00001"
                              min="0"
                              max="1"
                              tooltip="Fraction of the planet's surface covered by oceans, from 0 to 1."
                            />
                            <.input
                              field={@world_form[:bond_albedo]}
                              type="number"
                              label="Bond Albedo"
                              step="0.00001"
                              min="0"
                              max="1"
                              tooltip="Fraction of incoming stellar energy reflected by the planet, from 0 to 1."
                            />
                          </div>
                          <div class="grid gap-3">
                            <.input
                              field={@world_form[:orbital_distance_au]}
                              type="number"
                              label="Orbit (AU)"
                              step="0.000001"
                              tooltip="Orbital semi-major axis in astronomical units; 1 AU is Earth's mean distance from the Sun."
                            />
                            <.input
                              field={@world_form[:orbital_eccentricity]}
                              type="number"
                              label="Eccentricity"
                              step="0.000001"
                              tooltip="Orbital shape: 0 is circular, while values below 1 describe bound elliptical orbits."
                            />
                            <.input
                              field={@world_form[:star_mass_solar]}
                              type="number"
                              label="Star Mass (Suns)"
                              step="0.00001"
                              tooltip="Primary star mass relative to the Sun; 1 equals one solar mass."
                            />
                            <.input
                              field={@world_form[:star_luminosity_solar]}
                              type="number"
                              label="Star Luminosity (Suns)"
                              step="0.00001"
                              tooltip="Primary star energy output relative to the Sun; 1 equals one solar luminosity."
                            />
                            <.input
                              field={@world_form[:star_temperature_k]}
                              type="number"
                              label="Star Temperature (K)"
                              tooltip="Primary star effective surface temperature in kelvins; the Sun is about 5,772 K."
                            />
                          </div>
                        </div>
                      </details>

                      <WorldFormComponents.moon_fields
                        :if={is_nil(@selected_world)}
                        form={@world_form}
                        id_prefix="dashboard-world-form"
                        add_event="add_world_moon"
                        remove_event="remove_world_moon"
                        map_form
                      />
                    </div>
                    <.button
                      id={
                        if(@selected_world,
                          do: "dashboard-update-world-button",
                          else: "dashboard-create-world-button"
                        )
                      }
                      class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition"
                    >
                      <span class="inline-flex items-center justify-center gap-2">
                        <%= if @selected_world do %>
                          <.icon name="hero-check" class="size-4" /> Save
                        <% else %>
                          <.icon name="hero-plus" class="size-4" /> Create world
                        <% end %>
                      </span>
                    </.button>
                    <button
                      :if={@selected_world}
                      id="cancel-world-edit"
                      type="button"
                      phx-click="clear_world_selection"
                      class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition"
                    >
                      Cancel
                    </button>
                  </.form>
                </div>
              </aside>
            </main>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("change_template", %{"world" => world_params}, socket) do
    template = Map.get(world_params, "template", "blank")

    form_params =
      if template == socket.assigns.current_template do
        world_params
      else
        defaults = Templates.defaults(template)

        galaxy_id =
          template_galaxy_selection(
            defaults[:galaxy],
            socket.assigns.galaxy_options,
            world_params["galaxy_id"]
          )

        %{
          "name" => defaults.name,
          "description" => defaults.description,
          "template" => template,
          "template_galaxy" => defaults[:galaxy],
          "galaxy_id" => galaxy_id || world_params["galaxy_id"]
        }
      end

    {:noreply,
     socket
     |> assign(:current_template, template)
     |> assign(:world_form, to_form(form_params, as: :world))}
  end

  def handle_event("add_world_moon", _params, socket) do
    params = WorldFormComponents.append_moon_params(socket.assigns.world_form.params || %{})

    {:noreply, assign(socket, :world_form, to_form(params, as: :world))}
  end

  def handle_event("remove_world_moon", %{"index" => index}, socket) do
    params =
      WorldFormComponents.remove_moon_params(socket.assigns.world_form.params || %{}, index)

    {:noreply, assign(socket, :world_form, to_form(params, as: :world))}
  end

  def handle_event("create_world", %{"world" => world_params}, socket) do
    template = Map.get(world_params, "template", "blank")
    attrs = Map.drop(world_params, ["template", "template_galaxy"])

    result =
      with {:ok, galaxy} <- get_optional_galaxy(socket, world_params["galaxy_id"]) do
        Worlds.create_world_from_template(template, attrs, galaxy: galaxy)
      end

    case result do
      {:ok, world} ->
        {:noreply,
         socket
         |> put_flash(:info, "World created")
         |> push_navigate(to: ~p"/worlds/#{world}/dashboard")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "World could not be created")}
    end
  end

  def handle_event("create_galaxy", %{"galaxy" => galaxy_params}, socket) do
    case Galaxies.create_galaxy(galaxy_params) do
      {:ok, _galaxy} ->
        galaxies = Galaxies.list_galaxies()

        {:noreply,
         socket
         |> put_flash(:info, "Galaxy created")
         |> assign_index_records(galaxies)
         |> assign(:galaxy_options, option_list(galaxies))
         |> assign(:world_form, world_form(galaxies))
         |> assign(:galaxy_form, galaxy_form())
         |> stream(:galaxies, galaxies, reset: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Galaxy could not be created")}
    end
  end

  def handle_event("delete_world", %{"id" => id}, socket) do
    world = Worlds.get_world!(id)

    case Worlds.delete_world(world) do
      {:ok, _deleted_world} ->
        galaxies = Galaxies.list_galaxies()
        unassigned_worlds = Worlds.list_worlds_without_galaxy()

        {:noreply,
         socket
         |> put_flash(:info, "World deleted")
         |> assign_index_records(galaxies, unassigned_worlds)
         |> stream(:galaxies, galaxies, reset: true)
         |> stream(:worlds, unassigned_worlds, reset: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "World could not be deleted")}
    end
  end

  def handle_event("delete_galaxy", %{"id" => id}, socket) do
    galaxy = Galaxies.get_galaxy!(id)

    case Galaxies.delete_galaxy(galaxy) do
      {:ok, _deleted_galaxy} ->
        galaxies = Galaxies.list_galaxies()
        unassigned_worlds = Worlds.list_worlds_without_galaxy()

        {:noreply,
         socket
         |> put_flash(:info, "Galaxy deleted")
         |> assign_index_records(galaxies, unassigned_worlds)
         |> assign(:galaxy_options, option_list(galaxies))
         |> assign(:world_form, world_form(galaxies))
         |> stream(:galaxies, galaxies, reset: true)
         |> stream(:worlds, unassigned_worlds, reset: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Galaxy could not be deleted")}
    end
  end

  def handle_event("select_world", %{"id" => id}, socket) do
    world = Worlds.get_world!(id)

    {:noreply,
     socket
     |> assign(:selected_world, world)
     |> assign(:world_form, selected_world_form(world))}
  end

  def handle_event("clear_world_selection", _params, socket) do
    galaxies = Galaxies.list_galaxies()

    {:noreply,
     socket
     |> assign(:current_template, "blank")
     |> assign(:selected_world, nil)
     |> assign(:world_form, world_form(galaxies))}
  end

  def handle_event("select_galaxy", %{"id" => id}, socket) do
    galaxy = Galaxies.get_galaxy!(id)

    {:noreply,
     socket
     |> assign(:selected_galaxy, galaxy)
     |> assign(:galaxy_form, selected_galaxy_form(galaxy))}
  end

  def handle_event("clear_galaxy_selection", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_galaxy, nil)
     |> assign(:galaxy_form, galaxy_form())}
  end

  def handle_event("update_world", %{"world" => params}, socket) do
    case socket.assigns.selected_world do
      nil ->
        {:noreply, put_flash(socket, :error, "Select a world before updating")}

      world ->
        attrs = Map.drop(params, ["galaxy_id", "template", "template_galaxy"])

        with {:ok, galaxy} <- get_optional_galaxy(socket, params["galaxy_id"]),
             {:ok, _world} <- Worlds.update_world(world, attrs, galaxy: galaxy) do
          {:noreply, socket |> put_flash(:info, "World updated") |> reload_index()}
        else
          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "World could not be updated")}
        end
    end
  end

  def handle_event("update_galaxy", %{"galaxy" => params}, socket) do
    case socket.assigns.selected_galaxy do
      nil ->
        {:noreply, put_flash(socket, :error, "Select a galaxy before updating")}

      galaxy ->
        case Galaxies.update_galaxy(galaxy, params) do
          {:ok, _galaxy} ->
            {:noreply, socket |> put_flash(:info, "Galaxy updated") |> reload_index()}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Galaxy could not be updated")}
        end
    end
  end

  def handle_event("set_theme", %{"theme" => theme}, socket) do
    {:noreply, assign(socket, :theme, normalize_theme(theme))}
  end

  def handle_event("set_library_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :library_tab, normalize_library_tab(tab))}
  end

  attr :counts, :map, required: true

  defp world_geography_stats(assigns) do
    ~H"""
    <div class="stone-border mt-2 flex flex-wrap gap-1.5 border-t pt-2 text-[11px]">
      <span class="stone-panel-muted stone-muted inline-flex items-center gap-1 rounded border px-1.5 py-0.5">
        <.icon name="hero-map" class="size-3" /> {@counts.holds} holds
      </span>
      <span class="stone-panel-muted stone-muted inline-flex items-center gap-1 rounded border px-1.5 py-0.5">
        <.icon name="hero-tag" class="size-3" /> {@counts.location_types} types
      </span>
      <span class="stone-panel-muted stone-muted inline-flex items-center gap-1 rounded border px-1.5 py-0.5">
        <.icon name="hero-map-pin" class="size-3" /> {@counts.locations} locations
      </span>
    </div>
    """
  end

  defp world_form(galaxies) do
    %{
      "name" => "",
      "description" => "",
      "template" => "blank",
      "template_galaxy" => nil,
      "galaxy_id" => first_id(galaxies),
      "primary_star_name" => "",
      "orbital_period_days" => "",
      "axial_tilt_degrees" => "",
      "day_length_hours" => "",
      "mean_radius_km" => "",
      "mass_earths" => "",
      "surface_gravity_m_s2" => "",
      "orbital_distance_au" => "",
      "orbital_eccentricity" => "",
      "atmospheric_pressure_atm" => "",
      "bond_albedo" => "",
      "ocean_fraction" => "",
      "star_mass_solar" => "",
      "star_luminosity_solar" => "",
      "star_temperature_k" => "",
      "map_projection" => ""
    }
    |> to_form(as: :world)
  end

  defp galaxy_form do
    %{"name" => "", "description" => ""}
    |> to_form(as: :galaxy)
  end

  defp selected_world_form(world) do
    %{
      "name" => world.name,
      "description" => world.description,
      "galaxy_id" => optional_id(world.galaxy_id),
      "primary_star_name" => world.primary_star_name,
      "orbital_period_days" => world.orbital_period_days,
      "axial_tilt_degrees" => world.axial_tilt_degrees,
      "day_length_hours" => world.day_length_hours,
      "mean_radius_km" => world.mean_radius_km,
      "mass_earths" => world.mass_earths,
      "surface_gravity_m_s2" => world.surface_gravity_m_s2,
      "orbital_distance_au" => world.orbital_distance_au,
      "orbital_eccentricity" => world.orbital_eccentricity,
      "atmospheric_pressure_atm" => world.atmospheric_pressure_atm,
      "bond_albedo" => world.bond_albedo,
      "ocean_fraction" => world.ocean_fraction,
      "star_mass_solar" => world.star_mass_solar,
      "star_luminosity_solar" => world.star_luminosity_solar,
      "star_temperature_k" => world.star_temperature_k,
      "map_projection" => world.map_projection,
      "template_galaxy" => nil
    }
    |> to_form(as: :world)
  end

  defp selected_galaxy_form(galaxy) do
    %{"name" => galaxy.name, "description" => galaxy.description}
    |> to_form(as: :galaxy)
  end

  defp assign_index_records(socket, galaxies) do
    assign_index_records(socket, galaxies, Worlds.list_worlds_without_galaxy())
  end

  defp reload_index(socket) do
    galaxies = Galaxies.list_galaxies()
    unassigned_worlds = Worlds.list_worlds_without_galaxy()

    socket
    |> assign_index_records(galaxies, unassigned_worlds)
    |> assign(:galaxy_options, option_list(galaxies))
    |> assign(:current_template, "blank")
    |> assign(:selected_world, nil)
    |> assign(:selected_galaxy, nil)
    |> assign(:world_form, world_form(galaxies))
    |> assign(:galaxy_form, galaxy_form())
    |> stream(:galaxies, galaxies, reset: true)
    |> stream(:worlds, unassigned_worlds, reset: true)
  end

  defp assign_index_records(socket, galaxies, unassigned_worlds) do
    inventory =
      Worlds.geography_inventory()
      |> Map.put(:galaxies, Galaxies.count_galaxies())
      |> Map.put(:maps, Maps.count_maps())

    world_counts =
      galaxies
      |> worlds_in_galaxies()
      |> Kernel.++(unassigned_worlds)
      |> Enum.map(& &1.id)
      |> Worlds.world_geography_counts()

    socket
    |> assign(:inventory, inventory)
    |> assign(:world_counts, world_counts)
    |> assign(:unassigned_world_count, length(unassigned_worlds))
  end

  defp option_list(records) do
    Enum.map(records, &{&1.name, to_string(&1.id)})
  end

  defp first_id([]) do
    nil
  end

  defp first_id([record | _records]) do
    to_string(record.id)
  end

  defp optional_id(nil) do
    nil
  end

  defp optional_id(id) do
    to_string(id)
  end

  defp get_optional_galaxy(_socket, galaxy_id) when galaxy_id in [nil, ""] do
    {:ok, nil}
  end

  defp get_optional_galaxy(socket, "__template_galaxy__") do
    if Templates.defaults(socket.assigns.current_template)[:galaxy] do
      {:ok, nil}
    else
      {:error, :record_outside_scope}
    end
  end

  defp get_optional_galaxy(socket, galaxy_id) do
    if Enum.any?(socket.assigns.galaxy_options, fn {_name, id} -> id == galaxy_id end) do
      {:ok, Galaxies.get_galaxy!(galaxy_id)}
    else
      {:error, :record_outside_scope}
    end
  end

  defp template_galaxy_id(nil, _galaxy_options) do
    nil
  end

  defp template_galaxy_id(template_galaxy, galaxy_options) do
    Enum.find_value(galaxy_options, fn
      {^template_galaxy, id} -> id
      _option -> nil
    end)
  end

  defp template_galaxy_selection(nil, galaxy_options, fallback_id) do
    Enum.find_value(galaxy_options, fn
      {_name, ^fallback_id} -> fallback_id
      _option -> nil
    end)
  end

  defp template_galaxy_selection(template_galaxy, galaxy_options, _fallback_id) do
    template_galaxy_id(template_galaxy, galaxy_options) || "__template_galaxy__"
  end

  defp world_galaxy_options(world_form, galaxy_options) do
    template_galaxy = world_form[:template_galaxy].value

    if template_galaxy in [nil, ""] or
         Enum.any?(galaxy_options, fn {name, _id} -> name == template_galaxy end) do
      galaxy_options
    else
      [{template_galaxy, "__template_galaxy__"} | galaxy_options]
    end
  end

  defp world_count(%{worlds: worlds}) when is_list(worlds) do
    length(worlds)
  end

  defp world_count(_galaxy) do
    0
  end

  defp world_counts(counts_by_world, world) do
    Map.get(counts_by_world, world.id, %{holds: 0, location_types: 0, locations: 0})
  end

  defp worlds_in_galaxies(galaxies) do
    Enum.flat_map(galaxies, fn galaxy ->
      if is_list(galaxy.worlds) do
        galaxy.worlds
      else
        []
      end
    end)
  end

  defp sorted_worlds(worlds) do
    Enum.sort_by(worlds, & &1.name)
  end

  defp normalize_library_tab(tab) when tab in ~w(galaxies unassigned_worlds) do
    tab
  end

  defp normalize_library_tab(_tab) do
    "galaxies"
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
end
