defmodule Tailmark.Document do
  alias Tailmark.Node.Text

  defstruct [
    :frontmatter,
    :source,
    :sourcepos,
    :ref,
    :parent,
    children: [],
    open?: true,
    type: :document
  ]

  def print(doc) do
    print(doc, 0)
  end

  defp print(nodes, indent) when is_list(nodes) do
    nodes |> Enum.each(&print(&1, indent))
  end

  defp print(node, indent) do
    IO.write(String.duplicate(" ", indent))
    IO.write(inspect(node))
    IO.puts("")

    case node do
      %{children: children} ->
        children |> Enum.each(&print(&1, indent + 1))

      _ ->
        nil
    end
  end

  def compress_text(node) when is_struct(node) do
    case node do
      %{children: children} ->
        %{node | children: children |> Enum.map(&compress_text/1) |> compress_text()}

      node ->
        node
    end
  end

  def compress_text([t = %Text{content: c1}, %Text{content: c2} | rest]) do
    compress_text([%Text{t | content: c1 <> c2} | rest])
  end

  def compress_text([t | rest]) do
    [t | compress_text(rest)]
  end

  def compress_text([]), do: []

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    # not used because the document is by definition always started and never
    # finalized, here for protocol completeness
    def start(_, parser, _), do: matched(parser)
    def continue(_, parser), do: matched(parser)

    def finalize(node, _), do: node
    def can_contain?(_, module), do: module != Tailmark.Node.ListItem
  end

  defimpl Inspect do
    def inspect(_node, _) do
      "Document"
    end
  end
end
