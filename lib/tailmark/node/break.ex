defmodule Tailmark.Node.Break do
  defstruct [:sourcepos, :ref, :parent, open?: true]

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    @marker ~r/^(?:\*[ \t]*){3,}$|^(?:_[ \t]*){3,}$|^(?:-[ \t]*){3,}$/

    def start(_, parser, _) do
      if !indented?(parser) && Regex.match?(@marker, rest(parser, :next_nonspace)) do
        parser
        |> close_unmatched()
        |> add_child(@for, :next_nonspace)
        |> then(&advance_offset(&1, String.length(&1.current_line) - &1.offset, false))
        |> leaf()
      else
        not_matched(parser)
      end
    end

    def continue(_, parser), do: not_matched(parser)

    def finalize(node, _), do: node
    def can_contain?(_, _), do: false
  end

  defimpl Inspect do
    def inspect(_node, _), do: "---"
  end
end
