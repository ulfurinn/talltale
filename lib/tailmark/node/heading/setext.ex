defmodule Tailmark.Node.Heading.Setext do
  defstruct [:sourcepos, :ref, :parent, children: [], level: 1, content: "", open?: true]

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    @marker ~r/^(?:=+|-+)[ \t]*$/

    def start(_, parser, container) do
      if !indented?(parser) && container.__struct__ == Tailmark.Node.Paragraph do
        match = Regex.run(@marker, rest(parser, :next_nonspace))

        case match do
          [marker] ->
            parser =
              parser
              |> close_unmatched()

            # TODO: update reference link definitions
            if container.content != "" do
              parser
              |> update_node(container.ref, fn node ->
                %@for{
                  sourcepos: node.sourcepos,
                  ref: node.ref,
                  parent: node.parent,
                  open?: node.open?,
                  level: if(match?("=" <> _, marker), do: 1, else: 2),
                  content: String.trim_trailing(node.content)
                }
              end)
              |> advance_offset(String.length(parser.current_line) - parser.offset, false)
              |> leaf()
            else
              not_matched(parser)
            end

          _ ->
            not_matched(parser)
        end
      else
        not_matched(parser)
      end
    end

    def continue(_, parser), do: not_matched(parser)
    def finalize(node, _), do: node
    def can_contain?(_, _), do: false
  end
end
