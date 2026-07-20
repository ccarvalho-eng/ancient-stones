defmodule AncientStonesWeb.WorldLive.Index do
  use AncientStonesWeb, :live_view

  alias AncientStones.Galaxies
  alias AncientStones.Templates
  alias AncientStones.Worlds

  def mount(_params, _session, socket) do
    galaxies = Galaxies.list_galaxies()

    {:ok,
     socket
     |> assign(:page_title, "Worlds")
     |> assign(:theme, "system")
     |> assign_index_records(galaxies)
     |> assign(:galaxy_options, option_list(galaxies))
     |> assign(:current_template, "blank")
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

            <main class="grid min-h-[720px] gap-4 p-4 xl:grid-cols-[minmax(0,1fr)_380px]">
              <section class="grid content-start gap-4">
                <div class="stone-panel flex flex-col overflow-hidden rounded-md border">
                  <.panel_header
                    title="Galaxies"
                    subtitle="Cosmic containers with their nested world records."
                    count={@inventory.galaxies}
                  />

                  <div
                    id="galaxies"
                    phx-update="stream"
                    class="grid max-h-[300px] gap-2 overflow-auto p-3"
                  >
                    <.empty_stream_state
                      id="galaxies-empty"
                      message="No galaxies yet."
                      class="py-5"
                    />
                    <div
                      :for={{id, galaxy} <- @streams.galaxies}
                      id={id}
                      class="stone-record-card rounded-md border p-3"
                    >
                      <div class="flex items-start justify-between gap-3">
                        <div class="min-w-0">
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
                        </div>
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
                          class="stone-soft-panel rounded-md border px-3 py-2"
                        >
                          <div class="flex items-start justify-between gap-3">
                            <div class="min-w-0">
                              <div class="stone-heading truncate text-sm font-medium">
                                {world.name}
                              </div>
                              <p class="stone-muted mt-1 line-clamp-2 text-xs leading-5">
                                {world.description || "No description yet."}
                              </p>
                              <.world_geography_stats counts={world_counts(@world_counts, world)} />
                            </div>
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

                <div class="stone-panel flex flex-col overflow-hidden rounded-md border">
                  <.panel_header
                    title="Unassigned Worlds"
                    subtitle="World records that are not associated with a galaxy."
                    count={@unassigned_world_count}
                  />

                  <div
                    id="worlds"
                    phx-update="stream"
                    class="grid max-h-[680px] gap-2 overflow-auto p-3"
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
                        <div class="min-w-0">
                          <div class="flex flex-wrap items-center gap-2">
                            <h4 class="stone-heading truncate text-sm font-semibold">{world.name}</h4>
                            <span class="stone-panel-muted stone-muted inline-flex items-center gap-1 rounded border px-2 py-0.5 text-xs">
                              <.icon name="hero-sparkles" class="size-3" /> No galaxy
                            </span>
                          </div>
                          <p class="stone-muted mt-2 line-clamp-2 text-sm">
                            {world.description || "No description yet."}
                          </p>
                          <.world_geography_stats counts={world_counts(@world_counts, world)} />
                        </div>
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
              </section>

              <aside class="grid content-start gap-4">
                <div class="stone-panel overflow-hidden rounded-md border">
                  <div class="stone-border border-b px-4 py-3">
                    <div class="stone-muted text-[11px] font-semibold uppercase tracking-wide">
                      Step 1
                    </div>
                    <h3 class="stone-heading mt-1 text-sm font-semibold">Create Galaxy</h3>
                    <p class="stone-muted mt-1 text-xs">
                      Use this first when the world belongs to a known cosmos.
                    </p>
                  </div>

                  <.form
                    for={@galaxy_form}
                    id="dashboard-galaxy-form"
                    phx-submit="create_galaxy"
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
                        <.icon name="hero-plus" class="size-4" /> Create galaxy
                      </span>
                    </.button>
                  </.form>
                </div>

                <div class="stone-panel overflow-hidden rounded-md border">
                  <div class="stone-border border-b px-4 py-3">
                    <div class="stone-muted text-[11px] font-semibold uppercase tracking-wide">
                      Step 2
                    </div>
                    <h3 class="stone-heading mt-1 text-sm font-semibold">Create World</h3>
                    <p class="stone-muted mt-1 text-xs">
                      A world is the planet record. Templates can fill starter geography.
                    </p>
                  </div>

                  <.form
                    for={@world_form}
                    id="dashboard-world-form"
                    phx-change="change_template"
                    phx-submit="create_world"
                    class="space-y-3 p-4"
                  >
                    <.input
                      field={@world_form[:template]}
                      type="select"
                      label="Template"
                      options={Templates.options()}
                    />
                    <.input field={@world_form[:template_galaxy]} type="hidden" />
                    <div
                      :if={@world_form[:template_galaxy].value not in [nil, ""]}
                      class="stone-panel-muted stone-muted rounded-md border px-3 py-2 text-xs"
                    >
                      Template galaxy:
                      <strong class="stone-heading font-semibold">
                        {@world_form[:template_galaxy].value}
                      </strong>
                    </div>
                    <.input
                      field={@world_form[:galaxy_id]}
                      type="select"
                      label="Galaxy"
                      prompt="None"
                      options={@galaxy_options}
                    />
                    <div class="stone-border border-t pt-3">
                      <.input field={@world_form[:name]} type="text" label="Name" required />
                    </div>
                    <.input
                      field={@world_form[:description]}
                      type="textarea"
                      label="Description"
                      rows="5"
                    />
                    <.button
                      id="dashboard-create-world-button"
                      class="stone-button w-full rounded-md border px-3 py-2 text-sm font-medium transition"
                    >
                      <span class="inline-flex items-center justify-center gap-2">
                        <.icon name="hero-plus" class="size-4" /> Create world
                      </span>
                    </.button>
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
        galaxy_id = template_galaxy_id(defaults[:galaxy], socket.assigns.galaxy_options)

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

  def handle_event("set_theme", %{"theme" => theme}, socket) do
    {:noreply, assign(socket, :theme, normalize_theme(theme))}
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
      "galaxy_id" => first_id(galaxies)
    }
    |> to_form(as: :world)
  end

  defp galaxy_form do
    %{"name" => "", "description" => ""}
    |> to_form(as: :galaxy)
  end

  defp assign_index_records(socket, galaxies) do
    assign_index_records(socket, galaxies, Worlds.list_worlds_without_galaxy())
  end

  defp assign_index_records(socket, galaxies, unassigned_worlds) do
    inventory =
      Worlds.geography_inventory()
      |> Map.put(:galaxies, Galaxies.count_galaxies())

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

  defp get_optional_galaxy(_socket, galaxy_id) when galaxy_id in [nil, ""] do
    {:ok, nil}
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
