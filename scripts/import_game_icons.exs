defmodule GameIconsImporter do
  @catalog_url "https://game-icons.net"
  @output_root "priv/static/images/game-icons"

  def run([source_root]) do
    source_root = Path.expand(source_root)

    unless File.dir?(source_root) do
      raise ArgumentError, "Game Icons source directory does not exist: #{source_root}"
    end

    categories = fetch_categories()
    tagged_icons = fetch_tagged_icons(categories)
    icons = import_icons(source_root, tagged_icons)
    categories = add_category_counts(categories, icons)

    write_manifest(icons, categories)
    write_category_indexes(icons, categories)
    write_path_indexes(icons)
    copy_license(source_root)

    IO.puts("Imported #{length(icons)} icons across #{length(categories)} categories")
  end

  def run(_args) do
    raise ArgumentError, "usage: mix run scripts/import_game_icons.exs /path/to/game-icons/icons"
  end

  defp fetch_categories do
    body = fetch!("#{@catalog_url}/tags.html")

    ~r{<a href="/tags/([^"]+)\.html">(?:<img [^>]+/>)?([^<]+)}
    |> Regex.scan(body, capture: :all_but_first)
    |> Enum.map(fn [id, label] ->
      %{id: id, label: label |> strip_count() |> decode_entities()}
    end)
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(& &1.label)
  end

  defp fetch_tagged_icons(categories) do
    categories
    |> Task.async_stream(&fetch_category_icons/1,
      max_concurrency: 12,
      ordered: false,
      timeout: :infinity
    )
    |> Enum.reduce(%{}, fn
      {:ok, {category, icons}}, tagged_icons ->
        Enum.reduce(icons, tagged_icons, fn icon, tagged_icons ->
          Map.update(
            tagged_icons,
            icon.id,
            Map.put(icon, :categories, [category.id]),
            &Map.update!(&1, :categories, fn categories -> [category.id | categories] end)
          )
        end)

      {:exit, reason}, _tagged_icons ->
        raise "failed to fetch Game Icons category metadata: #{inspect(reason)}"
    end)
  end

  defp fetch_category_icons(category) do
    body = fetch!("#{@catalog_url}/tags/#{category.id}.html")

    icons =
      ~r{<li data-hint="([^"]+)"[^>]*>.*?<a href="/1x1/([^/]+)/([^"]+)\.html">}
      |> Regex.scan(body, capture: :all_but_first)
      |> Enum.map(fn [name, author, slug] ->
        %{
          id: "#{author}/#{slug}",
          name: decode_entities(name),
          author: author,
          slug: slug
        }
      end)

    {category, icons}
  end

  defp import_icons(source_root, tagged_icons) do
    source_root
    |> Path.join("**/*.svg")
    |> Path.wildcard()
    |> Enum.reject(&badge?/1)
    |> Enum.map(&import_icon(&1, source_root, tagged_icons))
    |> Enum.sort_by(& &1.name)
  end

  defp import_icon(source_path, source_root, tagged_icons) do
    [author, filename] = source_path |> Path.relative_to(source_root) |> Path.split()
    slug = Path.rootname(filename)
    id = "#{author}/#{slug}"
    metadata = Map.get(tagged_icons, id, %{})
    categories = metadata |> Map.get(:categories, ["uncategorized"]) |> Enum.uniq() |> Enum.sort()
    output_path = Path.join([@output_root, "icons", author, filename])

    svg = source_path |> File.read!() |> transparent_black_svg()
    write_file(output_path, svg)

    %{
      id: id,
      name: Map.get(metadata, :name, humanize(slug)),
      author: author,
      categories: categories,
      path: svg_path(svg),
      path_key: slug,
      path_url: "/images/game-icons/paths/#{author}.json",
      url: "/images/game-icons/icons/#{author}/#{filename}"
    }
  end

  defp transparent_black_svg(svg) do
    svg
    |> String.replace(~s(<path d="M0 0h512v512H0z"/>), "")
    |> String.replace(~s(fill="#fff"), ~s(fill="#000"))
  end

  defp add_category_counts(categories, icons) do
    categories = [%{id: "uncategorized", label: "Uncategorized"} | categories]

    categories
    |> Enum.map(fn category ->
      count = Enum.count(icons, &Enum.member?(&1.categories, category.id))
      Map.put(category, :count, count)
    end)
    |> Enum.reject(&(&1.count == 0))
  end

  defp write_manifest(icons, categories) do
    manifest = %{
      source: "https://game-icons.net",
      license: "CC BY 3.0 or CC0 where noted by the upstream author",
      icons: Enum.map(icons, &Map.delete(&1, :path)),
      categories: categories
    }

    write_file(Path.join(@output_root, "manifest.json"), Jason.encode!(manifest))
  end

  defp write_category_indexes(icons, categories) do
    Enum.each(categories, fn category ->
      icon_ids =
        icons
        |> Enum.filter(&Enum.member?(&1.categories, category.id))
        |> Enum.map(& &1.id)

      index = Jason.encode!(%{id: category.id, label: category.label, icons: icon_ids})
      write_file(Path.join([@output_root, "categories", "#{category.id}.json"]), index)
    end)
  end

  defp write_path_indexes(icons) do
    icons
    |> Enum.group_by(& &1.author)
    |> Enum.each(fn {author, author_icons} ->
      paths = Map.new(author_icons, &{&1.path_key, &1.path})
      write_file(Path.join([@output_root, "paths", "#{author}.json"]), Jason.encode!(paths))
    end)
  end

  defp copy_license(source_root) do
    source_root
    |> Path.join("license.txt")
    |> File.read!()
    |> then(&write_file(Path.join(@output_root, "LICENSE.txt"), &1))
  end

  defp write_file(path, contents) do
    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, contents)
  end

  defp svg_path(svg) do
    ~r/<path[^>]*d="([^"]+)"/
    |> Regex.scan(svg, capture: :all_but_first)
    |> List.last()
    |> List.first()
  end

  defp fetch!(url) do
    url
    |> Req.get!(retry: :transient, max_retries: 3)
    |> Map.fetch!(:body)
  end

  defp badge?(path) do
    path |> Path.split() |> Enum.member?("badges")
  end

  defp strip_count(label) do
    String.replace(label, ~r/\s+—\s+\d+.*$/, "")
  end

  defp decode_entities(value) do
    value
    |> String.replace("&amp;", "&")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
  end

  defp humanize(slug) do
    slug
    |> String.replace("-", " ")
    |> String.capitalize()
  end
end

GameIconsImporter.run(System.argv())
