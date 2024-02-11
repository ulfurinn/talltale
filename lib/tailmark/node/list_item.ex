defmodule Tailmark.Node.ListItem do
  defstruct [:sourcepos, :ref, :parent, :list_data, children: [], open?: true]

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    alias Tailmark.Node.List.Data

    @codeIndent 4
    @nonSpace ~r/[^ \t\f\v\r\n]/
    @bulletMarker ~r/^[*+-]/
    @orderedMarker ~r/^(\d{1,9})([.)])/

    def start(_, parser, container) do
      with true <- !indented?(parser) || container.__struct__ == Tailmark.Node.List,
           {list_data, parser} <- parse_list_data(parser, container),
           false <- is_nil(list_data) do
        parser =
          parser
          |> close_unmatched()

        parser =
          if tip(parser).__struct__ != Tailmark.Node.List ||
               !list_match(container.list_data, list_data) do
            parser
            |> add_child(Tailmark.Node.List, :next_nonspace, fn list ->
              %Tailmark.Node.List{list | list_data: list_data}
            end)
          else
            parser
          end

        parser
        |> add_child(@for, :next_nonspace, fn list ->
          %@for{list | list_data: list_data}
        end)
        |> container()
      else
        _ -> not_matched(parser)
      end
    end

    def continue(node, parser) do
      cond do
        parser.blank ->
          if node.children == [] do
            # blank line after empty list item
            not_matched(parser)
          else
            parser
            |> advance_next_nonspace()
            |> matched()
          end

        parser.indent >= node.list_data.marker_offset + node.list_data.padding ->
          parser
          |> advance_offset(node.list_data.marker_offset + node.list_data.padding, true)
          |> matched()

        true ->
          not_matched(parser)
      end
    end

    def finalize(node, parser) do
      case List.last(node.children) do
        nil ->
          to = %{
            line: node.sourcepos.from.line,
            col: node.list_data.marker_offset + node.list_data.padding
          }

          %{node | sourcepos: %{node.sourcepos | to: to}}

        child ->
          child = parser |> get_node(child)

          %{node | sourcepos: %{node.sourcepos | to: child.sourcepos.to}}
      end
    end

    def can_contain?(_, module), do: module != Tailmark.Node.ListItem

    defp parse_list_data(parser, container) do
      data = %Data{marker_offset: parser.indent}
      rest = rest(parser, :next_nonspace)

      if parser.indent < @codeIndent do
        bullet_match = Regex.run(@bulletMarker, rest)
        ordered_match = Regex.run(@orderedMarker, rest)
        container_mod = container.__struct__

        case {bullet_match, ordered_match} do
          {[marker], nil} ->
            %Data{
              data
              | type: :bullet,
                bullet_char: String.at(marker, 0),
                marker_length: String.length(marker)
            }

          {nil, [marker, number, delim]}
          when container_mod != Tailmark.Node.Paragraph or number == "1" ->
            %Data{
              data
              | type: :ordered,
                start: String.to_integer(number),
                delimiter: delim,
                marker_length: String.length(marker)
            }

          _ ->
            nil
        end
        |> check_space_after(parser)
        |> ensure_non_blank_if_breaking_paragraph(parser, container)
        |> parse_list_data_known_type(parser)
      else
        {nil, parser}
      end
    end

    defp check_space_after(nil, _), do: nil

    defp check_space_after(data, parser) do
      if peek(parser, :next_nonspace, data.marker_length) in [nil, " ", "\t"] do
        data
      else
        nil
      end
    end

    defp ensure_non_blank_if_breaking_paragraph(nil, _, _), do: nil

    defp ensure_non_blank_if_breaking_paragraph(data, parser, container) do
      if container.__struct__ == Tailmark.Node.Paragraph &&
           !Regex.match?(@nonSpace, rest(parser, :next_nonspace, data.marker_length)) do
        nil
      else
        data
      end
    end

    defp parse_list_data_known_type(nil, parser), do: {nil, parser}

    defp parse_list_data_known_type(data, parser) do
      parser =
        parser
        |> advance_next_nonspace()
        |> advance_offset(data.marker_length, true)

      spaces_start_col = parser.column
      spaces_start_offset = parser.offset

      parser = skip_spaces(parser, spaces_start_col)

      blank? = peek(parser, :offset) == nil
      spaces_after_marker = parser.column - spaces_start_col

      if spaces_after_marker >= 5 || spaces_after_marker < 1 || blank? do
        data = %Data{data | padding: data.marker_length + 1}

        parser =
          parser
          |> put_column(spaces_start_col)
          |> put_offset(spaces_start_offset)
          |> advance_offset_if_space_or_tab(:offset, 1, true)

        {data, parser}
      else
        data = %Data{data | padding: data.marker_length + spaces_after_marker}
        {data, parser}
      end
    end

    defp skip_spaces(parser, spaces_start_col) do
      parser = parser |> advance_offset(1, true)
      next = peek(parser, :offset)

      if parser.column - spaces_start_col < 5 && space_or_tab?(next) do
        skip_spaces(parser, spaces_start_col)
      else
        parser
      end
    end

    defp list_match(%Data{type: t, delimiter: d, bullet_char: b}, %Data{
           type: t,
           delimiter: d,
           bullet_char: b
         }),
         do: true

    defp list_match(%Data{}, %Data{}), do: false
  end
end
