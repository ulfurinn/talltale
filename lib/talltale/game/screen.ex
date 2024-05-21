defmodule Talltale.Game.Screen do
  alias Talltale.Game.Outcome
  defstruct [:id, text: [], pass: %Outcome{}]
end
