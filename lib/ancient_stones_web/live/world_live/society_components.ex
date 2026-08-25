defmodule AncientStonesWeb.WorldLive.SocietyComponents do
  use AncientStonesWeb, :html

  attr :world, :any, required: true
  attr :mode, :atom, required: true
  attr :households, :any, required: true
  attr :relationships, :any, required: true
  attr :landholdings, :any, required: true
  attr :selected_household, :any, default: nil
  attr :selected_household_membership, :any, default: nil
  attr :selected_relationship, :any, default: nil
  attr :selected_landholding, :any, default: nil
  attr :household_form, :any, required: true
  attr :household_membership_form, :any, required: true
  attr :relationship_form, :any, required: true
  attr :landholding_form, :any, required: true
  attr :character_options, :list, required: true
  attr :household_member_options, :list, required: true
  attr :household_options, :list, required: true
  attr :location_options, :list, required: true
  attr :geographic_scope_options, :list, required: true

  def society_dashboard(assigns) do
    ~H"""
    <div
      id="society-dashboard"
      class="grid min-h-[800px] gap-4 bg-stone-100 p-4 xl:grid-cols-[320px_minmax(0,1fr)_380px] dark:bg-zinc-900"
    >
      <aside class="overflow-hidden rounded-md border border-stone-200 bg-white dark:border-zinc-700 dark:bg-zinc-950">
        <header class="border-b border-stone-200 px-4 py-3 dark:border-zinc-700">
          <p class="text-[10px] font-semibold uppercase tracking-[0.18em] text-stone-500">
            Social record
          </p>
          <h2 class="stone-heading mt-1 text-sm font-semibold">Household and kindred</h2>
          <p class="stone-muted mt-1 text-xs leading-5">
            Residence, dependency, kinship, fosterage, and rights of use
          </p>
        </header>

        <nav
          id="society-mode-navigation"
          class="grid grid-cols-3 gap-1 border-b border-stone-200 p-2 dark:border-zinc-700"
        >
          <.mode_link world={@world} mode={:household} current={@mode} label="Households" />
          <.mode_link world={@world} mode={:relationship} current={@mode} label="Ties" />
          <.mode_link world={@world} mode={:holding} current={@mode} label="Tenure" />
        </nav>

        <div class="max-h-[720px] overflow-y-auto p-2">
          <%= case @mode do %>
            <% :household -> %>
              <div id="society-households" phx-update="stream" class="space-y-1.5">
                <p
                  id="society-households-empty"
                  class="stone-muted hidden only:block px-3 py-8 text-center text-sm"
                >
                  No households recorded.
                </p>
                <.link
                  :for={{dom_id, household} <- @households}
                  id={dom_id}
                  patch={
                    ~p"/worlds/#{@world}/dashboard?section=society&mode=household&household_id=#{household.id}"
                  }
                  class={[
                    "block rounded border px-3 py-2.5 transition",
                    selected?(@selected_household, household) &&
                      "border-amber-500 bg-amber-50 dark:border-amber-600 dark:bg-amber-950/30",
                    !selected?(@selected_household, household) &&
                      "border-transparent hover:border-stone-200 hover:bg-stone-50 dark:hover:border-zinc-700 dark:hover:bg-zinc-900"
                  ]}
                >
                  <span class="stone-heading block text-sm font-semibold">{household.name}</span>
                  <span class="stone-muted mt-0.5 block text-xs">
                    {household_meta(household)}
                  </span>
                </.link>
              </div>
            <% :relationship -> %>
              <div id="society-relationships" phx-update="stream" class="space-y-1.5">
                <p
                  id="society-relationships-empty"
                  class="stone-muted hidden only:block px-3 py-8 text-center text-sm"
                >
                  No personal ties recorded.
                </p>
                <.link
                  :for={{dom_id, relationship} <- @relationships}
                  id={dom_id}
                  patch={
                    ~p"/worlds/#{@world}/dashboard?section=society&mode=relationship&relationship_id=#{relationship.id}"
                  }
                  class={[
                    "block rounded border px-3 py-2.5 transition",
                    selected?(@selected_relationship, relationship) &&
                      "border-amber-500 bg-amber-50 dark:border-amber-600 dark:bg-amber-950/30",
                    !selected?(@selected_relationship, relationship) &&
                      "border-transparent hover:border-stone-200 hover:bg-stone-50 dark:hover:border-zinc-700 dark:hover:bg-zinc-900"
                  ]}
                >
                  <span class="stone-heading block text-sm font-semibold">
                    {relationship.character_a.name} and {relationship.character_b.name}
                  </span>
                  <span class="stone-muted mt-0.5 block text-xs">
                    {humanize(relationship.relationship_type)}
                  </span>
                </.link>
              </div>
            <% :holding -> %>
              <div id="society-landholdings" phx-update="stream" class="space-y-1.5">
                <p
                  id="society-landholdings-empty"
                  class="stone-muted hidden only:block px-3 py-8 text-center text-sm"
                >
                  No tenure or use rights recorded.
                </p>
                <.link
                  :for={{dom_id, holding} <- @landholdings}
                  id={dom_id}
                  patch={
                    ~p"/worlds/#{@world}/dashboard?section=society&mode=holding&landholding_id=#{holding.id}"
                  }
                  class={[
                    "block rounded border px-3 py-2.5 transition",
                    selected?(@selected_landholding, holding) &&
                      "border-amber-500 bg-amber-50 dark:border-amber-600 dark:bg-amber-950/30",
                    !selected?(@selected_landholding, holding) &&
                      "border-transparent hover:border-stone-200 hover:bg-stone-50 dark:hover:border-zinc-700 dark:hover:bg-zinc-900"
                  ]}
                >
                  <span class="stone-heading block text-sm font-semibold">{holding.name}</span>
                  <span class="stone-muted mt-0.5 block text-xs">
                    {holding.household.name} · {humanize(holding.tenure_type)}
                  </span>
                </.link>
              </div>
          <% end %>
        </div>
      </aside>

      <main class="rounded-md border border-stone-200 bg-white p-5 dark:border-zinc-700 dark:bg-zinc-950">
        <.record_details
          mode={@mode}
          household={@selected_household}
          selected_membership={@selected_household_membership}
          membership_form={@household_membership_form}
          membership_character_options={@household_member_options}
          world={@world}
          relationship={@selected_relationship}
          landholding={@selected_landholding}
        />
      </main>

      <aside class="overflow-hidden rounded-md border border-stone-200 bg-white dark:border-zinc-700 dark:bg-zinc-950">
        <header class="border-b border-stone-200 px-4 py-3 dark:border-zinc-700">
          <h2 class="stone-heading text-sm font-semibold">Properties</h2>
          <p class="stone-muted mt-1 text-xs">Blank fields remain unknown, not assumed.</p>
        </header>
        <div id="society-properties" class="max-h-[750px] overflow-y-auto p-4">
          <%= case @mode do %>
            <% :household -> %>
              <.form
                for={@household_form}
                id="society-household-form"
                phx-submit="save_household"
                class="space-y-3"
              >
                <.input field={@household_form[:name]} label="Recorded name" required />
                <.input
                  field={@household_form[:household_type]}
                  type="select"
                  label="Household character"
                  options={AncientStones.Worlds.Household.household_type_options()}
                  required
                />
                <.input
                  field={@household_form[:status]}
                  type="select"
                  label="Status"
                  options={AncientStones.Worlds.Household.status_options()}
                  required
                />
                <.input
                  field={@household_form[:home_location_id]}
                  type="select"
                  label="Usual residence"
                  prompt="Not located"
                  options={@location_options}
                />
                <.input
                  :if={is_nil(@selected_household)}
                  field={@household_form[:head_character_id]}
                  type="select"
                  label="Initial household head"
                  prompt="Not recorded"
                  options={@character_options}
                />
                <.input
                  field={@household_form[:description]}
                  type="textarea"
                  label="Composition and means"
                />
                <.form_actions
                  world={@world}
                  mode={@mode}
                  selected={@selected_household}
                  kind="household"
                />
              </.form>
            <% :relationship -> %>
              <.form
                for={@relationship_form}
                id="society-relationship-form"
                phx-submit="save_character_relationship"
                class="space-y-3"
              >
                <.input
                  field={@relationship_form[:character_a_id]}
                  type="select"
                  label="First person"
                  options={@character_options}
                  required
                />
                <.input
                  field={@relationship_form[:character_b_id]}
                  type="select"
                  label="Second person"
                  options={@character_options}
                  required
                />
                <.input
                  field={@relationship_form[:relationship_type]}
                  type="select"
                  label="Tie"
                  options={AncientStones.Worlds.CharacterRelationship.relationship_type_options()}
                  required
                />
                <div class="grid grid-cols-2 gap-3">
                  <.input field={@relationship_form[:character_a_role]} label="First role" />
                  <.input field={@relationship_form[:character_b_role]} label="Second role" />
                </div>
                <.input
                  field={@relationship_form[:status]}
                  type="select"
                  label="Status"
                  options={AncientStones.Worlds.CharacterRelationship.status_options()}
                  required
                />
                <div class="grid grid-cols-2 gap-3">
                  <.input field={@relationship_form[:start_date_label]} label="Began" />
                  <.input field={@relationship_form[:end_date_label]} label="Ended" />
                </div>
                <.input field={@relationship_form[:description]} type="textarea" label="Context" />
                <.form_actions
                  world={@world}
                  mode={@mode}
                  selected={@selected_relationship}
                  kind="relationship"
                />
              </.form>
            <% :holding -> %>
              <.form
                for={@landholding_form}
                id="society-landholding-form"
                phx-submit="save_landholding"
                class="space-y-3"
              >
                <.input
                  field={@landholding_form[:household_id]}
                  type="select"
                  label="Household"
                  options={@household_options}
                  required
                />
                <.input field={@landholding_form[:name]} label="Recorded holding or right" required />
                <.input
                  field={@landholding_form[:geographic_scope]}
                  type="select"
                  label="Geographic scope"
                  options={@geographic_scope_options}
                  required
                />
                <.input
                  field={@landholding_form[:tenure_type]}
                  type="select"
                  label="Tenure or use right"
                  options={AncientStones.Worlds.Landholding.tenure_type_options()}
                  required
                />
                <.input
                  field={@landholding_form[:primary_use]}
                  type="select"
                  label="Principal use"
                  options={AncientStones.Worlds.Landholding.primary_use_options()}
                  required
                />
                <.input
                  field={@landholding_form[:size_hectares]}
                  type="number"
                  step="any"
                  label="Approximate hectares"
                />
                <.input
                  field={@landholding_form[:status]}
                  type="select"
                  label="Status"
                  options={AncientStones.Worlds.Landholding.status_options()}
                  required
                />
                <.input
                  field={@landholding_form[:description]}
                  type="textarea"
                  label="Rights and obligations"
                />
                <.form_actions
                  world={@world}
                  mode={@mode}
                  selected={@selected_landholding}
                  kind="landholding"
                />
              </.form>
          <% end %>
        </div>
      </aside>
    </div>
    """
  end

  attr :world, :any, required: true
  attr :mode, :atom, required: true
  attr :current, :atom, required: true
  attr :label, :string, required: true

  defp mode_link(assigns) do
    ~H"""
    <.link
      patch={~p"/worlds/#{@world}/dashboard?section=society&mode=#{@mode}"}
      class={[
        "rounded px-2 py-1.5 text-center text-[11px] font-semibold transition",
        @current == @mode && "bg-stone-800 text-white dark:bg-stone-200 dark:text-stone-900",
        @current != @mode && "stone-muted hover:bg-stone-100 dark:hover:bg-zinc-800"
      ]}
    >
      {@label}
    </.link>
    """
  end

  attr :mode, :atom, required: true
  attr :household, :any, default: nil
  attr :selected_membership, :any, default: nil
  attr :membership_form, :any, required: true
  attr :membership_character_options, :list, required: true
  attr :world, :any, required: true
  attr :relationship, :any, default: nil
  attr :landholding, :any, default: nil

  defp record_details(%{mode: :household} = assigns) do
    ~H"""
    <div id="society-record-details">
      <.details_header eyebrow="Household" title={record_name(@household, "No household selected")} />
      <%= if @household do %>
        <p class="stone-muted mt-5 max-w-3xl text-sm leading-6">
          {@household.description || "Composition and means have not been recorded."}
        </p>
        <.fact_grid facts={[
          {"Character", humanize(@household.household_type)},
          {"Usual residence", record_name(@household.home_location, "Not located")},
          {"Status", humanize(@household.status)},
          {"Recorded members", length(@household.memberships)}
        ]} />
        <.membership_list
          memberships={@household.memberships}
          household={@household}
          world={@world}
        />
        <.membership_form
          household={@household}
          membership={@selected_membership}
          form={@membership_form}
          character_options={@membership_character_options}
          world={@world}
        />
        <.holding_list holdings={@household.landholdings} />
      <% else %>
        <.empty_details text="Select a household or record one. A household may include kin, servants, dependents, fosterlings, and hired laborers sharing one economic unit." />
      <% end %>
    </div>
    """
  end

  defp record_details(%{mode: :relationship} = assigns) do
    ~H"""
    <div id="society-record-details">
      <.details_header
        eyebrow="Personal tie"
        title={relationship_name(@relationship, "No relationship selected")}
      />
      <%= if @relationship do %>
        <p class="stone-muted mt-5 max-w-3xl text-sm leading-6">
          {@relationship.description || "No further context has been recorded."}
        </p>
        <.fact_grid facts={[
          {"Tie", humanize(@relationship.relationship_type)},
          {"First role", @relationship.character_a_role || "Not specified"},
          {"Second role", @relationship.character_b_role || "Not specified"},
          {"Status", humanize(@relationship.status)},
          {"Began", @relationship.start_date_label || "Unknown"},
          {"Ended", @relationship.end_date_label || "Not recorded"}
        ]} />
      <% else %>
        <.empty_details text="Record biological kinship separately from marriage, fosterage, guardianship, and partnership. Social kinship can matter as much as descent." />
      <% end %>
    </div>
    """
  end

  defp record_details(%{mode: :holding} = assigns) do
    ~H"""
    <div id="society-record-details">
      <.details_header
        eyebrow="Tenure and use"
        title={record_name(@landholding, "No holding selected")}
      />
      <%= if @landholding do %>
        <p class="stone-muted mt-5 max-w-3xl text-sm leading-6">
          {@landholding.description || "Rights and attached obligations have not been recorded."}
        </p>
        <.fact_grid facts={[
          {"Household", @landholding.household.name},
          {"Place", holding_place(@landholding)},
          {"Tenure", tenure_label(@landholding.tenure_type)},
          {"Principal use", humanize(@landholding.primary_use)},
          {"Approximate area", area_label(@landholding.size_hectares)},
          {"Status", humanize(@landholding.status)}
        ]} />
        <p class="mt-5 rounded border border-amber-200 bg-amber-50 px-3 py-2 text-xs leading-5 text-amber-900 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-200">
          Tenure records a recognized claim or use right. It does not automatically mean unrestricted private ownership.
        </p>
      <% else %>
        <.empty_details text="Record land, pasture, woodland, fishing, and workshop rights with the tenure actually recognized by neighbors and authorities." />
      <% end %>
    </div>
    """
  end

  attr :eyebrow, :string, required: true
  attr :title, :string, required: true

  defp details_header(assigns) do
    ~H"""
    <header class="border-b border-stone-200 pb-4 dark:border-zinc-700">
      <p class="text-[10px] font-semibold uppercase tracking-[0.18em] text-stone-500">{@eyebrow}</p>
      <h2 class="stone-heading mt-1 text-xl font-semibold">{@title}</h2>
    </header>
    """
  end

  attr :facts, :list, required: true

  defp fact_grid(assigns) do
    ~H"""
    <dl class="mt-5 grid gap-px overflow-hidden rounded border border-stone-200 bg-stone-200 sm:grid-cols-2 dark:border-zinc-700 dark:bg-zinc-700">
      <div :for={{label, value} <- @facts} class="bg-stone-50 px-3 py-2.5 dark:bg-zinc-900">
        <dt class="text-[10px] font-semibold uppercase tracking-wider text-stone-500">{label}</dt>
        <dd class="stone-heading mt-1 text-sm font-medium">{value}</dd>
      </div>
    </dl>
    """
  end

  attr :memberships, :list, required: true
  attr :household, :any, required: true
  attr :world, :any, required: true

  defp membership_list(assigns) do
    ~H"""
    <section
      id="society-household-members"
      class="mt-6 rounded border border-stone-200 dark:border-zinc-700"
    >
      <header class="border-b border-stone-200 bg-stone-50 px-3 py-2 dark:border-zinc-700 dark:bg-zinc-900">
        <h3 class="stone-heading text-xs font-semibold uppercase tracking-wide">
          People of the household
        </h3>
      </header>
      <p :if={@memberships == []} class="stone-muted px-3 py-4 text-sm">No members recorded.</p>
      <article
        :for={membership <- @memberships}
        id={"household-membership-#{membership.id}"}
        class="flex items-start justify-between gap-4 border-b border-stone-100 px-3 py-3 last:border-b-0 dark:border-zinc-800"
      >
        <div>
          <h4 class="stone-heading text-sm font-semibold">{membership.character.name}</h4>
          <p :if={membership.description not in [nil, ""]} class="stone-muted mt-1 text-xs leading-5">
            {membership.description}
          </p>
        </div>
        <div class="flex items-start gap-3 text-right">
          <div>
            <span class="stone-muted text-xs">{humanize(membership.role)}</span>
            <span
              :if={membership.is_primary}
              class="mt-1 block text-[10px] font-semibold uppercase text-amber-700"
            >
              Primary home
            </span>
          </div>
          <div class="flex gap-1">
            <.link
              id={"edit-household-membership-#{membership.id}"}
              patch={
                ~p"/worlds/#{@world}/dashboard?section=society&mode=household&household_id=#{@household.id}&membership_id=#{membership.id}"
              }
              class="stone-text rounded px-1.5 py-1 text-[10px] font-semibold hover:bg-stone-100 dark:hover:bg-zinc-800"
            >
              Edit
            </.link>
            <button
              id={"delete-household-membership-#{membership.id}"}
              type="button"
              phx-click="delete_household_membership"
              phx-value-id={membership.id}
              data-confirm="Remove this person from the household record?"
              class="rounded px-1.5 py-1 text-[10px] font-semibold text-red-700 hover:bg-red-50 dark:text-red-300 dark:hover:bg-red-950/30"
            >
              Remove
            </button>
          </div>
        </div>
      </article>
    </section>
    """
  end

  attr :household, :any, required: true
  attr :membership, :any, default: nil
  attr :form, :any, required: true
  attr :character_options, :list, required: true
  attr :world, :any, required: true

  defp membership_form(assigns) do
    ~H"""
    <section
      id="household-membership-editor"
      class="mt-4 rounded border border-stone-200 bg-stone-50 p-3 dark:border-zinc-700 dark:bg-zinc-900"
    >
      <div class="mb-3 flex items-center justify-between gap-3">
        <h3 class="stone-heading text-xs font-semibold uppercase tracking-wide">
          {if(@membership, do: "Edit household member", else: "Add household member")}
        </h3>
        <.link
          :if={@membership}
          id="cancel-household-membership-edit"
          patch={
            ~p"/worlds/#{@world}/dashboard?section=society&mode=household&household_id=#{@household.id}"
          }
          class="stone-text text-xs font-semibold"
        >
          Cancel
        </.link>
      </div>
      <.form
        for={@form}
        id="household-membership-form"
        phx-submit="save_household_membership"
        class="space-y-3"
      >
        <%= if @membership do %>
          <.input field={@form[:character_id]} type="hidden" />
          <p id="household-membership-person" class="stone-muted text-sm">
            Person: <span class="stone-heading font-semibold">{@membership.character.name}</span>
          </p>
        <% else %>
          <.input
            field={@form[:character_id]}
            type="select"
            label="Person"
            prompt="Select a person"
            options={@character_options}
            required
          />
        <% end %>
        <div class="grid gap-3 sm:grid-cols-2">
          <.input
            field={@form[:role]}
            type="select"
            label="Place in household"
            options={AncientStones.Worlds.HouseholdMembership.role_options()}
            required
          />
          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={AncientStones.Worlds.HouseholdMembership.status_options()}
            required
          />
        </div>
        <.input field={@form[:is_primary]} type="checkbox" label="Usual household" />
        <.input field={@form[:description]} type="textarea" label="Notes" />
        <button
          id="save-household-membership"
          type="submit"
          class="stone-button w-full rounded px-3 py-2 text-sm font-semibold transition"
        >
          {if(@membership, do: "Update member", else: "Add member")}
        </button>
      </.form>
    </section>
    """
  end

  attr :holdings, :list, required: true

  defp holding_list(assigns) do
    ~H"""
    <section
      id="society-household-holdings"
      class="mt-6 rounded border border-stone-200 dark:border-zinc-700"
    >
      <header class="border-b border-stone-200 bg-stone-50 px-3 py-2 dark:border-zinc-700 dark:bg-zinc-900">
        <h3 class="stone-heading text-xs font-semibold uppercase tracking-wide">
          Tenure and use rights
        </h3>
      </header>
      <p :if={@holdings == []} class="stone-muted px-3 py-4 text-sm">No rights recorded.</p>
      <article
        :for={holding <- @holdings}
        id={"household-landholding-#{holding.id}"}
        class="flex items-baseline justify-between gap-4 border-b border-stone-100 px-3 py-3 last:border-b-0 dark:border-zinc-800"
      >
        <div>
          <h4 class="stone-heading text-sm font-semibold">{holding.name}</h4>
          <p class="stone-muted mt-0.5 text-xs">{holding_place(holding)}</p>
        </div>
        <span class="stone-muted text-xs">{tenure_label(holding.tenure_type)}</span>
      </article>
    </section>
    """
  end

  attr :text, :string, required: true

  defp empty_details(assigns) do
    ~H"""
    <p class="stone-muted mt-5 max-w-2xl text-sm leading-6">{@text}</p>
    """
  end

  attr :world, :any, required: true
  attr :mode, :atom, required: true
  attr :selected, :any, default: nil
  attr :kind, :string, required: true

  defp form_actions(assigns) do
    ~H"""
    <div class="flex gap-2 pt-2">
      <.button class="stone-button flex-1 rounded border px-3 py-2 text-sm font-semibold transition">
        {if @selected, do: "Save changes", else: "Create record"}
      </.button>
      <.link
        :if={@selected}
        patch={~p"/worlds/#{@world}/dashboard?section=society&mode=#{@mode}"}
        class="stone-button rounded border px-3 py-2 text-sm font-semibold transition"
      >
        New
      </.link>
      <button
        :if={@selected}
        id={"delete-society-#{@kind}-#{@selected.id}"}
        type="button"
        phx-click="delete_society_record"
        phx-value-kind={@kind}
        phx-value-id={@selected.id}
        data-confirm="Delete this record?"
        class="rounded border border-red-200 px-3 py-2 text-sm font-semibold text-red-700 transition hover:bg-red-50 dark:border-red-900 dark:text-red-300 dark:hover:bg-red-950/30"
      >
        Delete
      </button>
    </div>
    """
  end

  defp selected?(%{id: id}, %{id: id}), do: true
  defp selected?(_selected, _record), do: false

  defp record_name(nil, fallback), do: fallback
  defp record_name(record, _fallback), do: record.name

  defp relationship_name(nil, fallback), do: fallback

  defp relationship_name(relationship, _fallback) do
    "#{relationship.character_a.name} and #{relationship.character_b.name}"
  end

  defp household_meta(household) do
    residence = record_name(household.home_location, "Unlocated")
    "#{residence} · #{length(household.memberships)} recorded"
  end

  defp holding_place(%{location: %{name: name}}), do: name
  defp holding_place(%{hold: %{name: name}}), do: name
  defp holding_place(_holding), do: "Unlocated"

  defp tenure_label(:allodial), do: "Allodial (odal)"
  defp tenure_label(:communal_right), do: "Communal use right"
  defp tenure_label(value), do: humanize(value)

  defp area_label(nil), do: "Not estimated"
  defp area_label(area), do: "#{area} ha"

  defp humanize(nil), do: "Unknown"

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
