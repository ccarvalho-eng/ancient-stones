defmodule AncientStonesWeb.WorldLive.Show do
  use AncientStonesWeb, :live_view

  alias AncientStones.Worlds

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "World")}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    world = Worlds.get_world!(id)

    {:noreply,
     socket
     |> assign(:world, world)
     |> assign(:page_title, world.name)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="stone-page stone-theme-light min-h-screen px-4 py-5" id="world-show">
        <div class="stone-shell mx-auto max-w-4xl overflow-hidden rounded-lg border shadow-sm">
          <header class="stone-topbar stone-border flex h-16 items-center justify-between border-b px-5">
            <div>
              <nav class="stone-muted flex items-center gap-1.5 text-xs font-medium">
                <.link navigate={~p"/worlds"} class="hover:text-zinc-800">Worlds</.link>
                <.icon name="hero-chevron-right" class="size-3.5" />
                <span class="stone-heading">{@world.name}</span>
              </nav>
              <h1 class="stone-heading mt-1 text-lg font-semibold" id="world-name">
                {@world.name}
              </h1>
            </div>
            <div class="flex items-center gap-2">
              <.link
                navigate={~p"/worlds/new"}
                class="stone-button inline-flex h-8 items-center gap-1.5 rounded-md border px-3 text-xs font-medium transition"
              >
                <.icon name="hero-plus" class="size-3.5" /> New
              </.link>
              <.link
                navigate={~p"/worlds/#{@world}/dashboard"}
                class="stone-button inline-flex h-8 items-center gap-1.5 rounded-md border px-3 text-xs font-medium transition"
              >
                Dashboard <.icon name="hero-arrow-right" class="size-3.5" />
              </.link>
            </div>
          </header>

          <main class="stone-workspace p-4">
            <section class="stone-panel overflow-hidden rounded-md border">
              <.panel_header
                title="World Summary"
                subtitle="Planet record and builder entry point."
              />
              <div class="p-4">
                <p class="stone-muted max-w-3xl text-sm leading-6" id="world-description">
                  {@world.description || "No description yet."}
                </p>
              </div>
            </section>
          </main>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
