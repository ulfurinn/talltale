defmodule Tailmark.Node.Blockquote do
  defstruct [:sourcepos, :ref, :parent, :callout, children: [], open?: true]

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    def start(_, parser, _) do
      if !indented?(parser) && peek(parser, :next_nonspace) == ">" do
        parser
        |> advance_next_nonspace()
        |> advance_offset(1, false)
        |> advance_offset_if_space_or_tab(:offset, 1, true)
        |> close_unmatched()
        |> add_child(@for, :next_nonspace)
        |> container()
      else
        not_matched(parser)
      end
    end

    def continue(_, parser) do
      if !indented?(parser) && peek(parser, :next_nonspace) == ">" do
        parser
        |> advance_next_nonspace()
        |> advance_offset(1, false)
        |> advance_offset_if_space_or_tab(:offset, 1, true)
        |> matched()
      else
        not_matched(parser)
      end
    end

    def finalize(node, _), do: node
    def can_contain?(_, module), do: module != Tailmark.Node.ListItem
  end

  defimpl Inspect do
    def inspect(%@for{callout: callout}, _) when callout != nil, do: "#{callout.type}>"
    def inspect(_, _), do: ">"
  end
end
