defmodule AncientStoneWeb.WorldLive.New do
  use AncientStoneWeb, :live_view

  alias AncientStone.Worlds
  alias AncientStone.Worlds.World

  def mount(_params, _session, socket) do
    form =
      %World{}
      |> Worlds.change_world()
      |> to_form()

    {:ok, assign(socket, form: form)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-xl px-6 py-10">
        <h1 class="text-2xl font-semibold text-zinc-900">Create world</h1>

        <.form
          for={@form}
          id="world-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-8 space-y-6"
        >
          <.input field={@form[:name]} type="text" label="Name" required />
          <.input field={@form[:description]} type="textarea" label="Description" />

          <.button id="create-world-button" phx-disable-with="Creating...">
            Create world
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"world" => world_params}, socket) do
    form =
      %World{}
      |> Worlds.change_world(world_params)
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
