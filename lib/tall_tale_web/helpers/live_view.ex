defmodule TallTaleWeb.Helpers.LiveView do
  def ok(socket), do: {:ok, socket}
  def noreply(socket), do: {:noreply, socket}
end
