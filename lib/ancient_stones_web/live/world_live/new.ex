defmodule AncientStonesWeb.WorldLive.New do
  use AncientStonesWeb, :live_view

  alias AncientStones.Worlds

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
