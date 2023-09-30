defmodule TalltaleWeb.EditorLive.Quality do
  use TalltaleWeb, [:live_view, mode: :editor]

  alias Talltale.Editor.Tale

  def mount(_params = %{"tale" => tale_id, "slug" => slug}, _session, socket) do
    socket
    |> setup(tale_id, :qualities)
    |> then(&put_quality(&1, Tale.get_quality(tale(&1), slug: slug)))
    |> ok
  end

  def handle_info({:quality_updated, quality}, socket),
    do: socket |> put_quality(quality) |> noreply()

  defp put_quality(socket, quality), do: assign(socket, :quality, quality)
end
