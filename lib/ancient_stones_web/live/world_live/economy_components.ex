defmodule AncientStonesWeb.WorldLive.EconomyComponents do
  use AncientStonesWeb, :html

  attr :world, :any, required: true
  attr :mode, :atom, required: true
  attr :trade_routes, :list, required: true
  attr :trade_flows, :list, required: true
  attr :tax_policies, :list, required: true
  attr :tax_exemptions, :list, required: true
  attr :tax_revenue_shares, :list, required: true
  attr :economic_profiles, :any, required: true
  attr :commodity_balances, :any, required: true
  attr :tax_assessments, :any, required: true
  attr :commercial_ventures, :any, required: true
  attr :venture_memberships, :any, required: true
  attr :venture_trade_routes, :any, required: true
  attr :economic_profile_count, :integer, required: true
  attr :commodity_balance_count, :integer, required: true
  attr :tax_assessment_count, :integer, required: true
  attr :commercial_venture_count, :integer, required: true
  attr :venture_membership_count, :integer, required: true
  attr :venture_trade_route_count, :integer, required: true
  attr :selected_trade_route, :any, default: nil
  attr :selected_trade_flow, :any, default: nil
  attr :selected_tax_policy, :any, default: nil
  attr :selected_tax_exemption, :any, default: nil
  attr :selected_tax_revenue_share, :any, default: nil
  attr :selected_hold_economic_profile, :any, default: nil
  attr :selected_commodity_balance, :any, default: nil
  attr :selected_tax_assessment, :any, default: nil
  attr :selected_commercial_venture, :any, default: nil
  attr :selected_venture_membership, :any, default: nil
  attr :selected_venture_trade_route, :any, default: nil
  attr :trade_route_form, :any, required: true
  attr :trade_flow_form, :any, required: true
  attr :tax_policy_form, :any, required: true
  attr :tax_exemption_form, :any, required: true
  attr :tax_revenue_share_form, :any, required: true
  attr :hold_economic_profile_form, :any, required: true
  attr :commodity_balance_form, :any, required: true
  attr :tax_assessment_form, :any, required: true
  attr :commercial_venture_form, :any, required: true
  attr :venture_membership_form, :any, required: true
  attr :venture_trade_route_form, :any, required: true
  attr :route_stops, :any, required: true
  attr :route_legs, :any, required: true
  attr :route_stop_count, :integer, required: true
  attr :route_leg_count, :integer, required: true
  attr :selected_trade_route_stop, :any, default: nil
  attr :selected_trade_route_leg, :any, default: nil
  attr :trade_route_stop_form, :any, required: true
  attr :trade_route_leg_form, :any, required: true
  attr :hold_options, :list, required: true
  attr :trade_route_options, :list, required: true
  attr :currency_options, :list, required: true
  attr :office_options, :list, required: true
  attr :jurisdiction_options, :list, required: true
  attr :beneficiary_options, :list, required: true
  attr :location_options, :list, required: true
  attr :water_body_options, :list, required: true
  attr :trade_route_stop_options, :list, required: true
  attr :character_options, :list, required: true
  attr :household_options, :list, required: true

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
          <.stream_group
            title="Hold profiles"
            stream={@economic_profiles}
            count={@economic_profile_count}
            world={@world}
            kind="hold_economic_profile"
            param="hold_economic_profile_id"
            selected={@selected_hold_economic_profile}
          />
          <.stream_group
            title="Commodity balances"
            stream={@commodity_balances}
            count={@commodity_balance_count}
            world={@world}
            kind="commodity_balance"
            param="commodity_balance_id"
            selected={@selected_commodity_balance}
            name_field={:commodity}
          />
          <.stream_group
            title="Tax assessments"
            stream={@tax_assessments}
            count={@tax_assessment_count}
            world={@world}
            kind="tax_assessment"
            param="tax_assessment_id"
            selected={@selected_tax_assessment}
            name_field={:assessment_period_label}
          />
          <.stream_group
            title="Ventures"
            stream={@commercial_ventures}
            count={@commercial_venture_count}
            world={@world}
            kind="commercial_venture"
            param="commercial_venture_id"
            selected={@selected_commercial_venture}
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
          <% details = record_details(assigns) %>
          <%= if details.selected? do %>
            <p class="max-w-3xl leading-6">{details.description}</p>
            <dl
              id="economy-detail-fields"
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
            <section
              :for={section <- details.sections}
              id={section.id}
              class="mt-6 overflow-hidden rounded-md border border-zinc-200 dark:border-zinc-700"
            >
              <header class="flex items-center justify-between border-b border-zinc-200 bg-zinc-50 px-3 py-2 dark:border-zinc-700 dark:bg-zinc-900">
                <h3 class="stone-heading text-xs font-semibold uppercase tracking-wide">
                  {section.title}
                </h3>
                <span class="stone-muted text-xs">{length(section.items)}</span>
              </header>
              <div class="divide-y divide-zinc-200 dark:divide-zinc-700">
                <article :for={item <- section.items} class="px-3 py-3">
                  <div class="flex flex-wrap items-baseline justify-between gap-2">
                    <h4 class="stone-heading text-sm font-semibold">{item.name}</h4>
                    <span class="stone-muted text-xs font-medium">{item.meta}</span>
                  </div>
                  <p
                    :if={item.description not in [nil, ""]}
                    class="stone-muted mt-1.5 text-xs leading-5"
                  >
                    {item.description}
                  </p>
                </article>
              </div>
            </section>
          <% else %>
            <p>{details.description}</p>
          <% end %>
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
              <.route_topology
                :if={@selected_trade_route}
                world={@world}
                route={@selected_trade_route}
                stops={@route_stops}
                legs={@route_legs}
                stop_count={@route_stop_count}
                leg_count={@route_leg_count}
                selected_stop={@selected_trade_route_stop}
                selected_leg={@selected_trade_route_leg}
                stop_form={@trade_route_stop_form}
                leg_form={@trade_route_leg_form}
                location_options={@location_options}
                water_body_options={@water_body_options}
                stop_options={@trade_route_stop_options}
              />
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
                <.input
                  field={@trade_flow_form[:coverage_scope]}
                  type="select"
                  label="Coverage"
                  prompt="Not specified"
                  options={AncientStones.Worlds.TradeFlow.coverage_scope_options()}
                />
                <.input field={@trade_flow_form[:quantity_basis]} label="Quantity basis" />
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
            <% :profile -> %>
              <.form
                for={@hold_economic_profile_form}
                id="hold-economic-profile-form"
                phx-submit="save_hold_economic_profile"
                class="space-y-3"
              >
                <.input
                  field={@hold_economic_profile_form[:hold_id]}
                  type="select"
                  label="Hold"
                  options={@hold_options}
                  required
                />
                <.input
                  field={@hold_economic_profile_form[:population_estimate]}
                  type="number"
                  label="Population estimate"
                  required
                />
                <.input
                  field={@hold_economic_profile_form[:household_estimate]}
                  type="number"
                  label="Household estimate"
                  required
                />
                <.input
                  field={@hold_economic_profile_form[:urban_population_estimate]}
                  type="number"
                  label="Urban population estimate"
                  required
                />
                <.input
                  field={@hold_economic_profile_form[:arable_hectares_estimate]}
                  type="number"
                  step="any"
                  label="Arable hectares"
                />
                <.input
                  field={@hold_economic_profile_form[:pasture_hectares_estimate]}
                  type="number"
                  step="any"
                  label="Pasture hectares"
                />
                <.input
                  field={@hold_economic_profile_form[:staple_reserve_months]}
                  type="number"
                  step="any"
                  label="Staple reserve months"
                />
                <.input
                  field={@hold_economic_profile_form[:assessment_label]}
                  label="Assessment period"
                  required
                />
                <.input
                  field={@hold_economic_profile_form[:confidence]}
                  type="select"
                  label="Confidence"
                  options={AncientStones.Worlds.HoldEconomicProfile.confidence_options()}
                />
                <.input
                  field={@hold_economic_profile_form[:description]}
                  type="textarea"
                  label="Description"
                />
                <.actions world={@world} />
              </.form>
            <% :balance -> %>
              <.form
                for={@commodity_balance_form}
                id="commodity-balance-form"
                phx-submit="save_commodity_balance"
                class="space-y-3"
              >
                <.input
                  field={@commodity_balance_form[:hold_id]}
                  type="select"
                  label="Hold"
                  options={@hold_options}
                  required
                />
                <.input field={@commodity_balance_form[:commodity]} label="Commodity" required />
                <.input field={@commodity_balance_form[:category]} label="Category" />
                <.input field={@commodity_balance_form[:unit]} label="Unit" required />
                <.input
                  field={@commodity_balance_form[:annual_output]}
                  type="number"
                  step="any"
                  label="Annual output"
                  required
                />
                <.input
                  field={@commodity_balance_form[:annual_local_need]}
                  type="number"
                  step="any"
                  label="Annual local need"
                  required
                />
                <.input
                  field={@commodity_balance_form[:stored_reserve]}
                  type="number"
                  step="any"
                  label="Stored reserve"
                  required
                />
                <.input
                  field={@commodity_balance_form[:bad_year_output_percentage]}
                  type="number"
                  step="any"
                  label="Bad-year output percentage"
                  required
                />
                <.input
                  field={@commodity_balance_form[:storage_loss_percentage]}
                  type="number"
                  step="any"
                  label="Annual storage loss percentage"
                  required
                />
                <.input
                  field={@commodity_balance_form[:status]}
                  type="select"
                  label="Status"
                  options={AncientStones.Worlds.CommodityBalance.status_options()}
                />
                <.input
                  field={@commodity_balance_form[:description]}
                  type="textarea"
                  label="Description"
                />
                <.actions world={@world} />
              </.form>
            <% :assessment -> %>
              <.form
                for={@tax_assessment_form}
                id="tax-assessment-form"
                phx-submit="save_tax_assessment"
                class="space-y-3"
              >
                <.input
                  field={@tax_assessment_form[:tax_policy_id]}
                  type="select"
                  label="Tax policy"
                  options={Enum.map(@tax_policies, &{&1.name, &1.id})}
                  required
                />
                <.input
                  field={@tax_assessment_form[:currency_id]}
                  type="select"
                  label="Currency"
                  options={@currency_options}
                  required
                />
                <.input
                  field={@tax_assessment_form[:assessment_period_label]}
                  label="Assessment period"
                  required
                />
                <.input
                  field={@tax_assessment_form[:cash_yield]}
                  type="number"
                  step="any"
                  label="Cash yield"
                  required
                />
                <.input
                  field={@tax_assessment_form[:in_kind_value]}
                  type="number"
                  step="any"
                  label="In-kind value"
                  required
                />
                <.input
                  field={@tax_assessment_form[:customary_labor_days]}
                  type="number"
                  label="Customary labor days"
                  required
                />
                <.input
                  field={@tax_assessment_form[:confidence]}
                  type="select"
                  label="Confidence"
                  options={AncientStones.Worlds.TaxAssessment.confidence_options()}
                />
                <.input
                  field={@tax_assessment_form[:description]}
                  type="textarea"
                  label="Description"
                />
                <.actions world={@world} />
              </.form>
            <% :venture -> %>
              <.form
                for={@commercial_venture_form}
                id="commercial-venture-form"
                phx-submit="save_commercial_venture"
                class="space-y-3"
              >
                <.input field={@commercial_venture_form[:name]} label="Name" required />
                <.input
                  field={@commercial_venture_form[:venture_type]}
                  type="select"
                  label="Form"
                  options={AncientStones.Worlds.CommercialVenture.venture_type_options()}
                  required
                />
                <.input
                  field={@commercial_venture_form[:home_location_id]}
                  type="select"
                  label="Home place"
                  prompt="Itinerant or not recorded"
                  options={@location_options}
                />
                <.input
                  field={@commercial_venture_form[:status]}
                  type="select"
                  label="Status"
                  options={AncientStones.Worlds.CommercialVenture.status_options()}
                  required
                />
                <.input
                  field={@commercial_venture_form[:purpose]}
                  type="textarea"
                  label="Purpose"
                  required
                />
                <.input
                  field={@commercial_venture_form[:capital_basis]}
                  type="textarea"
                  label="Capital and assets"
                />
                <div class="grid grid-cols-2 gap-3">
                  <.input field={@commercial_venture_form[:formation_label]} label="Formed" />
                  <.input field={@commercial_venture_form[:end_label]} label="Ended" />
                </div>
                <.input
                  field={@commercial_venture_form[:description]}
                  type="textarea"
                  label="Description"
                />
                <.actions world={@world} />
              </.form>
              <.venture_maintenance
                :if={@selected_commercial_venture}
                world={@world}
                venture={@selected_commercial_venture}
                memberships={@venture_memberships}
                route_links={@venture_trade_routes}
                membership_count={@venture_membership_count}
                route_link_count={@venture_trade_route_count}
                selected_membership={@selected_venture_membership}
                selected_route_link={@selected_venture_trade_route}
                membership_form={@venture_membership_form}
                route_link_form={@venture_trade_route_form}
                character_options={@character_options}
                household_options={@household_options}
                trade_route_options={@trade_route_options}
              />
          <% end %>
        </div>
      </aside>
    </div>
    """
  end

  attr :world, :any, required: true
  attr :route, :any, required: true
  attr :stops, :any, required: true
  attr :legs, :any, required: true
  attr :stop_count, :integer, required: true
  attr :leg_count, :integer, required: true
  attr :selected_stop, :any, default: nil
  attr :selected_leg, :any, default: nil
  attr :stop_form, :any, required: true
  attr :leg_form, :any, required: true
  attr :location_options, :list, required: true
  attr :water_body_options, :list, required: true
  attr :stop_options, :list, required: true

  defp route_topology(assigns) do
    ~H"""
    <section
      id="trade-route-topology"
      class="mt-6 space-y-5 border-t border-zinc-200 pt-5 dark:border-zinc-700"
    >
      <div>
        <div class="mb-2 flex items-center justify-between">
          <h3 class="stone-heading text-xs font-semibold uppercase tracking-wide">Ordered stops</h3>
          <span class="stone-muted text-xs">{@stop_count}</span>
        </div>
        <div
          id="trade-route-stop-records"
          phx-update="stream"
          class="space-y-1 rounded border border-zinc-200 p-1.5 dark:border-zinc-700"
        >
          <p id="trade-route-stop-empty" class="stone-muted hidden px-2 py-3 text-xs only:block">
            No itinerary stops.
          </p>
          <div
            :for={{dom_id, stop} <- @stops}
            id={dom_id}
            class="grid grid-cols-[minmax(0,1fr)_32px] overflow-hidden rounded border border-zinc-200 dark:border-zinc-700"
          >
            <.link
              id={"economy-trade_route_stop-#{stop.id}"}
              patch={
                ~p"/worlds/#{@world}/dashboard?section=economy&mode=route&trade_route_id=#{@route.id}&trade_route_stop_id=#{stop.id}"
              }
              class={[
                "stone-heading truncate px-2 py-1.5 text-xs font-semibold transition hover:bg-zinc-100 dark:hover:bg-zinc-800",
                @selected_stop && @selected_stop.id == stop.id && "bg-zinc-100 dark:bg-zinc-800"
              ]}
            >{stop.position}. {association_name(stop.location)}</.link>
            <button
              id={"delete-trade_route_stop-#{stop.id}"}
              type="button"
              phx-click="delete_route_topology_record"
              phx-value-kind="trade_route_stop"
              phx-value-id={stop.id}
              data-confirm="Delete this stop and its adjacent legs?"
              class="stone-button border-l border-zinc-200 text-zinc-500 hover:text-red-600 dark:border-zinc-700"
            ><.icon name="hero-trash" class="size-3.5" /></button>
          </div>
        </div>
        <.form
          for={@stop_form}
          id="trade-route-stop-form"
          phx-submit="save_trade_route_stop"
          class="mt-3 space-y-3"
        >
          <.input
            field={@stop_form[:location_id]}
            type="select"
            label="Stop location"
            options={@location_options}
            required
          />
          <.input field={@stop_form[:position]} type="number" label="Position" required />
          <.input field={@stop_form[:handling_notes]} type="textarea" label="Handling notes" />
          <.input field={@stop_form[:description]} type="textarea" label="Description" />
          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-semibold transition">
            Save stop
          </.button>
        </.form>
      </div>

      <div>
        <div class="mb-2 flex items-center justify-between">
          <h3 class="stone-heading text-xs font-semibold uppercase tracking-wide">Route legs</h3>
          <span class="stone-muted text-xs">{@leg_count}</span>
        </div>
        <div
          id="trade-route-leg-records"
          phx-update="stream"
          class="space-y-1 rounded border border-zinc-200 p-1.5 dark:border-zinc-700"
        >
          <p id="trade-route-leg-empty" class="stone-muted hidden px-2 py-3 text-xs only:block">
            No route legs.
          </p>
          <div
            :for={{dom_id, leg} <- @legs}
            id={dom_id}
            class="grid grid-cols-[minmax(0,1fr)_32px] overflow-hidden rounded border border-zinc-200 dark:border-zinc-700"
          >
            <.link
              id={"economy-trade_route_leg-#{leg.id}"}
              patch={
                ~p"/worlds/#{@world}/dashboard?section=economy&mode=route&trade_route_id=#{@route.id}&trade_route_leg_id=#{leg.id}"
              }
              class={[
                "stone-heading min-w-0 px-2 py-1.5 text-xs font-semibold transition hover:bg-zinc-100 dark:hover:bg-zinc-800",
                @selected_leg && @selected_leg.id == leg.id && "bg-zinc-100 dark:bg-zinc-800"
              ]}
            >
              <span class="block truncate">
                {leg.position}. {association_name(leg.origin_stop.location)} to {association_name(
                  leg.destination_stop.location
                )}
              </span>
              <span
                :if={leg.water_traversals != []}
                id={"trade-route-leg-water-path-#{leg.id}"}
                class="stone-muted mt-0.5 block truncate text-[10px] font-normal"
              >{water_path_name(leg)}</span>
            </.link>
            <button
              id={"delete-trade_route_leg-#{leg.id}"}
              type="button"
              phx-click="delete_route_topology_record"
              phx-value-kind="trade_route_leg"
              phx-value-id={leg.id}
              data-confirm="Delete this route leg?"
              class="stone-button border-l border-zinc-200 text-zinc-500 hover:text-red-600 dark:border-zinc-700"
            ><.icon name="hero-trash" class="size-3.5" /></button>
          </div>
        </div>
        <.form
          for={@leg_form}
          id="trade-route-leg-form"
          phx-submit="save_trade_route_leg"
          class="mt-3 space-y-3"
        >
          <.input
            field={@leg_form[:origin_stop_id]}
            type="select"
            label="Origin stop"
            options={@stop_options}
            required
          />
          <.input
            field={@leg_form[:destination_stop_id]}
            type="select"
            label="Destination stop"
            options={@stop_options}
            required
          />
          <.input
            field={@leg_form[:water_body_id]}
            type="select"
            label="Required route water"
            prompt="Overland leg"
            options={@water_body_options}
          />
          <.input field={@leg_form[:position]} type="number" label="Position" required />
          <.input
            field={@leg_form[:transport_mode]}
            type="select"
            label="Transport"
            options={AncientStones.Worlds.TradeRouteLeg.transport_mode_options()}
            required
          />
          <.input
            field={@leg_form[:distance_km]}
            type="number"
            step="any"
            label="Distance km"
            required
          />
          <.input
            field={@leg_form[:typical_travel_days]}
            type="number"
            step="any"
            label="Typical travel days"
            required
          />
          <.input
            field={@leg_form[:seasonality]}
            type="select"
            label="Seasonality"
            prompt="Not specified"
            options={AncientStones.Worlds.TradeRouteLeg.seasonality_options()}
          />
          <.input
            field={@leg_form[:risk]}
            type="select"
            label="Risk"
            prompt="Not assessed"
            options={AncientStones.Worlds.TradeRouteLeg.risk_options()}
          />
          <.input field={@leg_form[:handling_notes]} type="textarea" label="Handling notes" />
          <.input field={@leg_form[:description]} type="textarea" label="Description" />
          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-semibold transition">
            Save leg
          </.button>
        </.form>
      </div>
    </section>
    """
  end

  defp water_path_name(leg) do
    leg.water_traversals
    |> Enum.sort_by(& &1.position)
    |> Enum.map_join(" → ", &association_name(&1.water_body))
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

  attr :title, :string, required: true
  attr :stream, :any, required: true
  attr :count, :integer, required: true
  attr :world, :any, required: true
  attr :kind, :string, required: true
  attr :param, :string, required: true
  attr :selected, :any, default: nil
  attr :name_field, :atom, default: :name

  defp stream_group(assigns) do
    ~H"""
    <details open class="rounded-md border border-zinc-200 dark:border-zinc-700">
      <summary class="stone-heading flex cursor-pointer list-none justify-between px-3 py-2 text-xs font-semibold uppercase tracking-wide">
        <span>{@title}</span><span class="stone-muted">{@count}</span>
      </summary>
      <div
        id={"economy-#{@kind}-records"}
        phx-update="stream"
        class="space-y-1 border-t border-zinc-200 p-1.5 dark:border-zinc-700"
      >
        <p
          id={"economy-#{@kind}-empty"}
          class="stone-muted hidden px-2 py-3 text-xs only:block"
        >
          No matching records.
        </p>
        <div
          :for={{dom_id, record} <- @stream}
          id={dom_id}
          class="grid grid-cols-[minmax(0,1fr)_32px] overflow-hidden rounded border border-zinc-200 dark:border-zinc-700"
        >
          <.link
            id={"economy-#{@kind}-#{record.id}"}
            patch={record_path(@world, @param, @kind, record)}
            class={[
              "stone-heading truncate px-2.5 py-2 text-xs font-semibold transition hover:bg-zinc-100 dark:hover:bg-zinc-800",
              @selected && @selected.id == record.id && "bg-zinc-100 dark:bg-zinc-800"
            ]}
          >{display(Map.get(record, @name_field) || association_name(Map.get(record, :hold)))}</.link>
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
  attr :venture, :any, required: true
  attr :memberships, :any, required: true
  attr :route_links, :any, required: true
  attr :membership_count, :integer, required: true
  attr :route_link_count, :integer, required: true
  attr :selected_membership, :any, default: nil
  attr :selected_route_link, :any, default: nil
  attr :membership_form, :any, required: true
  attr :route_link_form, :any, required: true
  attr :character_options, :list, required: true
  attr :household_options, :list, required: true
  attr :trade_route_options, :list, required: true

  defp venture_maintenance(assigns) do
    ~H"""
    <section
      id="venture-maintenance"
      class="mt-6 space-y-5 border-t border-zinc-200 pt-5 dark:border-zinc-700"
    >
      <div>
        <div class="flex items-center justify-between">
          <h3 class="stone-heading text-xs font-semibold uppercase tracking-wide">Partners</h3>
          <span class="stone-muted text-xs">{@membership_count}</span>
        </div>
        <div
          id="venture-memberships"
          phx-update="stream"
          class="mt-2 divide-y divide-zinc-200 rounded border border-zinc-200 dark:divide-zinc-700 dark:border-zinc-700"
        >
          <p id="venture-memberships-empty" class="stone-muted hidden px-3 py-3 text-xs only:block">
            No partners recorded.
          </p>
          <article
            :for={{dom_id, membership} <- @memberships}
            id={dom_id}
            class="flex items-start justify-between gap-3 px-3 py-2.5"
          >
            <div>
              <p class="stone-heading text-xs font-semibold">{venture_member_name(membership)}</p>
              <p class="stone-muted mt-0.5 text-[11px]">
                {membership.role} · {humanize(membership.status)}
                <span :if={membership.share_percentage}> · {display(membership.share_percentage)}%</span>
              </p>
            </div>
            <div class="flex gap-1">
              <.link
                id={"edit-venture-membership-#{membership.id}"}
                patch={
                  ~p"/worlds/#{@world}/dashboard?section=economy&mode=venture&commercial_venture_id=#{@venture.id}&venture_membership_id=#{membership.id}"
                }
                class="stone-button rounded border px-1.5 py-1 text-[10px] font-semibold"
              >Edit</.link>
              <button
                id={"delete-venture-membership-#{membership.id}"}
                type="button"
                phx-click="delete_economy_record"
                phx-value-kind="venture_membership"
                phx-value-id={membership.id}
                data-confirm="Remove this venture membership?"
                class="stone-button rounded border p-1"
                aria-label={"Delete membership for #{venture_member_name(membership)}"}
              ><.icon name="hero-trash" class="size-3.5" /></button>
            </div>
          </article>
        </div>
        <.form
          for={@membership_form}
          id="venture-membership-form"
          phx-submit="save_venture_membership"
          class="mt-3 space-y-3"
        >
          <.input
            field={@membership_form[:member_ref]}
            type="select"
            label="Partner"
            options={venture_member_options(@character_options, @household_options)}
            required
          />
          <.input field={@membership_form[:role]} label="Role" required />
          <.input field={@membership_form[:contribution]} type="textarea" label="Contribution" />
          <.input
            field={@membership_form[:share_percentage]}
            type="number"
            min="0.01"
            max="100"
            step="0.01"
            label="Known share percentage"
          />
          <.input
            field={@membership_form[:status]}
            type="select"
            label="Status"
            options={AncientStones.Worlds.VentureMembership.status_options()}
            required
          />
          <.input field={@membership_form[:description]} type="textarea" label="Terms" />
          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-semibold transition">
            {if @selected_membership, do: "Update partner", else: "Add partner"}
          </.button>
        </.form>
      </div>

      <div class="border-t border-zinc-200 pt-5 dark:border-zinc-700">
        <div class="flex items-center justify-between">
          <h3 class="stone-heading text-xs font-semibold uppercase tracking-wide">Route work</h3>
          <span class="stone-muted text-xs">{@route_link_count}</span>
        </div>
        <div
          id="venture-trade-routes"
          phx-update="stream"
          class="mt-2 divide-y divide-zinc-200 rounded border border-zinc-200 dark:divide-zinc-700 dark:border-zinc-700"
        >
          <p id="venture-trade-routes-empty" class="stone-muted hidden px-3 py-3 text-xs only:block">
            No route role recorded.
          </p>
          <article
            :for={{dom_id, link} <- @route_links}
            id={dom_id}
            class="flex items-start justify-between gap-3 px-3 py-2.5"
          >
            <div>
              <p class="stone-heading text-xs font-semibold">{association_name(link.trade_route)}</p>
              <p class="stone-muted mt-0.5 text-[11px]">{humanize(link.role)}</p>
            </div>
            <div class="flex gap-1">
              <.link
                id={"edit-venture-trade-route-#{link.id}"}
                patch={
                  ~p"/worlds/#{@world}/dashboard?section=economy&mode=venture&commercial_venture_id=#{@venture.id}&venture_trade_route_id=#{link.id}"
                }
                class="stone-button rounded border px-1.5 py-1 text-[10px] font-semibold"
              >Edit</.link>
              <button
                id={"delete-venture-trade-route-#{link.id}"}
                type="button"
                phx-click="delete_economy_record"
                phx-value-kind="venture_trade_route"
                phx-value-id={link.id}
                data-confirm="Remove this route role?"
                class="stone-button rounded border p-1"
                aria-label={"Delete route role for #{association_name(link.trade_route)}"}
              ><.icon name="hero-trash" class="size-3.5" /></button>
            </div>
          </article>
        </div>
        <.form
          for={@route_link_form}
          id="venture-trade-route-form"
          phx-submit="save_venture_trade_route"
          class="mt-3 space-y-3"
        >
          <.input
            field={@route_link_form[:trade_route_id]}
            type="select"
            label="Trade route"
            options={@trade_route_options}
            required
          />
          <.input
            field={@route_link_form[:role]}
            type="select"
            label="Role"
            options={AncientStones.Worlds.VentureTradeRoute.role_options()}
            required
          />
          <.input field={@route_link_form[:description]} type="textarea" label="Work performed" />
          <.button class="stone-button w-full rounded-md border px-3 py-2 text-sm font-semibold transition">
            {if @selected_route_link, do: "Update route role", else: "Add route role"}
          </.button>
        </.form>
      </div>
    </section>
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
          "tax_revenue_share" => "share",
          "hold_economic_profile" => "profile",
          "commodity_balance" => "balance",
          "tax_assessment" => "assessment",
          "commercial_venture" => "venture"
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

  defp modes do
    [
      {"Route", "route"},
      {"Flow", "flow"},
      {"Policy", "policy"},
      {"Exemption", "exemption"},
      {"Share", "share"},
      {"Profile", "profile"},
      {"Balance", "balance"},
      {"Assessment", "assessment"},
      {"Venture", "venture"}
    ]
  end

  defp record_title(assigns) do
    assigns
    |> selected_record()
    |> record_name("New #{assigns.mode}")
  end

  defp record_details(assigns) do
    case selected_record(assigns) do
      nil ->
        %{
          selected?: false,
          description: "Choose a record from the left, or use the form to create one.",
          fields: [],
          sections: []
        }

      record ->
        details_for(assigns.mode, record, assigns)
    end
  end

  defp details_for(:route, route, assigns) do
    flows = Enum.filter(assigns.trade_flows, &(&1.trade_route_id == route.id))

    details(
      route,
      [
        {"Origin", association_name(route.origin_hold)},
        {"Destination", association_name(route.destination_hold)},
        {"Transport", humanize(route.transport_mode)},
        {"Distance", value_with_unit(route.distance_km, "km")},
        {"Seasonality", humanize(route.seasonality)},
        {"Risk", humanize(route.risk)},
        {"Status", humanize(route.status)}
      ],
      [
        related_section(
          "economy-related-trade-flows",
          "Commodity flows",
          Enum.map(flows, &flow_item/1)
        )
      ]
    )
  end

  defp details_for(:flow, flow, assigns) do
    route = Enum.find(assigns.trade_routes, &(&1.id == flow.trade_route_id))

    details(
      flow,
      [
        {"Route", association_name(route)},
        {"Corridor", route_corridor(route)},
        {"Category", humanize(flow.category)},
        {"Quantity", value_with_unit(flow.quantity, flow.unit)},
        {"Declared value", money_value(flow.declared_value, flow.currency)},
        {"Frequency", humanize(flow.frequency)},
        {"Coverage", humanize(flow.coverage_scope)},
        {"Quantity basis", flow.quantity_basis}
      ],
      []
    )
  end

  defp details_for(:policy, policy, assigns) do
    exemptions = Enum.filter(assigns.tax_exemptions, &(&1.tax_policy_id == policy.id))
    shares = Enum.filter(assigns.tax_revenue_shares, &(&1.tax_policy_id == policy.id))

    details(
      policy,
      [
        {"Jurisdiction", jurisdiction_name(policy)},
        {"Tax type", humanize(policy.tax_type)},
        {"Rate", tax_rate(policy)},
        {"Direction", humanize(policy.direction)},
        {"Collector", association_office(policy.collecting_office)},
        {"Currency", association_name(policy.currency)},
        {"Effective from", display(policy.effective_from)},
        {"Effective to", display(policy.effective_to)},
        {"Status", humanize(policy.status)}
      ],
      [
        related_section(
          "economy-related-revenue-shares",
          "Revenue allocation",
          Enum.map(shares, &share_item/1)
        ),
        related_section(
          "economy-related-tax-exemptions",
          "Exemptions",
          Enum.map(exemptions, &exemption_item/1)
        )
      ]
    )
  end

  defp details_for(:exemption, exemption, assigns) do
    policy = Enum.find(assigns.tax_policies, &(&1.id == exemption.tax_policy_id))

    details(
      exemption,
      [
        {"Tax policy", association_name(policy)},
        {"Beneficiary", beneficiary_name(exemption)},
        {"Relief", value_with_unit(exemption.exemption_percentage, "%")},
        {"Effective from", display(exemption.effective_from)},
        {"Effective to", display(exemption.effective_to)}
      ],
      []
    )
  end

  defp details_for(:share, share, assigns) do
    policy = Enum.find(assigns.tax_policies, &(&1.id == share.tax_policy_id))

    details(
      share,
      [
        {"Tax policy", association_name(policy)},
        {"Recipient office", association_office(share.political_office)},
        {"Allocation", value_with_unit(share.percentage, "%")}
      ],
      []
    )
  end

  defp details_for(:profile, profile, _assigns) do
    details(
      profile,
      [
        {"Hold", association_name(profile.hold)},
        {"Province", association_name(profile.hold.province)},
        {"Population estimate", display(profile.population_estimate)},
        {"Household estimate", display(profile.household_estimate)},
        {"Urban population", display(profile.urban_population_estimate)},
        {"Arable land", value_with_unit(profile.arable_hectares_estimate, "ha")},
        {"Pasture", value_with_unit(profile.pasture_hectares_estimate, "ha")},
        {"Staple reserve", value_with_unit(profile.staple_reserve_months, "months")},
        {"Assessment", profile.assessment_label},
        {"Confidence", humanize(profile.confidence)}
      ],
      []
    )
  end

  defp details_for(:balance, balance, _assigns) do
    ordinary_balance = AncientStones.Worlds.CommodityBalance.ordinary_balance(balance)
    bad_year_output = AncientStones.Worlds.CommodityBalance.bad_year_output(balance)

    details(
      balance,
      [
        {"Hold", association_name(balance.hold)},
        {"Province", association_name(balance.hold.province)},
        {"Category", humanize(balance.category)},
        {"Annual output", value_with_unit(balance.annual_output, balance.unit)},
        {"Annual local need", value_with_unit(balance.annual_local_need, balance.unit)},
        {"Ordinary balance", value_with_unit(ordinary_balance, balance.unit)},
        {"Stored reserve", value_with_unit(balance.stored_reserve, balance.unit)},
        {"Bad-year output", value_with_unit(bad_year_output, balance.unit)},
        {"Storage loss", value_with_unit(balance.storage_loss_percentage, "%")},
        {"Status", humanize(balance.status)}
      ],
      []
    )
  end

  defp details_for(:assessment, assessment, _assigns) do
    details(
      assessment,
      [
        {"Tax policy", association_name(assessment.tax_policy)},
        {"Period", assessment.assessment_period_label},
        {"Cash yield", money_value(assessment.cash_yield, assessment.currency)},
        {"In-kind value", money_value(assessment.in_kind_value, assessment.currency)},
        {"Customary labor", value_with_unit(assessment.customary_labor_days, "days")},
        {"Confidence", humanize(assessment.confidence)}
      ],
      []
    )
  end

  defp details_for(:venture, venture, _assigns) do
    details(
      venture,
      [
        {"Form", humanize(venture.venture_type)},
        {"Home place", association_name(venture.home_location)},
        {"Status", humanize(venture.status)},
        {"Purpose", venture.purpose},
        {"Capital and assets", venture.capital_basis},
        {"Formed", venture.formation_label},
        {"Ended", venture.end_label}
      ],
      [
        related_section(
          "economy-related-venture-members",
          "Partners",
          Enum.map(venture.memberships, &venture_membership_item/1)
        ),
        related_section(
          "economy-related-venture-routes",
          "Route work",
          Enum.map(venture.trade_route_links, &venture_trade_route_item/1)
        )
      ]
    )
  end

  defp details(record, fields, sections) do
    %{
      selected?: true,
      description: record_description(record),
      fields: Enum.reject(fields, fn {_label, value} -> value in [nil, ""] end),
      sections: Enum.reject(sections, &(&1.items == []))
    }
  end

  defp related_section(id, title, items) do
    %{id: id, title: title, items: items}
  end

  defp flow_item(flow) do
    %{
      name: flow.commodity,
      meta:
        Enum.join(
          [
            value_with_unit(flow.quantity, flow.unit),
            money_value(flow.declared_value, flow.currency)
          ]
          |> Enum.reject(&is_nil/1),
          " / "
        ),
      description: flow.description
    }
  end

  defp exemption_item(exemption) do
    %{
      name: exemption.name,
      meta: "#{beneficiary_name(exemption)} / #{display(exemption.exemption_percentage)}% relief",
      description: exemption.description
    }
  end

  defp share_item(share) do
    %{
      name: association_office(share.political_office),
      meta: "#{display(share.percentage)}%",
      description: nil
    }
  end

  defp venture_membership_item(membership) do
    %{
      name: venture_member_name(membership),
      meta:
        Enum.join(
          [membership.role, membership_share(membership)] |> Enum.reject(&is_nil/1),
          " / "
        ),
      description: membership.contribution || membership.description
    }
  end

  defp venture_trade_route_item(link) do
    %{
      name: association_name(link.trade_route),
      meta: humanize(link.role),
      description: link.description
    }
  end

  defp selected_record(%{mode: :route} = assigns) do
    assigns.selected_trade_route
  end

  defp selected_record(%{mode: :flow} = assigns) do
    assigns.selected_trade_flow
  end

  defp selected_record(%{mode: :policy} = assigns) do
    assigns.selected_tax_policy
  end

  defp selected_record(%{mode: :exemption} = assigns) do
    assigns.selected_tax_exemption
  end

  defp selected_record(%{mode: :share} = assigns) do
    assigns.selected_tax_revenue_share
  end

  defp selected_record(%{mode: :profile} = assigns) do
    assigns.selected_hold_economic_profile
  end

  defp selected_record(%{mode: :balance} = assigns) do
    assigns.selected_commodity_balance
  end

  defp selected_record(%{mode: :assessment} = assigns) do
    assigns.selected_tax_assessment
  end

  defp selected_record(%{mode: :venture} = assigns) do
    assigns.selected_commercial_venture
  end

  defp record_name(nil, fallback) do
    fallback
  end

  defp record_name(%{commodity: value}, _fallback) when not is_nil(value) do
    value
  end

  defp record_name(%{name: value}, _fallback) when not is_nil(value) do
    value
  end

  defp record_name(%{assessment_period_label: value}, _fallback) when not is_nil(value) do
    value
  end

  defp record_name(%{hold: hold}, _fallback) when not is_nil(hold) do
    association_name(hold)
  end

  defp record_name(%{percentage: value}, _fallback) do
    "#{display(value)}% revenue share"
  end

  defp record_description(%{description: value}) when value not in [nil, ""] do
    value
  end

  defp record_description(_record) do
    "This record has no description yet."
  end

  defp jurisdiction_name(policy) do
    association_name(policy.continent) || association_name(policy.province) ||
      association_name(policy.hold)
  end

  defp beneficiary_name(exemption) do
    association_name(exemption.guild) || association_name(exemption.trade_route) ||
      association_name(exemption.continent) || association_name(exemption.province) ||
      association_name(exemption.hold)
  end

  defp route_corridor(nil) do
    nil
  end

  defp route_corridor(route) do
    Enum.join(
      [association_name(route.origin_hold), association_name(route.destination_hold)]
      |> Enum.reject(&is_nil/1),
      " to "
    )
  end

  defp tax_rate(policy) do
    case policy.rate_basis do
      :percentage -> "#{display(policy.rate)}%"
      basis -> "#{display(policy.rate)} / #{humanize(basis)}"
    end
  end

  defp money_value(nil, _currency) do
    nil
  end

  defp money_value(value, currency) do
    Enum.join([display(value), association_name(currency)] |> Enum.reject(&is_nil/1), " ")
  end

  defp value_with_unit(nil, _unit) do
    nil
  end

  defp value_with_unit(value, unit) do
    Enum.join([display(value), unit] |> Enum.reject(&(&1 in [nil, ""])), " ")
  end

  defp venture_member_options(character_options, household_options) do
    Enum.map(character_options, fn {name, id} ->
      {"Person / #{name}", "character:#{id}"}
    end) ++
      Enum.map(household_options, fn {name, id} ->
        {"Household / #{name}", "household:#{id}"}
      end)
  end

  defp venture_member_name(%{character: character, household: household}) do
    association_name(character) || association_name(household) || "Unidentified partner"
  end

  defp membership_share(%{share_percentage: nil}) do
    nil
  end

  defp membership_share(membership) do
    "#{display(membership.share_percentage)}%"
  end

  defp association_name(nil) do
    nil
  end

  defp association_name(%Ecto.Association.NotLoaded{}) do
    nil
  end

  defp association_name(record) do
    Map.get(record, :name)
  end

  defp association_office(nil) do
    nil
  end

  defp association_office(%Ecto.Association.NotLoaded{}) do
    nil
  end

  defp association_office(record) do
    Map.get(record, :office)
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

  defp display(nil) do
    nil
  end

  defp display(%Decimal{} = value) do
    Decimal.to_string(value, :normal)
  end

  defp display(value) do
    to_string(value)
  end
end
