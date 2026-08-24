defmodule AncientStones.WorldExports.WorldGuideEpub do
  alias AncientStones.WorldExports.WorldManual

  @epub_version "3.0"
  @modified_at "2000-01-01T00:00:00Z"

  def render(guide) do
    manual = WorldManual.build(guide)
    chapters = chapters(manual)
    identifier = "urn:ancient-stones:world:#{slug(manual.title)}"

    files =
      [
        {"mimetype", "application/epub+zip"},
        {"META-INF/container.xml", container_xml()},
        {"EPUB/package.opf", package_document(manual, chapters, identifier)},
        {"EPUB/nav.xhtml", navigation_document(manual, chapters)},
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

  defp chapters(manual) do
    manual.chapters
    |> Enum.with_index(1)
    |> Enum.map(fn {chapter, index} ->
      filename =
        if chapter.id == "overview" do
          "overview.xhtml"
        else
          "#{chapter.id}.xhtml"
        end

      %{
        id: "chapter-#{index}",
        filename: filename,
        title: chapter.title,
        content: chapter_document(chapter)
      }
    end)
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

  defp package_document(manual, chapters, identifier) do
    manifest =
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
        <dc:title>#{escape(manual.title)} World Guide</dc:title>
        <dc:language>en</dc:language>
        <dc:creator>Ancient Stones</dc:creator>
        <meta property="dcterms:modified">#{@modified_at}</meta>
      </metadata>
      <manifest>
        <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
        <item id="styles" href="styles.css" media-type="text/css"/>
        #{manifest}
      </manifest>
      <spine>
        #{spine}
      </spine>
    </package>
    """
  end

  defp navigation_document(manual, chapters) do
    links =
      Enum.map_join(chapters, "\n", fn chapter ->
        ~s(<li><a href="#{chapter.filename}">#{escape(chapter.title)}</a></li>)
      end)

    xhtml_document(
      "Contents",
      """
      <nav epub:type="toc" id="toc">
        <h1>#{escape(manual.title)}</h1>
        <ol>#{links}</ol>
      </nav>
      """
    )
  end

  defp chapter_document(chapter) do
    body =
      [
        "<h1>#{escape(chapter.title)}</h1>",
        description(chapter.description),
        render_facts(chapter.facts),
        render_records(chapter.records, 2)
      ]
      |> Enum.join("\n")

    xhtml_document(chapter.title, body)
  end

  defp render_records(records, level) do
    Enum.map_join(records, "\n", fn record ->
      heading_level = min(level, 6)

      """
      <section class="record depth-#{heading_level}">
        <h#{heading_level}>#{escape(record.title)}</h#{heading_level}>
        #{meta(record.meta)}
        #{description(record.description)}
        #{render_facts(record.facts)}
        #{render_records(record.children, level + 1)}
      </section>
      """
    end)
  end

  defp render_facts([]) do
    ""
  end

  defp render_facts(facts) do
    rows =
      Enum.map_join(facts, "\n", fn {label, value} ->
        "<dt>#{escape(label)}</dt><dd>#{escape(value)}</dd>"
      end)

    "<dl>#{rows}</dl>"
  end

  defp meta(nil) do
    ""
  end

  defp meta(value) do
    if blank?(value) do
      ""
    else
      "<p class=\"meta\">#{escape(value)}</p>"
    end
  end

  defp description(nil) do
    ""
  end

  defp description(value) do
    if blank?(value) do
      ""
    else
      "<p class=\"description\">#{escape(value)}</p>"
    end
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
      <body><main>#{body}</main></body>
    </html>
    """
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

  defp blank?(value) do
    String.trim(to_string(value)) == ""
  end

  defp stylesheet do
    """
    :root { color: #171717; background: #fff; }
    body { margin: 7%; font-family: Georgia, "Times New Roman", serif; line-height: 1.65; }
    main { max-width: 44rem; margin: 0 auto; }
    h1, h2, h3, h4, h5, h6 { line-height: 1.18; break-after: avoid; }
    h1 { margin: 0 0 2rem; font-size: 2.35rem; border-bottom: 1px solid #555; padding-bottom: 1rem; }
    h2 { margin: 2.4rem 0 0.6rem; font-size: 1.5rem; }
    h3 { margin: 2rem 0 0.55rem; font-size: 1.15rem; }
    h4, h5, h6 { margin: 1.6rem 0 0.45rem; font-size: 0.95rem; }
    p { margin: 0.35rem 0 0.95rem; }
    .record { margin: 0 0 1.5rem; }
    .record.depth-2 { padding-bottom: 1rem; border-bottom: 1px solid #bbb; }
    .meta { margin-top: 0; color: #444; font-family: Helvetica, Arial, sans-serif; font-size: 0.78rem; letter-spacing: 0.04em; text-transform: uppercase; }
    .description { white-space: pre-line; }
    dl { display: grid; grid-template-columns: minmax(7rem, 0.38fr) 1fr; gap: 0.28rem 1rem; margin: 0.75rem 0 1.25rem; }
    dt { color: #555; font-family: Helvetica, Arial, sans-serif; font-size: 0.75rem; font-weight: bold; letter-spacing: 0.04em; text-transform: uppercase; }
    dd { margin: 0; }
    nav ol { padding-left: 1.4rem; }
    nav li { margin: 0.65rem 0; }
    nav a { color: #111; text-decoration: none; border-bottom: 1px solid #999; }
    """
  end
end
