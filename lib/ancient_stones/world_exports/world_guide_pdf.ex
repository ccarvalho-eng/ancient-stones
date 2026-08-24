defmodule AncientStones.WorldExports.WorldGuidePdf do
  @page_width 595
  @page_height 842
  @margin 52
  @top 765
  @bottom 52
  @content_width @page_width - @margin * 2
  @parchment {236, 226, 199}
  @parchment_shadow {222, 208, 174}
  @ink {35, 40, 36}
  @rule {174, 149, 105}

  def render(guide) do
    Pdf.build([size: :a4, compress: true], fn pdf ->
      state =
        pdf
        |> Pdf.set_info(
          title: "#{guide.world.name} World Guide",
          author: "Ancient Stones",
          creator: "Ancient Stones",
          subject: "World atlas and gazetteer"
        )
        |> cover(guide)
        |> content_page("World at a glance")
        |> overview(guide)
        |> geography(guide.continents)
        |> directory("People", guide.characters)
        |> directory("Guilds", guide.guilds)
        |> economy(guide.trade_routes, guide.tax_policies)

      Pdf.export(state.pdf)
    end)
  end

  defp cover(pdf, guide) do
    galaxy_name = Map.get(guide.world, :galaxy_name) || "Galaxy not recorded"
    star_name = Map.get(guide.world, :primary_star_name) || "Primary star not recorded"

    pdf
    |> page_background()
    |> Pdf.set_fill_color(@ink)
    |> Pdf.rectangle({0, 0}, {@page_width, @page_height})
    |> Pdf.fill()
    |> Pdf.set_stroke_color(@rule)
    |> Pdf.set_line_width(2)
    |> Pdf.rectangle({34, 34}, {@page_width - 68, @page_height - 68})
    |> Pdf.stroke()
    |> Pdf.set_line_width(0.7)
    |> Pdf.rectangle({43, 43}, {@page_width - 86, @page_height - 86})
    |> Pdf.stroke()
    |> cover_corner_marks()
    |> Pdf.set_fill_color(@parchment)
    |> Pdf.set_font("Helvetica", size: 11, bold: true)
    |> Pdf.text_wrap!(
      {@margin, 716},
      {@content_width, 24},
      "ANCIENT STONES / NORTHERN ARCHIVE",
      align: :center
    )
    |> cover_weave(684)
    |> Pdf.set_font("Helvetica", size: 34, bold: true)
    |> Pdf.text_wrap!({@margin, 574}, {@content_width, 110}, normalize(guide.world.name),
      align: :center
    )
    |> Pdf.set_fill_color(@rule)
    |> Pdf.set_font("Helvetica", size: 13)
    |> Pdf.text_wrap!(
      {@margin, 510},
      {@content_width, 28},
      "ATLAS / GAZETTEER / CHRONICLE",
      align: :center
    )
    |> Pdf.set_fill_color(@parchment)
    |> Pdf.set_font("Helvetica", size: 10, bold: true)
    |> Pdf.text_wrap!(
      {@margin, 463},
      {@content_width, 22},
      normalize("GALAXY / #{galaxy_name}"),
      align: :center
    )
    |> Pdf.text_wrap!(
      {@margin, 440},
      {@content_width, 22},
      normalize("PRIMARY STAR / #{star_name}"),
      align: :center
    )
    |> Pdf.set_fill_color(@parchment)
    |> Pdf.set_font("Helvetica", size: 11)
    |> Pdf.text_wrap!(
      {@margin + 45, 302},
      {@content_width - 90, 125},
      normalize(
        guide.world.description || "A living record of lands, peoples, powers, and trade."
      ),
      align: :center
    )
    |> cover_weave(230)

    %{pdf: pdf, y: @top, page: 1, running_title: guide.world.name}
  end

  defp overview(state, guide) do
    province_count = Enum.sum(Enum.map(guide.continents, &length(&1.provinces)))

    hold_count =
      guide.continents
      |> Enum.flat_map(& &1.provinces)
      |> Enum.sum_by(&length(&1.holds))

    location_count =
      guide.continents
      |> Enum.flat_map(& &1.provinces)
      |> Enum.flat_map(& &1.holds)
      |> Enum.sum_by(&length(&1.locations))

    trade_flow_count = Enum.sum_by(guide.trade_routes, &length(&1.flows))
    exemption_count = Enum.sum_by(guide.tax_policies, &length(&1.exemptions))

    state
    |> heading(guide.world.name, 25)
    |> paragraph(guide.world.description || "No world description has been recorded.")
    |> fact_table("Celestial and physical record", world_facts(guide.world))
    |> fact_table("Recorded holdings", [
      {"Continents", length(guide.continents)},
      {"Provinces", province_count},
      {"Holds", hold_count},
      {"Named locations", location_count},
      {"Characters", length(guide.characters)},
      {"Guilds", length(guide.guilds)},
      {"Trade routes", length(guide.trade_routes)},
      {"Commodity flows", trade_flow_count},
      {"Tax policies", length(guide.tax_policies)},
      {"Tax exemptions", exemption_count}
    ])
  end

  defp geography(state, []) do
    state
    |> content_page("Atlas")
    |> heading("Atlas", 24)
    |> paragraph("No continents have been recorded.")
  end

  defp geography(state, continents) do
    Enum.reduce(continents, state, fn continent, acc ->
      acc
      |> content_page("Atlas - #{continent.name}")
      |> heading(continent.name, 25)
      |> paragraph(continent.description)
      |> calendar(continent.calendar)
      |> offices(continent.offices)
      |> provinces(continent.provinces)
    end)
  end

  defp calendar(state, nil) do
    state
  end

  defp calendar(state, calendar) do
    weekday_names = Enum.join(calendar.weekday_names, ", ")

    state
    |> subheading("Calendar - #{calendar.name}")
    |> fact_table(nil, [
      {"Days per week", calendar.days_per_week},
      {"Weekday names", if(weekday_names == "", do: "Not recorded", else: weekday_names)}
    ])
  end

  defp provinces(state, provinces) do
    Enum.reduce(provinces, state, fn province, acc ->
      acc
      |> subheading(province.name)
      |> paragraph(province.description)
      |> offices(province.offices)
      |> holds(province.holds)
    end)
  end

  defp holds(state, holds) do
    Enum.reduce(holds, state, fn hold, acc ->
      acc
      |> minor_heading(hold.name)
      |> paragraph(hold.description)
      |> offices(hold.offices)
      |> entity_table("Commerce", hold.commerce)
      |> entity_table("Locations", hold.locations)
    end)
  end

  defp offices(state, []) do
    state
  end

  defp offices(state, offices) do
    entries =
      Enum.map(offices, fn office ->
        %{name: office.name, detail: office.holder || "Vacant", description: nil}
      end)

    entity_table(state, "Offices", entries)
  end

  defp entity_table(state, _label, []) do
    state
  end

  defp entity_table(state, label, entries) do
    state =
      state
      |> ensure_space(70)
      |> subheading(label)

    result =
      entries
      |> Enum.with_index()
      |> Enum.reduce(state, fn {entry, index}, acc ->
        detail =
          [Map.get(entry, :detail), Map.get(entry, :description)]
          |> Enum.reject(&blank?/1)
          |> Enum.join(" / ")

        table_row(acc, entry.name, detail, index)
      end)

    table_spacing(result)
  end

  defp directory(state, title, entries) do
    state =
      state
      |> content_page(title)
      |> heading(title, 25)

    if entries == [] do
      paragraph(state, "No #{String.downcase(title)} have been recorded.")
    else
      Enum.reduce(entries, state, fn entry, acc ->
        acc
        |> minor_heading(entry.name)
        |> paragraph(entry.description)
      end)
    end
  end

  defp economy(state, routes, policies) do
    state
    |> content_page("Trade and taxation")
    |> heading("Trade and taxation", 25)
    |> subheading("Trade routes")
    |> routes(routes)
    |> subheading("Tax policies")
    |> policies(policies)
  end

  defp routes(state, []) do
    paragraph(state, "No trade routes have been recorded.")
  end

  defp routes(state, routes) do
    Enum.reduce(routes, state, fn route, acc ->
      acc
      |> minor_heading(route.name)
      |> paragraph(route.detail)
      |> paragraph(route.description)
      |> entity_table("Commodity flows", route.flows)
    end)
  end

  defp policies(state, []) do
    paragraph(state, "No tax policies have been recorded.")
  end

  defp policies(state, policies) do
    Enum.reduce(policies, state, fn policy, acc ->
      acc
      |> minor_heading(policy.name)
      |> paragraph(policy.detail)
      |> paragraph(policy.description)
      |> entity_table("Revenue allocation", policy.revenue_shares)
      |> entity_table("Exemptions", policy.exemptions)
    end)
  end

  defp content_page(state_or_pdf, title) do
    {pdf, page} =
      case state_or_pdf do
        %{pdf: pdf, page: page} -> {Pdf.add_page(pdf), page + 1}
        pdf when is_pid(pdf) -> {Pdf.add_page(pdf), 2}
      end

    pdf =
      pdf
      |> page_background()
      |> Pdf.set_fill_color(@ink)
      |> Pdf.rectangle({0, @page_height - 38}, {@page_width, 38})
      |> Pdf.fill()
      |> Pdf.set_fill_color(@rule)
      |> Pdf.rectangle({0, @page_height - 41}, {@page_width, 3})
      |> Pdf.fill()
      |> Pdf.set_fill_color(@parchment)
      |> Pdf.set_font("Helvetica", size: 9, bold: true)
      |> Pdf.text_at({@margin, @page_height - 25}, normalize(String.upcase(title)))
      |> Pdf.set_fill_color(@ink)
      |> Pdf.set_font("Helvetica", size: 8)
      |> Pdf.text_at({@page_width - @margin - 20, 28}, Integer.to_string(page))

    %{pdf: pdf, y: @top, page: page, running_title: title}
  end

  defp page_background(pdf) do
    pdf
    |> Pdf.set_fill_color(@parchment)
    |> Pdf.rectangle({0, 0}, {@page_width, @page_height})
    |> Pdf.fill()
    |> Pdf.set_stroke_color(@parchment_shadow)
    |> Pdf.set_line_width(0.5)
    |> Pdf.rectangle({24, 24}, {@page_width - 48, @page_height - 48})
    |> Pdf.stroke()
  end

  defp heading(state, text, size) do
    state
    |> ensure_space(size + 24)
    |> draw_lines(text, size, size + 5, @ink, true)
    |> rule()
  end

  defp subheading(state, text) do
    state
    |> ensure_space(34)
    |> draw_lines(String.upcase(normalize(text)), 13, 18, @ink, true)
  end

  defp minor_heading(state, text) do
    state
    |> ensure_space(26)
    |> draw_lines(text, 11, 15, @ink, true)
  end

  defp paragraph(state, text) do
    if blank?(text) do
      state
    else
      draw_lines(state, text, 9, 13, @ink, false)
    end
  end

  defp rule(state) do
    state = ensure_space(state, 13)
    center = @page_width / 2

    pdf =
      state.pdf
      |> Pdf.set_stroke_color(@rule)
      |> Pdf.set_line_width(0.7)
      |> Pdf.line({@margin, state.y}, {center - 14, state.y})
      |> Pdf.line({center - 14, state.y}, {center - 7, state.y + 5})
      |> Pdf.line({center - 7, state.y + 5}, {center, state.y})
      |> Pdf.line({center, state.y}, {center + 7, state.y + 5})
      |> Pdf.line({center + 7, state.y + 5}, {center + 14, state.y})
      |> Pdf.line({center + 14, state.y}, {@page_width - @margin, state.y})
      |> Pdf.stroke()

    %{state | pdf: pdf, y: state.y - 13}
  end

  defp draw_lines(state, text, font_size, leading, color, bold, indent \\ 0) do
    lines = wrap(normalize(text), max_chars(font_size, indent))
    needed = max(length(lines), 1) * leading + 7
    state = ensure_space(state, needed)

    pdf =
      state.pdf
      |> Pdf.set_fill_color(color)
      |> Pdf.set_font("Helvetica", size: font_size, bold: bold)

    pdf =
      lines
      |> Enum.with_index()
      |> Enum.reduce(pdf, fn {line, index}, document ->
        Pdf.text_at(document, {@margin + indent, state.y - index * leading}, line)
      end)

    %{state | pdf: pdf, y: state.y - needed}
  end

  defp fact_table(state, nil, rows) do
    result =
      rows
      |> Enum.reject(fn {_label, value} -> blank?(value) end)
      |> Enum.with_index()
      |> Enum.reduce(state, fn {{label, value}, index}, acc ->
        table_row(acc, label, value, index)
      end)

    table_spacing(result)
  end

  defp fact_table(state, title, rows) do
    state
    |> ensure_space(70)
    |> subheading(title)
    |> fact_table(nil, rows)
  end

  defp table_row(state, label, value, index) do
    label_width = 146
    gap = 14
    value_width = @content_width - label_width - gap
    label_lines = wrap(normalize(label), max_chars_for_width(label_width, 9))
    value_lines = wrap(normalize(value), max_chars_for_width(value_width, 8.5))
    line_count = max(length(label_lines), length(value_lines))
    height = max(line_count, 1) * 12 + 10
    state = ensure_space(state, height)
    row_bottom = state.y - height + 5

    pdf =
      state.pdf
      |> maybe_fill_table_row(index, row_bottom, height)
      |> Pdf.set_stroke_color(@rule)
      |> Pdf.set_line_width(0.35)
      |> Pdf.line({@margin, row_bottom}, {@page_width - @margin, row_bottom})
      |> Pdf.stroke()
      |> draw_table_lines(label_lines, @margin + 6, state.y - 8, true)
      |> draw_table_lines(value_lines, @margin + label_width + gap, state.y - 8, false)

    %{state | pdf: pdf, y: row_bottom}
  end

  defp maybe_fill_table_row(pdf, index, row_bottom, height) do
    if rem(index, 2) == 0 do
      pdf
      |> Pdf.set_fill_color(@parchment_shadow)
      |> Pdf.rectangle({@margin, row_bottom}, {@content_width, height})
      |> Pdf.fill()
    else
      pdf
    end
  end

  defp draw_table_lines(pdf, lines, x, y, bold) do
    font_size = if bold, do: 9, else: 8.5

    pdf =
      pdf
      |> Pdf.set_fill_color(@ink)
      |> Pdf.set_font("Helvetica", size: font_size, bold: bold)

    lines
    |> Enum.with_index()
    |> Enum.reduce(pdf, fn {line, index}, document ->
      Pdf.text_at(document, {x, y - index * 12}, line)
    end)
  end

  defp table_spacing(state) do
    %{state | y: state.y - 18}
  end

  defp world_facts(world) do
    [
      {"Galaxy", Map.get(world, :galaxy_name) || "Not recorded"},
      {"Primary star", Map.get(world, :primary_star_name) || "Not recorded"},
      {"Orbital period", measure(Map.get(world, :orbital_period_days), "days")},
      {"Day length", measure(Map.get(world, :day_length_hours), "hours")},
      {"Axial tilt", measure(Map.get(world, :axial_tilt_degrees), "degrees")},
      {"Mean radius", measure(Map.get(world, :mean_radius_km), "km")},
      {"Map projection", Map.get(world, :map_projection) || "Not recorded"}
    ]
  end

  defp measure(nil, _unit) do
    "Not recorded"
  end

  defp measure(value, unit) do
    "#{value} #{unit}"
  end

  defp max_chars_for_width(width, font_size) do
    trunc(width / (font_size * 0.53))
  end

  defp cover_corner_marks(pdf) do
    inset = 52
    length = 24

    pdf
    |> Pdf.line({inset, inset}, {inset + length, inset})
    |> Pdf.line({inset, inset}, {inset, inset + length})
    |> Pdf.line({@page_width - inset, inset}, {@page_width - inset - length, inset})
    |> Pdf.line({@page_width - inset, inset}, {@page_width - inset, inset + length})
    |> Pdf.line({inset, @page_height - inset}, {inset + length, @page_height - inset})
    |> Pdf.line({inset, @page_height - inset}, {inset, @page_height - inset - length})
    |> Pdf.line(
      {@page_width - inset, @page_height - inset},
      {@page_width - inset - length, @page_height - inset}
    )
    |> Pdf.line(
      {@page_width - inset, @page_height - inset},
      {@page_width - inset, @page_height - inset - length}
    )
    |> Pdf.stroke()
  end

  defp cover_weave(pdf, y) do
    center = @page_width / 2

    pdf
    |> Pdf.set_stroke_color(@rule)
    |> Pdf.set_line_width(1)
    |> Pdf.line({@margin + 70, y}, {center - 22, y})
    |> Pdf.line({center - 22, y}, {center - 11, y + 8})
    |> Pdf.line({center - 11, y + 8}, {center, y})
    |> Pdf.line({center, y}, {center + 11, y + 8})
    |> Pdf.line({center + 11, y + 8}, {center + 22, y})
    |> Pdf.line({center + 22, y}, {@page_width - @margin - 70, y})
    |> Pdf.stroke()
  end

  defp ensure_space(state, needed) do
    if state.y - needed < @bottom do
      content_page(state, state.running_title)
    else
      state
    end
  end

  defp max_chars(font_size, indent) do
    trunc((@content_width - indent) / (font_size * 0.53))
  end

  defp wrap("", _max_chars) do
    []
  end

  defp wrap(text, max_chars) do
    text
    |> String.split(~r/\s+/u, trim: true)
    |> Enum.reduce({[], ""}, fn word, {lines, current} ->
      candidate = if current == "", do: word, else: current <> " " <> word

      if String.length(candidate) <= max_chars do
        {lines, candidate}
      else
        {[current | lines], word}
      end
    end)
    |> then(fn {lines, current} -> Enum.reverse([current | lines]) end)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize(nil) do
    ""
  end

  defp normalize(value) do
    value
    |> to_string()
    |> String.replace(~r/[\x00-\x08\x0B\x0C\x0E-\x1F]/u, " ")
  end

  defp blank?(value) do
    is_nil(value) || String.trim(to_string(value)) == ""
  end
end
