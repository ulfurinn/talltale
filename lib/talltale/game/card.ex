defmodule Talltale.Game.Card do
  @moduledoc "An action."
  alias Talltale.Game.Outcome

  defstruct [
    :id,
    :ref,
    :title,
    :text,
    :frequency,
    :sticky,
    :condition,
    :challenges,
    pass: %Outcome{},
    fail: %Outcome{}
  ]

  def gen_ref(card) do
    %__MODULE__{card | ref: Uniq.UUID.uuid7()}
  end
end
