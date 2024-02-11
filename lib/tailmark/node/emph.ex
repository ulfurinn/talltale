defmodule Tailmark.Node.Emph do
  defstruct [:ref, :parent, children: []]

  def new() do
    %__MODULE__{ref: make_ref()}
  end
end
