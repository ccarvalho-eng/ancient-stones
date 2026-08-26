defmodule AncientStonesWeb.WorldExportController do
  use AncientStonesWeb, :controller

  alias AncientStones.WorldExports.{WorldGuideEpub, WorldGuidePdf}
  alias AncientStones.Worlds.WorldGuide

  # sobelow_skip ["XSS.SendResp"]
  def show(conn, %{"id" => world_id}) do
    guide = WorldGuide.load!(world_id)
    pdf = WorldGuidePdf.render(guide)

    conn
    |> put_resp_header("content-type", "application/pdf")
    |> put_resp_header(
      "content-disposition",
      ~s(attachment; filename="#{filename(guide.world.name)}")
    )
    |> send_resp(:ok, pdf)
  end

  # sobelow_skip ["XSS.SendResp"]
  def epub(conn, %{"id" => world_id}) do
    guide = WorldGuide.load!(world_id)
    epub = WorldGuideEpub.render(guide)

    conn
    |> put_resp_header("content-type", "application/epub+zip")
    |> put_resp_header(
      "content-disposition",
      ~s(attachment; filename="#{filename(guide.world.name, "epub")}")
    )
    |> send_resp(:ok, epub)
  end

  defp filename(world_name, extension \\ "pdf") do
    slug =
      world_name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/u, "-")
      |> String.trim("-")

    "#{if(slug == "", do: "world", else: slug)}-world-guide.#{extension}"
  end
end
