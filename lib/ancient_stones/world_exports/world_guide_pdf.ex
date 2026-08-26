defmodule AncientStones.WorldExports.WorldGuidePdf do
  @moduledoc """
  Renders world guides as paginated PDF manuals.

  The renderer performs a layout pass to determine chapter destinations before
  producing the final document with linked contents.
  """

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

  @doc "Renders a loaded world guide as a PDF binary."
  @spec render(AncientStones.Worlds.WorldGuide.t()) :: binary()
  def render(guide) do
    manual = WorldManual.build(guide)
    chapter_pages = chapter_pages(guide, manual)

    render_pdf(guide, manual, chapter_pages)
  end

  defp chapter_pages(guide, manual) do
    Pdf.build([size: :a4, compress: true], fn pdf ->
      pdf
      |> render_manual(guide, manual, %{})
      |> Map.fetch!(:chapter_pages)
    end)
  end

  defp render_pdf(guide, manual, chapter_pages) do
    Pdf.build([size: :a4, compress: true], fn pdf ->
      state = render_manual(pdf, guide, manual, chapter_pages)

      Pdf.export(state.pdf)
    end)
  end

  defp render_manual(pdf, guide, manual, chapter_pages) do
    pdf
    |> Pdf.set_info(
      title: "#{guide.world.name} World Guide",
      author: "Ancient Stones",
      creator: "Ancient Stones",
      subject: "World atlas and gazetteer"
    )
    |> cover(guide)
    |> Map.put(:chapter_pages, %{})
    |> manual_contents(manual.chapters, chapter_pages)
    |> manual_chapters(manual.chapters)
  end

  defp manual_contents(state, chapters, chapter_pages) do
    state =
      state
      |> content_page("Contents")
      |> heading("Contents", 25)

    Enum.reduce(chapters, state, fn chapter, acc ->
      contents_record(acc, chapter, Map.get(chapter_pages, chapter.id))
    end)
  end

  defp manual_chapters(state, chapters) do
    Enum.reduce(chapters, state, fn chapter, acc ->
      acc =
        Map.update!(acc, :chapter_pages, &Map.put(&1, chapter.id, acc.page + 1))

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
      |> map_canvas(Map.get(record, :map_canvas))
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
    {state, pdf, page} =
      case state_or_pdf do
        %{pdf: pdf, page: page} = state -> {state, Pdf.add_page(pdf), page + 1}
        pdf when is_pid(pdf) -> {%{chapter_pages: %{}}, Pdf.add_page(pdf), 2}
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

    state
    |> Map.put(:pdf, pdf)
    |> Map.put(:y, @top)
    |> Map.put(:page, page)
    |> Map.put(:running_title, title)
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

  defp contents_record(state, chapter, target_page) do
    name_lines = wrap(normalize(chapter.title), max_chars_for_width(@content_width - 36, 11))
    detail_lines = wrap(normalize(chapter.description), max_chars_for_width(@content_width, 9))
    name_height = max(length(name_lines), 1) * 16
    detail_height = length(detail_lines) * 14
    height = name_height + detail_height + 21
    state = ensure_space(state, height)
    rule_y = state.y - height + 8

    pdf =
      state.pdf
      |> draw_record_lines(name_lines, @margin, state.y, 11, 16, true)
      |> draw_record_lines(detail_lines, @margin, state.y - name_height - 3, 9, 14, false)
      |> contents_page_number(target_page, state.y)
      |> record_rule(rule_y)
      |> contents_link(target_page, rule_y, height)

    %{state | pdf: pdf, y: rule_y - 14}
  end

  defp contents_page_number(pdf, nil, _y) do
    pdf
  end

  defp contents_page_number(pdf, page_number, y) do
    pdf
    |> Pdf.set_fill_color(@rule)
    |> Pdf.set_font("Helvetica", size: 8, bold: true)
    |> Pdf.text_at({@page_width - @margin - 15, y}, Integer.to_string(page_number))
  end

  defp contents_link(pdf, nil, _y, _height) do
    pdf
  end

  defp contents_link(pdf, page_number, y, height) do
    Pdf.link_to_page(pdf, {@margin, y}, {@content_width, height}, page_number)
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

  defp map_canvas(state, nil) do
    state
  end

  defp map_canvas(
         state,
         %{document: %{"objects" => objects} = document, width: width, height: height}
       )
       when is_list(objects) and is_number(width) and width > 0 and is_number(height) and
              height > 0 do
    max_height = 330
    scale = min(@content_width / width, max_height / height)
    canvas_width = width * scale
    canvas_height = height * scale
    state = ensure_space(state, canvas_height + 28)
    x = @margin + (@content_width - canvas_width) / 2
    bottom = state.y - canvas_height
    transform = %{x: x, bottom: bottom, height: height, scale: scale}
    background = pdf_color(Map.get(document, "mapBackground"), @parchment)

    pdf =
      state.pdf
      |> Pdf.set_fill_color(background)
      |> Pdf.rectangle({x, bottom}, {canvas_width, canvas_height})
      |> Pdf.fill()

    pdf = Enum.reduce(objects, pdf, &render_map_object(&2, &1, transform))

    pdf =
      pdf
      |> Pdf.set_stroke_color(@rule)
      |> Pdf.set_line_width(0.5)
      |> Pdf.rectangle({x, bottom}, {canvas_width, canvas_height})
      |> Pdf.stroke()

    %{state | pdf: pdf, y: bottom - 22}
  end

  defp map_canvas(state, _canvas) do
    state
  end

  defp render_map_object(pdf, %{"type" => type, "path" => path} = object, transform)
       when type in ["Path", "path"] and is_list(path) do
    {pdf, _current_point} =
      pdf
      |> Pdf.set_stroke_color(pdf_color(Map.get(object, "stroke"), @ink))
      |> Pdf.set_line_width(
        max(number(Map.get(object, "strokeWidth"), 1.0) * transform.scale, 0.25)
      )
      |> then(
        &Enum.reduce(path, {&1, nil}, fn command, acc ->
          render_path_command(acc, command, transform)
        end)
      )

    Pdf.stroke(pdf)
  end

  defp render_map_object(pdf, %{"type" => type, "text" => text} = object, transform)
       when type in ["IText", "Textbox", "i-text", "textbox"] and is_binary(text) do
    x = number(Map.get(object, "left"))
    y = number(Map.get(object, "top"))
    font_size = max(number(Map.get(object, "fontSize"), 16) * transform.scale, 4)

    pdf
    |> Pdf.set_fill_color(pdf_color(Map.get(object, "fill"), @ink))
    |> Pdf.set_font("Times", size: font_size, bold: true)
    |> Pdf.text_at(map_point({x, y}, transform), normalize(text))
  end

  defp render_map_object(pdf, _object, _transform) do
    pdf
  end

  defp render_path_command({pdf, _current}, ["M", x, y], transform) do
    point = {number(x), number(y)}
    {Pdf.move_to(pdf, map_point(point, transform)), point}
  end

  defp render_path_command({pdf, _current}, ["L", x, y], transform) do
    point = {number(x), number(y)}
    {Pdf.line_append(pdf, map_point(point, transform)), point}
  end

  defp render_path_command({pdf, {start_x, start_y}}, ["C", x1, y1, x2, y2, x3, y3], transform) do
    control_1 = {number(x1), number(y1)}
    control_2 = {number(x2), number(y2)}
    finish = {number(x3), number(y3)}

    pdf =
      1..6
      |> Enum.map(&(&1 / 6))
      |> Enum.reduce(pdf, fn t, document ->
        point = cubic_point({start_x, start_y}, control_1, control_2, finish, t)
        Pdf.line_append(document, map_point(point, transform))
      end)

    {pdf, finish}
  end

  defp render_path_command(acc, _command, _transform) do
    acc
  end

  defp cubic_point({x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}, t) do
    inverse = 1 - t

    {
      inverse ** 3 * x0 + 3 * inverse ** 2 * t * x1 + 3 * inverse * t ** 2 * x2 + t ** 3 * x3,
      inverse ** 3 * y0 + 3 * inverse ** 2 * t * y1 + 3 * inverse * t ** 2 * y2 + t ** 3 * y3
    }
  end

  defp map_point({x, y}, transform) do
    {
      transform.x + x * transform.scale,
      transform.bottom + (transform.height - y) * transform.scale
    }
  end

  defp pdf_color("#" <> hex, default) when byte_size(hex) == 6 do
    with {red, ""} <- Integer.parse(binary_part(hex, 0, 2), 16),
         {green, ""} <- Integer.parse(binary_part(hex, 2, 2), 16),
         {blue, ""} <- Integer.parse(binary_part(hex, 4, 2), 16) do
      {red, green, blue}
    else
      _error -> default
    end
  end

  defp pdf_color(_color, default) do
    default
  end

  defp number(value, _default \\ 0)

  defp number(value, _default) when is_integer(value) do
    value / 1
  end

  defp number(value, _default) when is_float(value) do
    value
  end

  defp number(_value, default) do
    default
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
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  defp blank?(value) do
    is_nil(value) || String.trim(to_string(value)) == ""
  end
end
