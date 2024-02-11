defmodule Tailmark.Node.Strong do
  defstruct [:ref, :parent, children: []]

  def new() do
    %__MODULE__{ref: make_ref()}
  end

  defimpl Inspect do
    def inspect(_node, _) do
      "Strong"
    end
  end
end
