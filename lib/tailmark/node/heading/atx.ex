defmodule Tailmark.Node.Heading.ATX do
  defstruct [:sourcepos, :ref, :parent, children: [], level: 1, content: "", open?: true]

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    @marker ~r/^\#{1,6}(?:[ \t]+|$)/

    def start(_, parser, _) do
      if !indented?(parser) do
        match =
          parser
          |> rest(:next_nonspace)
          |> re_run(@marker)

        case match do
          [marker] ->
            parser
            |> advance_next_nonspace()
            |> advance_offset(String.length(marker), false)
            |> close_unmatched()
            |> add_child(@for, :next_nonspace, fn heading, parser ->
              content =
                parser
                |> rest(:offset)
                |> re_replace(~r/^[ \t]*#+[ \t]*$/, "")
                |> re_replace(~r/[ \t]+#+[ \t]*$/, "")

              %{heading | level: marker |> String.trim() |> String.length(), content: content}
            end)
            |> then(&(&1 |> advance_offset(String.length(&1.current_line) - &1.offset, false)))
            |> leaf()

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

    defp re_run(string, re), do: Regex.run(re, string)
    defp re_replace(string, re, replacement), do: Regex.replace(re, string, replacement)
  end

  defimpl Inspect do
    def inspect(node, _) do
      "H#{node.level}"
    end
  end
end
