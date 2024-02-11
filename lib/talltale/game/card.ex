defmodule Talltale.Game.Card do
  @moduledoc "An action."
  defstruct [:id, :ref, :title, :text, :frequency, :condition, :sticky, :effects]

  def gen_ref(card) do
    %__MODULE__{card | ref: Uniq.UUID.uuid7()}
  end
end
