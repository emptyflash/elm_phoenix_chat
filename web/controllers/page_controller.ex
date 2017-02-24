defmodule ElmPhoenixChat.PageController do
  use ElmPhoenixChat.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
