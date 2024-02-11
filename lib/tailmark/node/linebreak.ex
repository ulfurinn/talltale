defmodule Tailmark.Node.Linebreak do
  defstruct [:ref, :parent, :hard]

  def new(hard), do: %__MODULE__{ref: make_ref(), hard: hard}

  defimpl Inspect do
    def inspect(_node, _) do
      "Linebreak"
    end
  end
end
