defmodule AncientStonesWeb.WorldLive.New do
  use AncientStonesWeb, :live_view

  alias AncientStones.Worlds
  alias AncientStonesWeb.WorldLive.WorldFormComponents

  def mount(_params, _session, socket) do
    form =
      Worlds.change_new_world()
      |> to_form()

    {:ok, assign(socket, form: form)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="stone-page stone-theme-light min-h-screen px-4 py-5" id="world-new">
        <div class="stone-shell mx-auto max-w-3xl overflow-hidden rounded-lg border shadow-sm">
          <header class="stone-topbar stone-border flex h-16 items-center justify-between border-b px-5">
            <div>
              <p class="stone-muted text-[11px] font-semibold uppercase tracking-wide">
                Ancient Stones
              </p>
              <h1 class="stone-heading text-lg font-semibold">Create World</h1>
            </div>
            <.link
              navigate={~p"/worlds"}
              class="stone-button inline-flex h-8 items-center gap-1.5 rounded-md border px-3 text-xs font-medium transition"
            >
              <.icon name="hero-arrow-left" class="size-3.5" /> Worlds
            </.link>
          </header>

          <main class="stone-workspace p-4">
            <section class="stone-panel overflow-hidden rounded-md border">
              <.panel_header
                title="Blank World"
                subtitle="Create a minimal planet record without loading a template."
              />

              <.form
                for={@form}
                id="world-form"
                phx-change="validate"
                phx-submit="save"
                class="space-y-4 p-4"
              >
                <.input field={@form[:name]} type="text" label="Name" required />
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label="Description"
                  rows="5"
                />
                <div class="grid gap-3 sm:grid-cols-3">
                  <.input
                    field={@form[:primary_star_name]}
                    type="text"
                    label="Star"
                    tooltip="Primary star or sun the world orbits."
                  />
                  <.input
                    field={@form[:orbital_period_days]}
                    type="number"
                    label="Orbit Days"
                    tooltip="Number of days in one full orbit around the primary star."
                  />
                  <.input
                    field={@form[:axial_tilt_degrees]}
                    type="number"
                    label="Axial Tilt"
                    step="0.01"
                    tooltip="Planet tilt in degrees. Earth is about 23.5 degrees."
                  />
                </div>
                <div class="grid gap-3 sm:grid-cols-2">
                  <.input
                    field={@form[:day_length_hours]}
                    type="number"
                    label="Day Hours"
                    step="0.01"
                  />
                  <.input field={@form[:mean_radius_km]} type="number" label="Radius (km)" />
                </div>
                <details id="new-world-advanced-physical-data" class="stone-border rounded-md border">
                  <summary class="stone-heading cursor-pointer px-3 py-2 text-sm font-semibold">
                    Advanced physical data
                  </summary>
                  <div class="stone-border grid gap-3 border-t p-3 sm:grid-cols-2">
                    <.input
                      field={@form[:mass_earths]}
                      type="number"
                      label="Mass (Earths)"
                      step="0.00001"
                      tooltip="Planetary mass relative to Earth; 1 equals Earth's mass."
                    />
                    <.input
                      field={@form[:surface_gravity_m_s2]}
                      type="number"
                      label="Gravity (m/s²)"
                      step="0.0001"
                      tooltip="Surface acceleration due to gravity in metres per second squared; Earth is about 9.81 m/s²."
                    />
                    <.input
                      field={@form[:atmospheric_pressure_atm]}
                      type="number"
                      label="Pressure (atm)"
                      step="0.0001"
                      tooltip="Mean surface pressure in standard atmospheres; 1 atm is 101.325 kPa."
                    />
                    <.input
                      field={@form[:ocean_fraction]}
                      type="number"
                      label="Ocean Fraction"
                      step="0.00001"
                      min="0"
                      max="1"
                      tooltip="Fraction of the planet's surface covered by oceans, from 0 to 1."
                    />
                    <.input
                      field={@form[:bond_albedo]}
                      type="number"
                      label="Bond Albedo"
                      step="0.00001"
                      min="0"
                      max="1"
                      tooltip="Fraction of incoming stellar energy reflected by the planet, from 0 to 1."
                    />
                    <.input
                      field={@form[:orbital_distance_au]}
                      type="number"
                      label="Orbit (AU)"
                      step="0.000001"
                      tooltip="Orbital semi-major axis in astronomical units; 1 AU is Earth's mean distance from the Sun."
                    />
                    <.input
                      field={@form[:orbital_eccentricity]}
                      type="number"
                      label="Eccentricity"
                      step="0.000001"
                      tooltip="Orbital shape: 0 is circular, while values below 1 describe bound elliptical orbits."
                    />
                    <.input
                      field={@form[:star_mass_solar]}
                      type="number"
                      label="Star Mass (Suns)"
                      step="0.00001"
                      tooltip="Primary star mass relative to the Sun; 1 equals one solar mass."
                    />
                    <.input
                      field={@form[:star_luminosity_solar]}
                      type="number"
                      label="Star Luminosity (Suns)"
                      step="0.00001"
                      tooltip="Primary star energy output relative to the Sun; 1 equals one solar luminosity."
                    />
                    <.input
                      field={@form[:star_temperature_k]}
                      type="number"
                      label="Star Temperature (K)"
                      tooltip="Primary star effective surface temperature in kelvins; the Sun is about 5,772 K."
                    />
                  </div>
                </details>

                <WorldFormComponents.moon_fields
                  form={@form}
                  id_prefix="world-form"
                  add_event="add_world_moon"
                  remove_event="remove_world_moon"
                />

                <.button
                  id="create-world-button"
                  phx-disable-with="Creating..."
                  class="stone-button inline-flex w-full items-center justify-center rounded-md border px-3 py-2 text-sm font-medium transition"
                >
                  <span class="inline-flex items-center gap-2">
                    <.icon name="hero-plus" class="size-4" /> Create world
                  </span>
                </.button>
              </.form>
            </section>
          </main>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("add_world_moon", _params, socket) do
    params = WorldFormComponents.append_moon_params(socket.assigns.form.params || %{})

    form =
      params
      |> Worlds.change_new_world()
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("remove_world_moon", %{"index" => index}, socket) do
    params = WorldFormComponents.remove_moon_params(socket.assigns.form.params || %{}, index)

    form =
      params
      |> Worlds.change_new_world()
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("validate", %{"world" => world_params}, socket) do
    form =
      world_params
      |> Worlds.change_new_world()
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"world" => world_params}, socket) do
    case Worlds.create_world(world_params) do
      {:ok, world} ->
        {:noreply,
         socket
         |> put_flash(:info, "World created")
         |> push_navigate(to: ~p"/worlds/#{world}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
