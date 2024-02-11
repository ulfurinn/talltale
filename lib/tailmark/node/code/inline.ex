defmodule Tailmark.Node.Code.Inline do
  defstruct [:ref, :parent, content: ""]

  def new(content) do
    %__MODULE__{ref: make_ref(), content: content}
  end
end
