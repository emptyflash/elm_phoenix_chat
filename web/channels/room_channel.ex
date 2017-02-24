defmodule ElmPhoenixChat.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("room:" <> _private_room, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end


  def handle_in("new:msg", %{"body" => body, "user" => user}, socket) do
    broadcast! socket, "new:msg", %{body: body, user: user}
    {:noreply, socket}
  end

end
