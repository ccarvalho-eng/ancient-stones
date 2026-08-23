defmodule AncientStonesWeb.WorldLive.EconomyComponents do
  use AncientStonesWeb, :html

  attr :world, :any, required: true
  attr :mode, :atom, required: true
  attr :trade_routes, :list, required: true
  attr :trade_flows, :list, required: true
  attr :tax_policies, :list, required: true
  attr :tax_exemptions, :list, required: true
  attr :tax_revenue_shares, :list, required: true
  attr :selected_trade_route, :any, default: nil
  attr :selected_trade_flow, :any, default: nil
  attr :selected_tax_policy, :any, default: nil
  attr :selected_tax_exemption, :any, default: nil
  attr :selected_tax_revenue_share, :any, default: nil
  attr :trade_route_form, :any, required: true
  attr :trade_flow_form, :any, required: true
  attr :tax_policy_form, :any, required: true
  attr :tax_exemption_form, :any, required: true
  attr :tax_revenue_share_form, :any, required: true
  attr :hold_options, :list, required: true
  attr :trade_route_options, :list, required: true
  attr :currency_options, :list, required: true
  attr :office_options, :list, required: true
  attr :jurisdiction_options, :list, required: true
  attr :beneficiary_options, :list, required: true

  def economy_dashboard(assigns) do
    ~H"""
    <div
      id="economy-dashboard"
      class="grid min-h-[800px] gap-4 bg-zinc-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_380px] dark:bg-zinc-900"
    >
      <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-950">
        <header class="border-b border-zinc-200 px-4 py-3 dark:border-zinc-700">
          <h2 class="stone-heading text-sm font-semibold">Economy</h2>
          <p class="stone-muted text-xs">Trade, taxation, exemptions, and treasury shares</p>
        </header>
        <div id="economy-record-list" class="max-h-[800px] space-y-2 overflow-y-auto p-2">
          <.group
            title="Trade routes"
            records={@trade_routes}
            world={@world}
            kind="trade_route"
            param="trade_route_id"
            selected={@selected_trade_route}
          />
          <.group
            title="Trade flows"
            records={@trade_flows}
            world={@world}
            kind="trade_flow"
            param="trade_flow_id"
            selected={@selected_trade_flow}
            name_field={:commodity}
          />
          <.group
            title="Tax policies"
            records={@tax_policies}
            world={@world}
            kind="tax_policy"
            param="tax_policy_id"
            selected={@selected_tax_policy}
          />
          <.group
            title="Exemptions"
            records={@tax_exemptions}
            world={@world}
            kind="tax_exemption"
            param="tax_exemption_id"
            selected={@selected_tax_exemption}
          />
          <.group
            title="Revenue shares"
            records={@tax_revenue_shares}
            world={@world}
            kind="tax_revenue_share"
            param="tax_revenue_share_id"
            selected={@selected_tax_revenue_share}
            name_field={:percentage}
          />
        </div>
      </aside>

      <main class="rounded-md border border-zinc-200 bg-white p-5 dark:border-zinc-700 dark:bg-zinc-950">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-zinc-200 pb-4 dark:border-zinc-700">
          <div>
            <p class="stone-muted text-[11px] font-semibold uppercase tracking-widest">
              Economic record
            </p><h2 class="stone-heading text-lg font-semibold">{record_title(assigns)}</h2>
          </div>
          <div class="flex flex-wrap gap-1.5">
            <.link
              :for={{label, mode} <- modes()}
              patch={~p"/worlds/#{@world}/dashboard?section=economy&mode=#{mode}"}
              class="stone-button rounded border px-2 py-1 text-[11px] font-semibold transition"
            >{label}</.link>
          </div>
        </div>
        <div id="economy-record-details" class="stone-muted mt-5 text-sm">
          <p>{record_summary(assigns)}</p>
        </div>
      </main>

      <aside class="overflow-hidden rounded-md border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-950">
        <header class="border-b border-zinc-200 px-4 py-3 dark:border-zinc-700">
          <h2 class="stone-heading text-sm font-semibold">Properties</h2><p class="stone-muted text-xs">
            Select to edit, then Save or Cancel.
          </p>
        </header>
        <div id="economy-properties" class="max-h-[800px] overflow-y-auto p-4">
          <%= case @mode do %>
            <% :route -> %>
              <.form
                for={@trade_route_form}
                id="trade-route-form"
                phx-submit="save_trade_route"
                class="space-y-3"
              >
                <.input field={@trade_route_form[:name]} label="Name" required />
                <.input
                  field={@trade_route_form[:origin_hold_id]}
                  type="select"
                  label="Origin hold"
                  options={@hold_options}
                  required
                />
                <.input
                  field={@trade_route_form[:destination_hold_id]}
                  type="select"
                  label="Destination hold"
                  options={@hold_options}
                  required
                />
                <.input
                  field={@trade_route_form[:transport_mode]}
                  type="select"
                  label="Transport"
                  options={AncientStones.Worlds.TradeRoute.transport_mode_options()}
                  required
                />
                <.input
                  field={@trade_route_form[:distance_km]}
                  type="number"
                  step="any"
                  label="Distance km"
                />
                <.input
                  field={@trade_route_form[:seasonality]}
                  type="select"
                  label="Seasonality"
                  prompt="Not specified"
                  options={AncientStones.Worlds.TradeRoute.seasonality_options()}
                />
                <.input
                  field={@trade_route_form[:risk]}
                  type="select"
                  label="Risk"
                  prompt="Not assessed"
                  options={AncientStones.Worlds.TradeRoute.risk_options()}
                />
                <.input
                  field={@trade_route_form[:status]}
                  type="select"
                  label="Status"
                  options={AncientStones.Worlds.TradeRoute.status_options()}
                />
                <.input field={@trade_route_form[:description]} type="textarea" label="Description" />
                <.actions world={@world} />
              </.form>
            <% :flow -> %>
              <.form
                for={@trade_flow_form}
                id="trade-flow-form"
                phx-submit="save_trade_flow"
                class="space-y-3"
              >
                <.input
                  field={@trade_flow_form[:trade_route_id]}
                  type="select"
                  label="Route"
                  options={@trade_route_options}
                  required
                />
                <.input field={@trade_flow_form[:commodity]} label="Commodity" required />
                <.input field={@trade_flow_form[:category]} label="Category" />
                <.input
                  field={@trade_flow_form[:quantity]}
                  type="number"
                  step="any"
                  label="Quantity"
                  required
                />
                <.input field={@trade_flow_form[:unit]} label="Unit" required />
                <.input
                  field={@trade_flow_form[:declared_value]}
                  type="number"
                  step="any"
                  label="Declared value"
                  required
                />
                <.input
                  field={@trade_flow_form[:currency_id]}
                  type="select"
                  label="Currency"
                  options={@currency_options}
                  required
                />
                <.input
                  field={@trade_flow_form[:frequency]}
                  type="select"
                  label="Frequency"
                  options={AncientStones.Worlds.TradeFlow.frequency_options()}
                />
                <.input field={@trade_flow_form[:description]} type="textarea" label="Description" />
                <.actions world={@world} />
              </.form>
            <% :policy -> %>
              <.form
                for={@tax_policy_form}
                id="tax-policy-form"
                phx-submit="save_tax_policy"
                class="space-y-3"
              >
                <.input field={@tax_policy_form[:name]} label="Name" required />
                <.input
                  field={@tax_policy_form[:jurisdiction]}
                  type="select"
                  label="Jurisdiction"
                  options={@jurisdiction_options}
                  required
                />
                <.input
                  field={@tax_policy_form[:tax_type]}
                  type="select"
                  label="Tax type"
                  options={AncientStones.Worlds.TaxPolicy.tax_type_options()}
                />
                <.input
                  field={@tax_policy_form[:rate_basis]}
                  type="select"
                  label="Rate basis"
                  options={AncientStones.Worlds.TaxPolicy.rate_basis_options()}
                />
                <.input
                  field={@tax_policy_form[:rate]}
                  type="number"
                  step="any"
                  label="Rate"
                  required
                />
                <.input
                  field={@tax_policy_form[:currency_id]}
                  type="select"
                  label="Currency"
                  prompt="Optional for percentages"
                  options={@currency_options}
                />
                <.input
                  field={@tax_policy_form[:collecting_office_id]}
                  type="select"
                  label="Collector"
                  prompt="Unassigned"
                  options={@office_options}
                />
                <.input
                  field={@tax_policy_form[:direction]}
                  type="select"
                  label="Direction"
                  options={AncientStones.Worlds.TaxPolicy.direction_options()}
                />
                <.input
                  field={@tax_policy_form[:status]}
                  type="select"
                  label="Status"
                  options={AncientStones.Worlds.TaxPolicy.status_options()}
                />
                <.input field={@tax_policy_form[:description]} type="textarea" label="Description" />
                <.actions world={@world} />
              </.form>
            <% :exemption -> %>
              <.form
                for={@tax_exemption_form}
                id="tax-exemption-form"
                phx-submit="save_tax_exemption"
                class="space-y-3"
              >
                <.input field={@tax_exemption_form[:name]} label="Name" required />
                <.input
                  field={@tax_exemption_form[:tax_policy_id]}
                  type="select"
                  label="Policy"
                  options={Enum.map(@tax_policies, &{&1.name, &1.id})}
                  required
                />
                <.input
                  field={@tax_exemption_form[:beneficiary]}
                  type="select"
                  label="Beneficiary"
                  options={@beneficiary_options}
                  required
                />
                <.input
                  field={@tax_exemption_form[:exemption_percentage]}
                  type="number"
                  step="any"
                  label="Exemption percentage"
                  required
                />
                <.input field={@tax_exemption_form[:description]} type="textarea" label="Description" />
                <.actions world={@world} />
              </.form>
            <% :share -> %>
              <.form
                for={@tax_revenue_share_form}
                id="tax-revenue-share-form"
                phx-submit="save_tax_revenue_share"
                class="space-y-3"
              >
                <.input
                  field={@tax_revenue_share_form[:tax_policy_id]}
                  type="select"
                  label="Policy"
                  options={Enum.map(@tax_policies, &{&1.name, &1.id})}
                  required
                />
                <.input
                  field={@tax_revenue_share_form[:political_office_id]}
                  type="select"
                  label="Recipient office"
                  options={@office_options}
                  required
                />
                <.input
                  field={@tax_revenue_share_form[:percentage]}
                  type="number"
                  step="any"
                  label="Percentage"
                  required
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
  attr :records, :list, required: true
  attr :world, :any, required: true
  attr :kind, :string, required: true
  attr :param, :string, required: true
  attr :selected, :any, default: nil
  attr :name_field, :atom, default: :name

  defp group(assigns) do
    ~H"""
    <details open class="rounded-md border border-zinc-200 dark:border-zinc-700">
      <summary class="stone-heading flex cursor-pointer list-none justify-between px-3 py-2 text-xs font-semibold uppercase tracking-wide">
        <span>{@title}</span><span class="stone-muted">{length(@records)}</span>
      </summary>
      <div class="space-y-1 border-t border-zinc-200 p-1.5 dark:border-zinc-700">
        <div
          :for={record <- @records}
          class="grid grid-cols-[minmax(0,1fr)_32px] overflow-hidden rounded border border-zinc-200 dark:border-zinc-700"
        >
          <.link
            id={"economy-#{@kind}-#{record.id}"}
            patch={record_path(@world, @param, @kind, record)}
            class={[
              "stone-heading truncate px-2.5 py-2 text-xs font-semibold transition hover:bg-zinc-100 dark:hover:bg-zinc-800",
              @selected && @selected.id == record.id && "bg-zinc-100 dark:bg-zinc-800"
            ]}
          >{display(Map.get(record, @name_field))}</.link>
          <button
            id={"delete-#{@kind}-#{record.id}"}
            type="button"
            phx-click="delete_economy_record"
            phx-value-kind={@kind}
            phx-value-id={record.id}
            data-confirm="Delete this economic record?"
            class="stone-button border-l border-zinc-200 text-zinc-500 hover:text-red-600 dark:border-zinc-700"
          ><.icon name="hero-trash" class="size-3.5" /></button>
        </div>
      </div>
    </details>
    """
  end

  attr :world, :any, required: true

  defp actions(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-2 pt-2">
      <.button class="stone-button rounded-md border px-3 py-2 text-sm font-semibold transition">Save</.button><.link
        patch={~p"/worlds/#{@world}/dashboard?section=economy"}
        class="stone-button rounded-md border px-3 py-2 text-center text-sm font-semibold transition"
      >Cancel</.link>
    </div>
    """
  end

  defp record_path(world, param, kind, record) do
    mode =
      Map.fetch!(
        %{
          "trade_route" => "route",
          "trade_flow" => "flow",
          "tax_policy" => "policy",
          "tax_exemption" => "exemption",
          "tax_revenue_share" => "share"
        },
        kind
      )

    query = %{"section" => "economy", "mode" => mode, param => record.id}

    query =
      if kind == "tax_revenue_share" do
        Map.put(query, "tax_policy_id", record.tax_policy_id)
      else
        query
      end

    ~p"/worlds/#{world}/dashboard?#{query}"
  end

  defp modes,
    do: [
      {"Route", "route"},
      {"Flow", "flow"},
      {"Policy", "policy"},
      {"Exemption", "exemption"},
      {"Share", "share"}
    ]

  defp record_title(assigns), do: selected_record(assigns) |> record_name("New #{assigns.mode}")
  defp record_summary(assigns), do: selected_record(assigns) |> record_description()
  defp selected_record(%{mode: :route} = assigns), do: assigns.selected_trade_route
  defp selected_record(%{mode: :flow} = assigns), do: assigns.selected_trade_flow
  defp selected_record(%{mode: :policy} = assigns), do: assigns.selected_tax_policy
  defp selected_record(%{mode: :exemption} = assigns), do: assigns.selected_tax_exemption
  defp selected_record(%{mode: :share} = assigns), do: assigns.selected_tax_revenue_share
  defp record_name(nil, fallback), do: fallback
  defp record_name(%{commodity: value}, _fallback) when not is_nil(value), do: value
  defp record_name(%{name: value}, _fallback) when not is_nil(value), do: value
  defp record_name(%{percentage: value}, _fallback), do: "#{display(value)}% revenue share"

  defp record_description(nil),
    do: "Choose a record from the left, or use the form to create one."

  defp record_description(%{description: value}) when value not in [nil, ""], do: value
  defp record_description(_record), do: "This record has no description yet."
  defp display(%Decimal{} = value), do: Decimal.to_string(value, :normal)
  defp display(value), do: to_string(value)
end
