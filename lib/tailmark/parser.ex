defmodule Tailmark.Parser do
  alias Tailmark.Doctree
  alias Tailmark.InlineParser
  alias Tailmark.Document
  alias Tailmark.ParseNode

  defstruct [
    :document,
    :tree,
    :tip,
    :old_tip,
    :last_matched_container,
    :current_line,
    :node_impls,
    all_closed: true,
    offset: 0,
    column: 0,
    indent: 0,
    next_nonspace: 0,
    next_nonspace_column: 0,
    line_number: 0,
    line_count: 0,
    blank: false,
    partially_consumed_tab: false
  ]

  @codeIndent 4
  @lineEnding ~r/\r\n|\n|\r/

  def document(md, opts \\ []) do
    lines =
      md
      |> String.split(@lineEnding)
      |> drop_last_empty_line()

    {frontmatter, lines} =
      if Keyword.get(opts, :frontmatter, true) do
        parse_frontmatter(lines)
      else
        {nil, lines}
      end

    lines =
      case lines do
        [] -> ["\n"]
        _ -> lines
      end

    document = %Document{
      source: Enum.join(lines, "\n"),
      sourcepos: %{from: %{line: 1, col: 1}, to: %{line: 0, col: 0}},
      ref: make_ref(),
      frontmatter: frontmatter
    }

    %__MODULE__{
      node_impls: [
        Tailmark.Node.Blockquote,
        Tailmark.Node.Heading.ATX,
        Tailmark.Node.Code.Fenced,
        # Tailmark.Node.HTML,
        Tailmark.Node.Heading.Setext,
        Tailmark.Node.Break,
        Tailmark.Node.ListItem,
        Tailmark.Node.Code.Indented
      ],
      document: document.ref,
      tree: Doctree.new(document),
      tip: document.ref,
      last_matched_container: document.ref,
      line_count: Enum.count(lines)
    }
    |> parse_blocks(lines)
    |> finalize_document()
    |> parse_inlines()
    |> substitute_tree_refs()
    # |> tap(&Doctree.print(&1.tree))
    |> then(& &1.document)
  end

  defp parse_blocks(state, lines) do
    lines
    |> Enum.with_index(1)
    |> Enum.reduce(state, &incorporate_line(&2, &1))
  end

  defp incorporate_line(state, {line, index}) do
    state =
      state
      |> put_old_tip()
      |> put_current_line(line)
      |> put_line_number(index)
      |> put_offset(0)
      |> put_column(0)
      |> put_blank(false)
      |> put_partially_consumed_tab(false)

    {state, continue_state} =
      state
      |> match_continue(%{all_matched: true, container: state.document, finished?: false})

    if continue_state.finished? do
      state
    else
      state
      |> put_all_closed(continue_state.container == state.old_tip)
      |> put_last_matched_container(continue_state.container)
      |> incorporate_line_start_matched()
    end
  end

  defp incorporate_line_start_matched(state) do
    container = state |> get_node(state.last_matched_container)

    {state, start_state} =
      match_start(state, %{
        container: container.ref,
        matched_leaf:
          container.__struct__ in [
            Tailmark.Node.Code.Fenced,
            Tailmark.Node.Code.Indented,
            Tailmark.Node.HTML
          ]
      })

    state |> add_text_content(start_state.container)
  end

  defp add_text_content(state, container) do
    if !state.all_closed && !state.blank && tip(state).__struct__ == Tailmark.Node.Paragraph do
      state
      |> add_line()
    else
      state = state |> close_unmatched()

      cond do
        get_node(state, container).__struct__ in [
          Tailmark.Node.Paragraph,
          Tailmark.Node.Code.Fenced,
          Tailmark.Node.Code.Indented,
          Tailmark.Node.HTML
        ] ->
          state
          |> add_line()

        state.offset < String.length(state.current_line) && !state.blank ->
          state
          |> add_child(Tailmark.Node.Paragraph, :offset)
          |> advance_next_nonspace()
          |> add_line()

        true ->
          state
      end
    end
  end

  defp add_line(state) do
    state =
      if state.partially_consumed_tab do
        spaces = 4 - rem(state.column, 4)

        state
        |> inc_offset(1)
        |> update_node(state.tip, fn node ->
          %{node | content: node.content <> String.duplicate(" ", spaces)}
        end)
      else
        state
      end

    state
    |> update_node(state.tip, fn node ->
      line = rest(state, :offset)

      %{node | content: node.content <> line <> "\n"}
    end)
  end

  defp match_continue(state, continue_state) do
    container = state |> get_node(continue_state.container)

    last_child =
      case container do
        %{children: children} -> state |> get_node(List.last(children))
        _ -> nil
      end

    if last_child && last_child.open? do
      state = state |> find_next_nonspace()
      {match, state} = ParseNode.continue(last_child, state)

      case match do
        :matched ->
          match_continue(state, %{continue_state | container: last_child.ref})

        :not_matched ->
          # keep original container
          {state, continue_state}

        :line_finished ->
          {state, %{continue_state | finished?: true}}
      end
    else
      {state, continue_state}
    end
  end

  defp match_start(state, start_state = %{matched_leaf: true}) do
    {state, start_state}
  end

  defp match_start(state, start_state) do
    state = state |> find_next_nonspace()

    # TODO: performance opt from blocks.js:829:835

    {matched, state, start_state} =
      state.node_impls
      |> Enum.reduce_while({false, state, start_state}, fn impl, {_, state, start_state} ->
        container = state |> get_node(start_state.container)

        {match, state} = ParseNode.start(struct(impl), state, container)

        case match do
          :container ->
            {:halt, {true, state, %{start_state | container: state.tip}}}

          :leaf ->
            {:halt, {true, state, %{start_state | container: state.tip, matched_leaf: true}}}

          :not_matched ->
            {:cont, {false, state, start_state}}
        end
      end)

    if matched do
      match_start(state, start_state)
    else
      state = state |> advance_next_nonspace()
      {state, start_state}
    end
  end

  def finalize(state, node, line_number) do
    above = node.parent

    state
    |> update_node(node.ref, fn node, state ->
      %{
        node
        | open?: false,
          sourcepos: %{
            node.sourcepos
            | to: %{line: line_number, col: String.length(state.current_line)}
          }
      }
      |> ParseNode.finalize(state)
    end)
    |> put_tip(above)
  end

  defp finalize_document(state = %__MODULE__{tip: nil}), do: state

  defp finalize_document(state = %__MODULE__{line_count: line_count}) do
    state
    |> finalize(tip(state), line_count)
    |> finalize_document()
  end

  defp finalize_until_can_accept_type(state, module) do
    if ParseNode.can_contain?(tip(state), module) do
      state
    else
      state
      |> finalize(tip(state), state.line_number - 1)
      |> finalize_until_can_accept_type(module)
    end
  end

  def add_child(state, module, position, constructor \\ & &1) do
    state =
      state
      |> finalize_until_can_accept_type(module)

    offset =
      case position do
        :next_nonspace -> state.next_nonspace
        :offset -> state.offset
      end

    column_number = offset + 1

    node =
      module.new(state.tip, %{
        from: %{line: state.line_number, col: column_number},
        to: %{line: 0, col: 0}
      })

    state
    |> append_child(state.tip, node)
    |> put_tip(node.ref)
    |> update_node(node.ref, constructor)
  end

  def append_child(state = %__MODULE__{tree: tree}, ref, child) do
    %__MODULE__{state | tree: Doctree.append_child(tree, ref, child)}
  end

  def remove_node(state, ref, child) do
    state
    |> update_node(ref, fn node -> %{node | children: node.children -- [child.ref]} end)
  end

  def cut_children_until(state, parent_ref, child_ref) do
    node = state |> get_node(parent_ref)
    {keep, remove} = node.children |> Enum.split_while(&(&1 != child_ref))

    state =
      state
      |> update_node(parent_ref, fn node -> %{node | children: keep} end)

    {state, remove}
  end

  defp drop_last_empty_line(lines) do
    lines
    |> Enum.reverse()
    |> case do
      ["" | rest] -> rest
      lines -> lines
    end
    |> Enum.reverse()
  end

  defp parse_frontmatter(lines) do
    case lines do
      ["---" | rest] ->
        {frontmatter, ["---" | content]} = Enum.split_while(rest, &(&1 != "---"))
        {YamlElixir.read_from_string!(Enum.join(frontmatter, "\n")), content}

      _ ->
        {nil, lines}
    end
  end

  defp substitute_tree_refs(state = %__MODULE__{tree: tree}) do
    %__MODULE__{state | document: Doctree.flatten_refs(tree)}
  end

  def peek(state, position, extra \\ 0)

  def peek(
        %{current_line: current_line, next_nonspace: next_nonspace},
        :next_nonspace,
        extra
      ) do
    String.at(current_line, next_nonspace + extra)
  end

  def peek(%{current_line: current_line, offset: offset}, :offset, extra) do
    String.at(current_line, offset + extra)
  end

  def rest(parser, position, extra \\ 0)

  def rest(%{current_line: current_line, next_nonspace: next_nonspace}, :next_nonspace, extra) do
    String.split_at(current_line, next_nonspace + extra) |> elem(1)
  end

  def rest(%{current_line: current_line, offset: offset}, :offset, extra) do
    String.split_at(current_line, offset + extra) |> elem(1)
  end

  defp find_next_nonspace(state) do
    find_state =
      find_next_nonspace(state.current_line, %{c: nil, i: state.offset, cols: state.column})

    state
    |> put_blank(find_state.c in ["\n", "\r", nil])
    |> put_next_nonspace(find_state.i)
    |> put_next_nonspace_column(find_state.cols)
    |> put_indent(find_state.cols - state.column)
  end

  defp find_next_nonspace(line, find_state = %{i: i, cols: cols}) do
    c = String.at(line, i)

    case c do
      " " ->
        find_next_nonspace(line, %{find_state | i: i + 1, cols: cols + 1})

      "\t" ->
        find_next_nonspace(line, %{find_state | i: i + 1, cols: cols + (4 - rem(cols, 4))})

      _ ->
        %{find_state | c: c}
    end
  end

  def advance_next_nonspace(state) do
    state
    |> put_offset(state.next_nonspace)
    |> put_column(state.next_nonspace_column)
    |> put_partially_consumed_tab(false)
  end

  def advance_offset_if_space_or_tab(state, peek_pos, count, columns) do
    if peek(state, peek_pos) in [" ", "\t"] do
      state
      |> advance_offset(count, columns)
    else
      state
    end
  end

  def space_or_tab?(char), do: char in [" ", "\t"]

  def advance_offset(state, 0, _), do: state

  def advance_offset(state, count, columns) do
    case peek(state, :offset) do
      nil ->
        state

      "\t" ->
        chars_to_tab = 4 - rem(state.column, 4)

        if columns do
          chars_to_advance = if chars_to_tab > count, do: count, else: chars_to_tab
          partially_consumed_tab = chars_to_tab > count

          state
          |> put_partially_consumed_tab(partially_consumed_tab)
          |> inc_column(chars_to_advance)
          |> inc_offset(if partially_consumed_tab, do: 0, else: 1)
          |> advance_offset(count - chars_to_advance, columns)
        else
          state
          |> put_partially_consumed_tab(false)
          |> inc_column(chars_to_tab)
          |> inc_offset(1)
          |> advance_offset(count - 1, columns)
        end

      _ ->
        state
        |> put_partially_consumed_tab(false)
        |> inc_column(1)
        |> inc_offset(1)
        |> advance_offset(count - 1, columns)
    end
  end

  def close_unmatched(state = %{all_closed: true}), do: state

  def close_unmatched(state) do
    state
    |> close_deepest_unmatched()
    |> put_all_closed(true)
  end

  defp close_deepest_unmatched(state = %{old_tip: ref, last_matched_container: ref}), do: state

  defp close_deepest_unmatched(state) do
    old_tip = state |> get_node(state.old_tip)

    state
    |> finalize(old_tip, state.line_number - 1)
    |> put_old_tip(old_tip.parent)
    |> close_deepest_unmatched()
  end

  defp parse_inlines(state = %__MODULE__{document: document, tree: tree}) do
    %__MODULE__{state | tree: parse_inlines(tree, document)}
  end

  defp parse_inlines(tree, ref) when is_reference(ref) do
    node = Doctree.get_node(tree, ref)

    tree =
      case node do
        %{children: children} ->
          Enum.reduce(children, tree, &parse_inlines(&2, &1))

        _ ->
          tree
      end

    InlineParser.parse(node, tree)
  end

  def put_offset(state, value), do: %{state | offset: value}
  def put_column(state, value), do: %{state | column: value}
  defp put_current_line(state, value), do: %{state | current_line: value}
  defp put_line_number(state, value), do: %{state | line_number: value}
  defp put_tip(state, value), do: %{state | tip: value}
  defp put_old_tip(state), do: %{state | old_tip: state.tip}
  defp put_old_tip(state, value), do: %{state | old_tip: value}
  defp put_blank(state, value), do: %{state | blank: value}
  defp put_partially_consumed_tab(state, value), do: %{state | partially_consumed_tab: value}
  defp put_next_nonspace(state, value), do: %{state | next_nonspace: value}
  defp put_next_nonspace_column(state, value), do: %{state | next_nonspace_column: value}
  defp put_indent(state, value), do: %{state | indent: value}
  defp put_all_closed(state, value), do: %{state | all_closed: value}
  defp put_last_matched_container(state, value), do: %{state | last_matched_container: value}

  defp inc_column(state, column), do: %{state | column: state.column + column}
  defp inc_offset(state, offset), do: %{state | offset: state.offset + offset}

  def get_node(%__MODULE__{tree: tree}, ref), do: Doctree.get_node(tree, ref)

  defp update_node(state = %__MODULE__{tree: tree}, node),
    do: %__MODULE__{state | tree: Doctree.put_node(tree, node)}

  def update_node(state = %__MODULE__{tree: tree}, ref, fun) when is_reference(ref) do
    node = Doctree.get_node(tree, ref)

    updated =
      cond do
        is_function(fun, 1) -> fun.(node)
        is_function(fun, 2) -> fun.(node, state)
        true -> raise "invalid arity in update_node callback"
      end

    case updated do
      {node, state} -> update_node(state, node)
      node -> update_node(state, node)
    end
  end

  def update_node(state, node, fun), do: update_node(state, node.ref, fun)

  def indented?(state), do: state.indent >= @codeIndent
  def blank?(%__MODULE__{blank: blank}), do: blank
  def tip(%__MODULE__{tip: tip, tree: tree}), do: Doctree.get_node(tree, tip)

  def matched(state), do: {:matched, state}
  def not_matched(state), do: {:not_matched, state}
  def line_finished(state), do: {:line_finished, state}
  def container(state), do: {:container, state}
  def leaf(state), do: {:leaf, state}
end
