defmodule AncientStonesWeb.WorldLive.WaterComponents do
  use AncientStonesWeb, :html

  attr :world, :any, required: true
  attr :mode, :atom, required: true
  attr :water_bodies, :any, required: true
  attr :connections, :any, required: true
  attr :province_links, :any, required: true
  attr :water_locations, :any, required: true
  attr :water_body_count, :integer, required: true
  attr :connection_count, :integer, required: true
  attr :province_link_count, :integer, required: true
  attr :water_location_count, :integer, required: true
  attr :selected_water_body, :any, default: nil
  attr :selected_connection, :any, default: nil
  attr :selected_province_link, :any, default: nil
  attr :selected_water_location, :any, default: nil
  attr :water_body_form, :any, required: true
  attr :connection_form, :any, required: true
  attr :province_link_form, :any, required: true
  attr :location_link_form, :any, required: true
  attr :water_body_options, :list, required: true
  attr :province_options, :list, required: true
  attr :location_options, :list, required: true

  def waters_dashboard(assigns) do
    ~H"""
    <div
      id="waters-dashboard"
      class="grid min-h-[800px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_380px] dark:bg-zinc-900"
    >
      <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-950">
        <header class="border-b border-zinc-200 px-4 py-3 dark:border-zinc-700">
          <h2 class="stone-heading text-sm font-semibold">Waters</h2>
          <p class="stone-muted text-xs">Named seas, rivers, drainage, and navigable links</p>
        </header>
        <div id="water-record-list" class="max-h-[800px] space-y-2 overflow-y-auto p-2">
          <.stream_group
            title="Water bodies"
            stream={@water_bodies}
            count={@water_body_count}
            world={@world}
            kind="water_body"
            param="water_body_id"
            selected={@selected_water_body}
          />
          <.stream_group
            title="Connections"
            stream={@connections}
            count={@connection_count}
            world={@world}
            kind="water_body_connection"
            param="water_body_connection_id"
            selected={@selected_connection}
          />
          <.stream_group
            title="Province relationships"
            stream={@province_links}
            count={@province_link_count}
            world={@world}
            kind="province_water_body"
            param="province_water_body_id"
            selected={@selected_province_link}
          />
          <.stream_group
            title="Waterfront locations"
            stream={@water_locations}
            count={@water_location_count}
            world={@world}
            kind="water_location"
            param="water_location_id"
            selected={@selected_water_location}
          />
        </div>
      </aside>

      <main class="rounded-md border border-zinc-200 bg-white p-5 dark:border-zinc-700 dark:bg-zinc-950">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-zinc-200 pb-4 dark:border-zinc-700">
          <div>
            <p class="stone-muted text-[11px] font-semibold uppercase tracking-widest">
              Water record
            </p>
            <h2 class="stone-heading text-lg font-semibold">{record_title(assigns)}</h2>
          </div>
          <div class="flex flex-wrap gap-1.5">
            <.link
              :for={{label, mode} <- modes()}
              patch={~p"/worlds/#{@world}/dashboard?section=waters&mode=#{mode}"}
              class="stone-button rounded border px-2 py-1 text-[11px] font-semibold transition"
            >{label}</.link>
          </div>
        </div>
        <div id="water-record-details" class="stone-muted mt-5 text-sm">
          <% details = record_details(assigns) %>
          <%= if details.selected? do %>
            <p class="max-w-3xl leading-6">{details.description}</p>
            <dl
              id="water-detail-fields"
              class="mt-5 grid gap-px overflow-hidden rounded-md border border-zinc-200 bg-zinc-200 sm:grid-cols-2 dark:border-zinc-700 dark:bg-zinc-700"
            >
              <div
                :for={{label, value} <- details.fields}
                class="bg-zinc-50 px-3 py-2.5 dark:bg-zinc-900"
              >
                <dt class="text-[10px] font-semibold uppercase tracking-wider text-zinc-500 dark:text-zinc-400">
                  {label}
                </dt>
                <dd class="stone-heading mt-1 text-sm font-medium">{value}</dd>
              </div>
            </dl>
          <% else %>
            <p>{details.description}</p>
          <% end %>
        </div>
      </main>

      <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-950">
        <header class="border-b border-zinc-200 px-4 py-3 dark:border-zinc-700">
          <h2 class="stone-heading text-sm font-semibold">Properties</h2>
          <p class="stone-muted text-xs">Chart physical conditions and practical navigation.</p>
        </header>
        <div id="water-properties" class="max-h-[800px] overflow-y-auto p-4">
          <%= case @mode do %>
            <% :body -> %>
              <.form
                for={@water_body_form}
                id="water-body-form"
                phx-submit="save_water_body"
                class="space-y-3"
              >
                <.input field={@water_body_form[:name]} label="Name" required />
                <.input
                  field={@water_body_form[:parent_water_body_id]}
                  type="select"
                  label="Parent water"
                  prompt="None"
                  options={@water_body_options}
                />
                <.input
                  field={@water_body_form[:kind]}
                  type="select"
                  label="Kind"
                  options={AncientStones.Worlds.WaterBody.kind_options()}
                  required
                />
                <.input
                  field={@water_body_form[:salinity]}
                  type="select"
                  label="Salinity"
                  options={AncientStones.Worlds.WaterBody.salinity_options()}
                  required
                />
                <.input
                  field={@water_body_form[:navigability]}
                  type="select"
                  label="Navigability"
                  options={AncientStones.Worlds.WaterBody.navigability_options()}
                  required
                />
                <.input
                  field={@water_body_form[:freeze_pattern]}
                  type="select"
                  label="Freeze pattern"
                  options={AncientStones.Worlds.WaterBody.freeze_pattern_options()}
                  required
                />
                <.input
                  field={@water_body_form[:prevailing_conditions]}
                  type="textarea"
                  label="Prevailing conditions"
                />
                <.input field={@water_body_form[:hazards]} type="textarea" label="Hazards" />
                <.input
                  field={@water_body_form[:status]}
                  type="select"
                  label="Status"
                  options={AncientStones.Worlds.WaterBody.status_options()}
                />
                <.input field={@water_body_form[:description]} type="textarea" label="Description" />
                <.actions world={@world} />
              </.form>
            <% :connection -> %>
              <.form
                for={@connection_form}
                id="water-body-connection-form"
                phx-submit="save_water_body_connection"
                class="space-y-3"
              >
                <.input
                  field={@connection_form[:origin_water_body_id]}
                  type="select"
                  label="Origin"
                  options={@water_body_options}
                  required
                />
                <.input
                  field={@connection_form[:destination_water_body_id]}
                  type="select"
                  label="Destination"
                  options={@water_body_options}
                  required
                />
                <.input
                  field={@connection_form[:connection_type]}
                  type="select"
                  label="Connection"
                  options={AncientStones.Worlds.WaterBodyConnection.connection_type_options()}
                  required
                />
                <.input
                  field={@connection_form[:directionality]}
                  type="select"
                  label="Hydrologic direction"
                  options={AncientStones.Worlds.WaterBodyConnection.directionality_options()}
                />
                <.input
                  field={@connection_form[:navigation_directionality]}
                  type="select"
                  label="Navigation direction"
                  options={
                    AncientStones.Worlds.WaterBodyConnection.navigation_directionality_options()
                  }
                />
                <.input
                  field={@connection_form[:navigability]}
                  type="select"
                  label="Navigability"
                  options={AncientStones.Worlds.WaterBodyConnection.navigability_options()}
                  required
                />
                <.input
                  field={@connection_form[:seasonality]}
                  type="select"
                  label="Seasonality"
                  prompt="Not specified"
                  options={AncientStones.Worlds.WaterBodyConnection.seasonality_options()}
                />
                <.input
                  field={@connection_form[:distance_km]}
                  type="number"
                  step="any"
                  label="Connected reach km"
                />
                <.input field={@connection_form[:description]} type="textarea" label="Description" />
                <.actions world={@world} />
              </.form>
            <% :province -> %>
              <.form
                for={@province_link_form}
                id="province-water-body-form"
                phx-submit="save_province_water_body"
                class="space-y-3"
              >
                <.input
                  field={@province_link_form[:province_id]}
                  type="select"
                  label="Province"
                  options={@province_options}
                  required
                />
                <.input
                  field={@province_link_form[:water_body_id]}
                  type="select"
                  label="Water body"
                  options={@water_body_options}
                  required
                />
                <.input
                  field={@province_link_form[:relationship]}
                  type="select"
                  label="Relationship"
                  options={AncientStones.Worlds.ProvinceWaterBody.relationship_options()}
                  required
                />
                <.input
                  field={@province_link_form[:description]}
                  type="textarea"
                  label="Description"
                />
                <.actions world={@world} />
              </.form>
            <% :location -> %>
              <.form
                for={@location_link_form}
                id="location-water-body-form"
                phx-submit="set_location_water_body"
                class="space-y-3"
              >
                <.input
                  field={@location_link_form[:location_id]}
                  type="select"
                  label="Location"
                  options={@location_options}
                  required
                />
                <.input
                  field={@location_link_form[:water_body_id]}
                  type="select"
                  label="Water body"
                  prompt="No linked water"
                  options={@water_body_options}
                />
                <.actions world={@world} />
              </.form>
          <% end %>
        </div>
      </aside>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :stream, :any, required: true
  attr :count, :integer, required: true
  attr :world, :any, required: true
  attr :kind, :string, required: true
  attr :param, :string, required: true
  attr :selected, :any, default: nil

  defp stream_group(assigns) do
    ~H"""
    <details open class="rounded-md border border-zinc-200 dark:border-zinc-700">
      <summary class="stone-heading flex cursor-pointer list-none justify-between px-3 py-2 text-xs font-semibold uppercase tracking-wide">
        <span>{@title}</span><span class="stone-muted">{@count}</span>
      </summary>
      <div
        id={"waters-#{@kind}-records"}
        phx-update="stream"
        class="space-y-1 border-t border-zinc-200 p-1.5 dark:border-zinc-700"
      >
        <p id={"waters-#{@kind}-empty"} class="stone-muted hidden px-2 py-3 text-xs only:block">
          No matching records.
        </p>
        <div
          :for={{dom_id, record} <- @stream}
          id={dom_id}
          class="grid grid-cols-[minmax(0,1fr)_32px] overflow-hidden rounded border border-zinc-200 dark:border-zinc-700"
        >
          <.link
            id={"waters-#{@kind}-#{record.id}"}
            patch={record_path(@world, @param, @kind, record)}
            class={[
              "stone-heading truncate px-2.5 py-2 text-xs font-semibold transition hover:bg-zinc-100 dark:hover:bg-zinc-800",
              @selected && @selected.id == record.id && "bg-zinc-100 dark:bg-zinc-800"
            ]}
          >{record_name(record)}</.link>
          <button
            :if={@kind != "water_location"}
            id={"delete-#{@kind}-#{record.id}"}
            type="button"
            phx-click="delete_water_record"
            phx-value-kind={@kind}
            phx-value-id={record.id}
            data-confirm="Delete this water record?"
            class="stone-button border-l border-zinc-200 text-zinc-500 hover:text-red-600 dark:border-zinc-700"
          ><.icon name="hero-trash" class="size-3.5" /></button>
          <span
            :if={@kind == "water_location"}
            class="stone-muted flex items-center justify-center border-l border-zinc-200 dark:border-zinc-700"
          ><.icon name="hero-map-pin" class="size-3.5" /></span>
        </div>
      </div>
    </details>
    """
  end

  attr :world, :any, required: true

  defp actions(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-2 pt-2">
      <.button class="stone-button rounded-md border px-3 py-2 text-sm font-semibold transition">
        Save
      </.button>
      <.link
        patch={~p"/worlds/#{@world}/dashboard?section=waters"}
        class="stone-button rounded-md border px-3 py-2 text-center text-sm font-semibold transition"
      >Cancel</.link>
    </div>
    """
  end

  defp record_path(world, param, kind, record) do
    mode =
      Map.fetch!(
        %{
          "water_body" => "body",
          "water_body_connection" => "connection",
          "province_water_body" => "province",
          "water_location" => "location"
        },
        kind
      )

    ~p"/worlds/#{world}/dashboard?#{%{"section" => "waters", "mode" => mode, param => record.id}}"
  end

  defp modes do
    [
      {"Water", "body"},
      {"Connection", "connection"},
      {"Province", "province"},
      {"Location", "location"}
    ]
  end

  defp record_title(assigns) do
    case selected_record(assigns) do
      nil -> "New #{assigns.mode}"
      record -> record_name(record)
    end
  end

  defp record_details(assigns) do
    case selected_record(assigns) do
      nil ->
        %{
          selected?: false,
          description: "Choose a record from the left, or use the form to chart one.",
          fields: []
        }

      record ->
        details_for(assigns.mode, record)
    end
  end

  defp details_for(:body, water) do
    details(
      water,
      [
        {"Kind", humanize(water.kind)},
        {"Parent water", association_name(water.parent_water_body)},
        {"Salinity", humanize(water.salinity)},
        {"Navigability", humanize(water.navigability)},
        {"Freeze pattern", humanize(water.freeze_pattern)},
        {"Prevailing conditions", water.prevailing_conditions},
        {"Hazards", water.hazards},
        {"Status", humanize(water.status)}
      ]
    )
  end

  defp details_for(:connection, connection) do
    details(
      connection,
      [
        {"Origin", association_name(connection.origin_water_body)},
        {"Destination", association_name(connection.destination_water_body)},
        {"Connection", humanize(connection.connection_type)},
        {"Hydrologic direction", humanize(connection.directionality)},
        {"Navigation direction", humanize(connection.navigation_directionality)},
        {"Navigability", humanize(connection.navigability)},
        {"Seasonality", humanize(connection.seasonality)},
        {"Connected reach", value_with_unit(connection.distance_km, "km")}
      ]
    )
  end

  defp details_for(:province, link) do
    details(
      link,
      [
        {"Province", association_name(link.province)},
        {"Water body", association_name(link.water_body)},
        {"Relationship", humanize(link.relationship)}
      ]
    )
  end

  defp details_for(:location, location) do
    details(
      location,
      [
        {"Water body", association_name(location.water_body)},
        {"Location type", association_name(location.location_type)}
      ]
    )
  end

  defp details(record, fields) do
    %{
      selected?: true,
      description: Map.get(record, :description) || "No description recorded.",
      fields: Enum.reject(fields, fn {_label, value} -> value in [nil, ""] end)
    }
  end

  defp selected_record(%{mode: :body} = assigns) do
    assigns.selected_water_body
  end

  defp selected_record(%{mode: :connection} = assigns) do
    assigns.selected_connection
  end

  defp selected_record(%{mode: :province} = assigns) do
    assigns.selected_province_link
  end

  defp selected_record(%{mode: :location} = assigns) do
    assigns.selected_water_location
  end

  defp selected_record(_assigns) do
    nil
  end

  defp record_name(%{origin_water_body: origin, destination_water_body: destination}) do
    "#{association_name(origin)} to #{association_name(destination)}"
  end

  defp record_name(%{province: province, water_body: water}) do
    "#{association_name(province)} / #{association_name(water)}"
  end

  defp record_name(record) do
    Map.get(record, :name) || "Untitled"
  end

  defp association_name(nil) do
    nil
  end

  defp association_name(%Ecto.Association.NotLoaded{}) do
    nil
  end

  defp association_name(record) do
    Map.get(record, :name) || "Untitled"
  end

  defp humanize(nil) do
    nil
  end

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp value_with_unit(nil, _unit) do
    nil
  end

  defp value_with_unit(value, unit) do
    "#{value} #{unit}"
  end
end
