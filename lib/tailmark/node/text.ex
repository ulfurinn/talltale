defmodule Tailmark.Node.Text do
  defstruct [:ref, :parent, content: ""]

  def new(content) do
    %__MODULE__{ref: make_ref(), content: content}
  end

  defimpl Inspect do
    def inspect(node, _) do
      "Text(#{node.content})"
    end
  end
end
