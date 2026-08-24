defmodule AncientStones.WorldExports.WorldGuidePdf do
  alias AncientStones.WorldExports.WorldManual

  @page_width 595
  @page_height 842
  @margin 52
  @top 765
  @bottom 52
  @content_width @page_width - @margin * 2
  @parchment {255, 255, 255}
  @ink {20, 20, 20}
  @rule {128, 128, 124}

  def render(guide) do
    manual = WorldManual.build(guide)

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
        |> manual_contents(manual.chapters)
        |> manual_chapters(manual.chapters)

      Pdf.export(state.pdf)
    end)
  end

  defp manual_contents(state, chapters) do
    state =
      state
      |> content_page("Contents")
      |> heading("Contents", 25)

    Enum.reduce(chapters, state, fn chapter, acc ->
      entity_record(acc, chapter.title, chapter.description, 0)
    end)
  end

  defp manual_chapters(state, chapters) do
    Enum.reduce(chapters, state, fn chapter, acc ->
      acc
      |> content_page(chapter.title)
      |> heading(chapter.title, 25)
      |> paragraph(chapter.description)
      |> fact_table(nil, chapter.facts)
      |> manual_records(chapter.records, 1)
    end)
  end

  defp manual_records(state, records, level) do
    Enum.reduce(records, state, fn record, acc ->
      acc
      |> manual_heading(record.title, level)
      |> paragraph(record.meta)
      |> paragraph(record.description)
      |> fact_table(nil, record.facts)
      |> manual_records(record.children, level + 1)
    end)
  end

  defp manual_heading(state, title, 1) do
    subheading(state, title)
  end

  defp manual_heading(state, title, _level) do
    minor_heading(state, title)
  end

  defp cover(pdf, guide) do
    galaxy_name = Map.get(guide.world, :galaxy_name) || "Galaxy not recorded"
    star_name = Map.get(guide.world, :primary_star_name) || "Primary star not recorded"

    pdf
    |> page_background()
    |> Pdf.set_fill_color(@parchment)
    |> Pdf.rectangle({0, 0}, {@page_width, @page_height})
    |> Pdf.fill()
    |> Pdf.set_fill_color(@ink)
    |> Pdf.set_font("Helvetica", size: 11, bold: true)
    |> Pdf.text_wrap!(
      {@margin, 716},
      {@content_width, 24},
      "ANCIENT STONES / NORTHERN ARCHIVE",
      align: :center
    )
    |> cover_rule(684)
    |> Pdf.set_font("Times", size: 38, bold: true)
    |> Pdf.text_wrap!({@margin, 574}, {@content_width, 110}, normalize(guide.world.name),
      align: :center,
      leading: 44
    )
    |> Pdf.set_fill_color(@rule)
    |> Pdf.set_font("Helvetica", size: 13)
    |> Pdf.text_wrap!(
      {@margin, 510},
      {@content_width, 28},
      "ATLAS / GAZETTEER / CHRONICLE",
      align: :center
    )
    |> Pdf.set_fill_color(@ink)
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
    |> Pdf.set_fill_color(@ink)
    |> Pdf.set_font("Times", size: 12)
    |> Pdf.text_wrap!(
      {@margin + 45, 302},
      {@content_width - 90, 125},
      normalize(
        guide.world.description || "A living record of lands, peoples, powers, and trade."
      ),
      align: :center,
      leading: 17
    )
    |> cover_rule(230)

    %{pdf: pdf, y: @top, page: 1, running_title: guide.world.name}
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
      |> Pdf.set_stroke_color(@rule)
      |> Pdf.set_line_width(0.6)
      |> Pdf.line({@margin, @page_height - 44}, {@page_width - @margin, @page_height - 44})
      |> Pdf.stroke()
      |> Pdf.set_fill_color(@rule)
      |> Pdf.set_font("Helvetica", size: 9, bold: true)
      |> Pdf.text_at({@margin, @page_height - 31}, normalize(String.upcase(title)))
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
      draw_lines(state, text, 9, 14, @ink, false)
    end
  end

  defp rule(state) do
    state = ensure_space(state, 13)

    pdf =
      state.pdf
      |> Pdf.set_stroke_color(@rule)
      |> Pdf.set_line_width(0.6)
      |> Pdf.line({@margin, state.y}, {@page_width - @margin, state.y})
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
      |> Pdf.set_font("Times", size: font_size, bold: bold)

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
        fact_record(acc, label, value, index)
      end)

    section_spacing(result)
  end

  defp fact_table(state, title, rows) do
    state
    |> ensure_space(78)
    |> subheading(title)
    |> fact_table(nil, rows)
  end

  defp fact_record(state, label, value, _index) do
    value_lines = wrap(normalize(value), max_chars_for_width(@content_width, 10))
    height = 17 + max(length(value_lines), 1) * 14 + 8
    state = ensure_space(state, height)
    rule_y = state.y - height + 6

    pdf =
      state.pdf
      |> Pdf.set_fill_color(@rule)
      |> Pdf.set_font("Helvetica", size: 7.5, bold: true)
      |> Pdf.text_at({@margin, state.y}, normalize(String.upcase(label)))
      |> draw_record_lines(value_lines, @margin, state.y - 15, 10, 14, false)
      |> record_rule(rule_y)

    %{state | pdf: pdf, y: rule_y - 8}
  end

  defp entity_record(state, name, detail, _index) do
    name_lines = wrap(normalize(name), max_chars_for_width(@content_width, 11))
    detail_lines = wrap(normalize(detail), max_chars_for_width(@content_width, 9))
    name_height = max(length(name_lines), 1) * 16
    detail_height = length(detail_lines) * 14
    height = name_height + detail_height + 21
    state = ensure_space(state, height)
    rule_y = state.y - height + 8

    pdf =
      state.pdf
      |> draw_record_lines(name_lines, @margin, state.y, 11, 16, true)
      |> draw_record_lines(detail_lines, @margin, state.y - name_height - 3, 9, 14, false)
      |> record_rule(rule_y)

    %{state | pdf: pdf, y: rule_y - 14}
  end

  defp draw_record_lines(pdf, lines, x, y, font_size, leading, bold) do
    pdf =
      pdf
      |> Pdf.set_fill_color(@ink)
      |> Pdf.set_font("Times", size: font_size, bold: bold)

    lines
    |> Enum.with_index()
    |> Enum.reduce(pdf, fn {line, index}, document ->
      Pdf.text_at(document, {x, y - index * leading}, line)
    end)
  end

  defp record_rule(pdf, y) do
    pdf
    |> Pdf.set_stroke_color(@rule)
    |> Pdf.set_line_width(0.35)
    |> Pdf.line({@margin, y}, {@page_width - @margin, y})
    |> Pdf.stroke()
  end

  defp section_spacing(state) do
    %{state | y: state.y - 8}
  end

  defp max_chars_for_width(width, font_size) do
    trunc(width / (font_size * 0.53))
  end

  defp cover_rule(pdf, y) do
    pdf
    |> Pdf.set_stroke_color(@rule)
    |> Pdf.set_line_width(0.6)
    |> Pdf.line({@margin + 70, y}, {@page_width - @margin - 70, y})
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
