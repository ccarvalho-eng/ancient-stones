defmodule AncientStonesWeb.WorldExportController do
  use AncientStonesWeb, :controller

  alias AncientStones.WorldExports.WorldGuidePdf
  alias AncientStones.Worlds.WorldGuide

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

  defp filename(world_name) do
    slug =
      world_name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/u, "-")
      |> String.trim("-")

    "#{if(slug == "", do: "world", else: slug)}-world-guide.pdf"
  end
end
