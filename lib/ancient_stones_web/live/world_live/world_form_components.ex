defmodule AncientStonesWeb.WorldLive.WorldFormComponents do
  use AncientStonesWeb, :html

  attr :form, Phoenix.HTML.Form, required: true
  attr :id_prefix, :string, required: true
  attr :add_event, :string, required: true
  attr :remove_event, :string, required: true
  attr :map_form, :boolean, default: false
  attr :editing, :boolean, default: false

  def moon_fields(assigns) do
    ~H"""
    <section
      id={"#{@id_prefix}-moons"}
      data-mode={if(@editing, do: "edit", else: "create")}
      class="stone-border rounded-md border"
    >
      <div class="stone-border flex items-start justify-between gap-3 border-b px-3 py-3">
        <div>
          <h4 class="stone-heading text-sm font-semibold">Moons</h4>
          <p class="stone-muted mt-1 text-xs">
            <%= if @editing do %>
              Edit existing moons or stage additions and removals. Changes apply when you save the world.
            <% else %>
              Add any known natural satellites. A world may be created without one.
            <% end %>
          </p>
        </div>
        <button
          id={"#{@id_prefix}-add-moon"}
          type="button"
          phx-click={@add_event}
          class="stone-button inline-flex shrink-0 items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-xs font-medium transition"
        >
          <.icon name="hero-plus" class="size-3.5" /> Add moon
        </button>
      </div>

      <div id={"#{@id_prefix}-moon-fields"} class="space-y-3 p-3">
        <%= if @map_form do %>
          <.inputs_for :let={moon_form} field={@form[:moons]} default={[]}>
            <.moon_entry
              moon_form={moon_form}
              id_prefix={@id_prefix}
              remove_event={@remove_event}
            />
          </.inputs_for>
        <% else %>
          <.inputs_for :let={moon_form} field={@form[:moons]}>
            <.moon_entry
              moon_form={moon_form}
              id_prefix={@id_prefix}
              remove_event={@remove_event}
            />
          </.inputs_for>
        <% end %>
      </div>
    </section>
    """
  end

  def append_moon_params(params) do
    moons = ordered_moon_params(Map.get(params, "moons", %{}))
    Map.put(params, "moons", index_moon_params(moons ++ [blank_moon_params()]))
  end

  def remove_moon_params(params, index) do
    with {parsed_index, ""} <- Integer.parse(to_string(index)),
         true <- parsed_index >= 0 do
      moons = ordered_moon_params(Map.get(params, "moons", %{}))
      Map.put(params, "moons", moons |> List.delete_at(parsed_index) |> index_moon_params())
    else
      _other -> params
    end
  end

  attr :moon_form, Phoenix.HTML.Form, required: true
  attr :id_prefix, :string, required: true
  attr :remove_event, :string, required: true

  defp moon_entry(assigns) do
    ~H"""
    <article
      id={"#{@id_prefix}-moon-#{@moon_form.index}"}
      class="stone-panel-muted stone-border rounded-md border p-3"
    >
      <.input field={@moon_form[:id]} type="hidden" />
      <div class="mb-3 flex items-center justify-between gap-3">
        <h5 class="stone-heading text-xs font-semibold uppercase tracking-wide">
          {moon_heading(@moon_form)}
        </h5>
        <button
          id={"#{@id_prefix}-remove-moon-#{@moon_form.index}"}
          type="button"
          phx-click={@remove_event}
          phx-value-index={@moon_form.index}
          class="stone-button inline-flex size-7 items-center justify-center rounded-md border transition"
          aria-label={"Remove #{moon_heading(@moon_form)}"}
        >
          <.icon name="hero-x-mark" class="size-3.5" />
        </button>
      </div>

      <div class="grid gap-3 sm:grid-cols-2">
        <.input field={@moon_form[:name]} type="text" label="Name" required />
        <.input
          field={@moon_form[:orbital_period_days]}
          type="number"
          label="Orbital Period (days)"
          step="0.00001"
          min="0.00001"
          tooltip="Calculated from planet mass and orbital distance when possible; otherwise enter the sidereal period."
        />
        <.input
          field={@moon_form[:semi_major_axis_km]}
          type="number"
          label="Orbital Distance (km)"
          min="1"
          tooltip="Semi-major axis measured from the planet's centre, not its surface."
        />
        <.input
          field={@moon_form[:mean_radius_km]}
          type="number"
          label="Moon Radius (km)"
          min="1"
          tooltip="Mean radius of the moon in kilometres."
        />
        <.input
          field={@moon_form[:mass_lunar]}
          type="number"
          label="Mass (Moons)"
          step="0.000001"
          min="0.000001"
          tooltip="Mass relative to Earth's Moon; 1 equals one lunar mass."
        />
        <.input
          field={@moon_form[:orbital_eccentricity]}
          type="number"
          label="Eccentricity"
          step="0.000001"
          min="0"
          max="0.999999"
          tooltip="Orbital shape: 0 is circular, while values below 1 describe bound elliptical orbits."
        />
      </div>

      <details
        id={"#{@id_prefix}-moon-#{@moon_form.index}-advanced"}
        class="stone-border mt-3 rounded-md border"
      >
        <summary class="stone-heading cursor-pointer px-3 py-2 text-xs font-semibold">
          Advanced moon data
        </summary>
        <div class="stone-border grid gap-3 border-t p-3 sm:grid-cols-2">
          <.input
            field={@moon_form[:inclination_degrees]}
            type="number"
            label="Inclination (degrees)"
            step="0.0001"
            min="0"
            max="180"
            tooltip="Angle between the moon's orbit and the planet's reference plane."
          />
          <.input
            field={@moon_form[:tidal_role]}
            type="textarea"
            label="Tidal Role"
            rows="3"
            tooltip="Observable effects on tides, calendars, navigation, or coastal life."
          />
          <div class="sm:col-span-2">
            <.input
              field={@moon_form[:description]}
              type="textarea"
              label="Description"
              rows="3"
            />
          </div>
        </div>
      </details>
    </article>
    """
  end

  defp ordered_moon_params(moons) when is_map(moons) do
    moons
    |> Enum.sort_by(fn {index, _moon} -> moon_index(index) end)
    |> Enum.map(fn {_index, moon} -> moon end)
  end

  defp ordered_moon_params(moons) when is_list(moons) do
    moons
  end

  defp ordered_moon_params(_moons) do
    []
  end

  defp index_moon_params(moons) do
    moons
    |> Enum.with_index()
    |> Map.new(fn {moon, index} -> {Integer.to_string(index), moon} end)
  end

  defp moon_index(index) do
    case Integer.parse(to_string(index)) do
      {parsed_index, ""} -> parsed_index
      _other -> 0
    end
  end

  defp moon_heading(moon_form) do
    case moon_form[:name].value |> to_string() |> String.trim() do
      "" -> "Moon #{moon_form.index + 1}"
      name -> name
    end
  end

  defp blank_moon_params do
    %{
      "id" => "",
      "name" => "",
      "orbital_period_days" => "",
      "semi_major_axis_km" => "",
      "mean_radius_km" => "",
      "mass_lunar" => "",
      "orbital_eccentricity" => "",
      "inclination_degrees" => "",
      "tidal_role" => "",
      "description" => ""
    }
  end
end
