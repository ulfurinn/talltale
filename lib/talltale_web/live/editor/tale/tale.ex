defmodule TalltaleWeb.EditorLive.Tale do
  use TalltaleWeb, [:live_view, mode: :editor]

  def mount(%{"tale" => id}, _session, socket) do
    socket
    |> setup(id, :tale)
    |> ok()
  end
end
