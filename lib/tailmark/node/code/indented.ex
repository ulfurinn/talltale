defmodule Tailmark.Node.Code.Indented do
  defstruct [:sourcepos, :ref, :parent, children: [], content: "", open?: true]

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    @codeIndent 4

    def start(_, parser, _) do
      if indented?(parser) && tip(parser).__struct__ != Tailmark.Node.Paragraph && !blank?(parser) do
        parser
        |> advance_offset(@codeIndent, true)
        |> close_unmatched()
        |> add_child(@for, :offset)
        |> leaf()
      else
        not_matched(parser)
      end
    end

    def continue(_node, parser) do
      cond do
        parser.indent >= @codeIndent ->
          parser
          |> advance_offset(@codeIndent, true)
          |> matched()

        blank?(parser) ->
          parser
          |> advance_next_nonspace()
          |> matched()

        true ->
          parser
          |> not_matched()
      end
    end

    def finalize(node = %@for{content: content}, _) do
      lines =
        content
        |> String.split("\n")
        |> Enum.reverse()
        |> Enum.drop_while(fn line -> String.trim(line) == "" end)
        |> Enum.reverse()

      content =
        lines
        |> Enum.join("\n")

      to = %{
        line: node.sourcepos.from.line + Enum.count(lines) - 1,
        col: node.sourcepos.from.col + String.length(List.last(lines)) - 1
      }

      %@for{node | content: content <> "\n", sourcepos: %{node.sourcepos | to: to}}
    end

    def can_contain?(_, _), do: false
  end
end
