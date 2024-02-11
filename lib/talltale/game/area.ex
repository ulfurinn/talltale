defmodule Talltale.Game.Area do
  @moduledoc "A larger area containing several locations."

  defstruct [:id, :title, :location_ids, :deck_id]
end
