defmodule AncientStones.WorldExports.WorldGuideEpub do
  @epub_version "3.0"

  def render(guide) do
    chapters = chapters(guide)
    identifier = "urn:ancient-stones:world:#{slug(guide.world.name)}"

    files =
      [
        {"mimetype", "application/epub+zip"},
        {"META-INF/container.xml", container_xml()},
        {"EPUB/package.opf", package_document(guide, chapters, identifier)},
        {"EPUB/nav.xhtml", navigation_document(guide, chapters)},
        {"EPUB/styles.css", stylesheet()}
      ] ++ Enum.map(chapters, &{"EPUB/#{&1.filename}", &1.content})

    archive_files =
      Enum.map(files, fn {filename, contents} ->
        {String.to_charlist(filename), contents}
      end)

    case :zip.create(~c"world-guide.epub", archive_files, [:memory, {:uncompress, :all}]) do
      {:ok, {_filename, binary}} -> binary
      {:error, reason} -> raise "could not build EPUB: #{inspect(reason)}"
    end
  end

  defp chapters(guide) do
    continent_chapters =
      guide.continents
      |> Enum.with_index(1)
      |> Enum.map(fn {continent, index} ->
        chapter(
          "continent-#{index}",
          "continent-#{index}.xhtml",
          continent.name,
          "Atlas / Continent #{String.pad_leading(Integer.to_string(index), 2, "0")}",
          continent
        )
      end)

    [
      chapter("overview", "overview.xhtml", "World at a glance", nil, guide.world)
      | continent_chapters
    ] ++
      [
        chapter("people", "people.xhtml", "People", nil, guide.characters),
        chapter("guilds", "guilds.xhtml", "Guilds", nil, guide.guilds),
        chapter(
          "economy",
          "economy.xhtml",
          "Trade and taxation",
          nil,
          %{trade_routes: guide.trade_routes, tax_policies: guide.tax_policies}
        )
      ]
  end

  defp chapter(id, filename, title, eyebrow, data) do
    %{
      id: id,
      filename: filename,
      title: title,
      content: chapter_document(title, eyebrow, data)
    }
  end

  defp container_xml do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
      <rootfiles>
        <rootfile full-path="EPUB/package.opf" media-type="application/oebps-package+xml"/>
      </rootfiles>
    </container>
    """
  end

  defp package_document(guide, chapters, identifier) do
    chapter_manifest =
      Enum.map_join(chapters, "\n", fn chapter ->
        ~s(<item id="#{chapter.id}" href="#{chapter.filename}" media-type="application/xhtml+xml"/>)
      end)

    spine =
      Enum.map_join(chapters, "\n", fn chapter ->
        ~s(<itemref idref="#{chapter.id}"/>)
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <package xmlns="http://www.idpf.org/2007/opf" version="#{@epub_version}" unique-identifier="book-id">
      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:identifier id="book-id">#{escape(identifier)}</dc:identifier>
        <dc:title>#{escape(guide.world.name)} World Guide</dc:title>
        <dc:language>en</dc:language>
        <dc:creator>Ancient Stones</dc:creator>
        <meta property="dcterms:modified">#{Date.utc_today()}T00:00:00Z</meta>
      </metadata>
      <manifest>
        <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
        <item id="styles" href="styles.css" media-type="text/css"/>
        #{chapter_manifest}
      </manifest>
      <spine>
        #{spine}
      </spine>
    </package>
    """
  end

  defp navigation_document(guide, chapters) do
    links =
      Enum.map_join(chapters, "\n", fn chapter ->
        ~s(<li><a href="#{chapter.filename}">#{escape(chapter.title)}</a></li>)
      end)

    xhtml_document(
      "Contents",
      """
      <main class="contents">
        <p class="eyebrow">Ancient Stones / World archive</p>
        <h1>#{escape(guide.world.name)}</h1>
        <nav epub:type="toc" id="toc">
          <h2>Contents</h2>
          <ol>#{links}</ol>
        </nav>
      </main>
      """
    )
  end

  defp chapter_document(title, eyebrow, data) do
    chapter_heading =
      if eyebrow do
        ~s(<p class="eyebrow">#{escape(eyebrow)}</p>)
      else
        ""
      end

    xhtml_document(
      title,
      """
      <main class="chapter">
        <header class="chapter-header">
          #{chapter_heading}
          <h1>#{escape(title)}</h1>
        </header>
        #{render_value(data)}
      </main>
      """
    )
  end

  defp xhtml_document(title, body) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="en">
      <head>
        <meta charset="UTF-8"/>
        <title>#{escape(title)}</title>
        <link rel="stylesheet" type="text/css" href="styles.css"/>
      </head>
      <body>#{body}</body>
    </html>
    """
  end

  defp render_value(nil), do: ""
  defp render_value(""), do: ""

  defp render_value(%Ecto.Association.NotLoaded{}) do
    ""
  end

  defp render_value(value) when is_list(value) do
    value
    |> Enum.map_join("\n", fn item ->
      "<article class=\"record\">#{render_value(item)}</article>"
    end)
  end

  defp render_value(%Decimal{} = value) do
    render_value(Decimal.to_string(value, :normal))
  end

  defp render_value(%module{} = value)
       when module in [Date, DateTime, NaiveDateTime, Time] do
    render_value(to_string(value))
  end

  defp render_value(%_{} = value) do
    value
    |> Map.from_struct()
    |> render_value()
  end

  defp render_value(value) when is_map(value) do
    name = Map.get(value, :name) || Map.get(value, "name")
    description = Map.get(value, :description) || Map.get(value, "description")

    fields =
      value
      |> Map.drop([:name, "name", :description, "description", :id, "id", :__meta__])
      |> Enum.reject(fn {_key, field_value} -> empty?(field_value) end)

    heading = if name, do: "<h2>#{escape(name)}</h2>", else: ""
    intro = if description, do: "<p class=\"description\">#{escape(description)}</p>", else: ""

    details =
      Enum.map_join(fields, "\n", fn {key, field_value} ->
        """
        <section class="field">
          <h3>#{escape(humanize(key))}</h3>
          #{render_value(field_value)}
        </section>
        """
      end)

    heading <> intro <> details
  end

  defp render_value(value) do
    "<p>#{escape(value)}</p>"
  end

  defp empty?(nil), do: true
  defp empty?(""), do: true
  defp empty?([]), do: true
  defp empty?(%Ecto.Association.NotLoaded{}), do: true
  defp empty?(_value), do: false

  defp humanize(key) do
    key
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp slug(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> "world"
      result -> result
    end
  end

  defp escape(value) do
    value
    |> to_string()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp stylesheet do
    """
    :root { color: #161616; background: #fff; }
    body { margin: 7%; font-family: Georgia, "Times New Roman", serif; line-height: 1.55; }
    main { max-width: 44rem; margin: 0 auto; }
    h1, h2 { font-family: Georgia, "Times New Roman", serif; line-height: 1.08; }
    h1 { margin: 0 0 2rem; font-size: 2.45rem; border-bottom: 1px solid #555; padding-bottom: 1rem; }
    h2 { margin: 2.4rem 0 0.7rem; font-size: 1.45rem; }
    h3, .eyebrow { font-family: Helvetica, Arial, sans-serif; text-transform: uppercase; letter-spacing: 0.12em; }
    h3 { margin: 1.7rem 0 0.55rem; font-size: 0.78rem; color: #444; }
    p { margin: 0.35rem 0 0.9rem; }
    .eyebrow { margin-bottom: 1rem; font-size: 0.72rem; color: #555; }
    .description { font-size: 1.05rem; }
    .record { break-inside: avoid; margin: 0 0 1.6rem; padding: 0 0 1.2rem; border-bottom: 1px solid #bbb; }
    .field { margin-left: 0.3rem; }
    nav ol { padding-left: 1.4rem; }
    nav li { margin: 0.65rem 0; }
    nav a { color: #111; text-decoration: none; border-bottom: 1px solid #999; }
    """
  end
end
