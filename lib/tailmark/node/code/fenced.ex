defmodule Tailmark.Node.Code.Fenced do
  defstruct [
    :sourcepos,
    :ref,
    :parent,
    :fenced,
    :fence_char,
    :fence_length,
    :fence_offset,
    children: [],
    content: "",
    info: nil,
    open?: true
  ]

  def new(_, nil), do: raise("sourcepos is required")

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    @marker ~r/^`{3,}(?!.*`)|^~{3,}/
    @endMarker ~r/^(?:`{3,}|~{3,})(?=[ \t]*$)/

    def start(_, parser, _) do
      if !indented?(parser) do
        match =
          parser
          |> rest(:next_nonspace)
          |> re_run(@marker)

        case match do
          [marker] ->
            fence_length = String.length(marker)

            parser
            |> close_unmatched()
            |> add_child(@for, :next_nonspace, fn code, parser ->
              %{
                code
                | fenced: true,
                  fence_length: fence_length,
                  fence_char: String.at(marker, 0),
                  fence_offset: parser.indent
              }
            end)
            |> advance_next_nonspace()
            |> advance_offset(fence_length, false)
            |> leaf()

          _ ->
            not_matched(parser)
        end
      else
        not_matched(parser)
      end
    end

    def continue(
          node = %@for{
            fence_char: fence_char,
            fence_length: fence_length,
            fence_offset: fence_offset
          },
          parser
        ) do
      with true <-
             parser.indent <= 3 &&
               peek(parser, :next_nonspace) == fence_char,
           [marker] <- Regex.run(@endMarker, rest(parser, :next_nonspace)),
           true <- String.length(marker) >= fence_length do
        # put last line length
        parser
        |> finalize(node, parser.line_number)
        |> line_finished()
      else
        _ ->
          1..fence_offset
          |> Enum.reduce_while(parser, fn _, parser ->
            if parser |> peek(:offset) |> space_or_tab?() do
              {:cont, parser |> advance_offset(1, true)}
            else
              {:halt, parser}
            end
          end)
          |> matched()
      end
    end

    def finalize(node = %@for{content: content}, _) do
      [info, rest] = String.split(content, "\n", parts: 2)

      info =
        case String.trim(info) do
          "" -> nil
          info -> info
        end

      %@for{node | info: info, content: rest}
    end

    def can_contain?(_, _), do: false

    defp re_run(string, re), do: Regex.run(re, string)
  end
end
