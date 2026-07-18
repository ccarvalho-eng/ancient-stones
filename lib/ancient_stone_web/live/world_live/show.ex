defmodule AncientStoneWeb.WorldLive.Show do
  use AncientStoneWeb, :live_view

  alias AncientStone.Worlds

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
      <div class="mx-auto max-w-2xl px-6 py-10" id="world-show">
        <.link navigate={~p"/worlds/new"} class="text-sm text-zinc-600
        hover:text-zinc-900">
          New world
        </.link>

        <h1 class="mt-6 text-3xl font-semibold text-zinc-900" id="world-name">
          {@world.name}
        </h1>

        <p class="mt-4 text-zinc-700" id="world-description">
          {@world.description}
        </p>
      </div>
    </Layouts.app>
    """
  end
end
