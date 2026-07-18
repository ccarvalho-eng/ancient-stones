defmodule AncientStoneWeb.PageController do
  use AncientStoneWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
