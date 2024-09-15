defmodule Tailmark.InlineParser do
  alias Tailmark.Node.Blockquote
  alias Tailmark.Node.Paragraph
  alias Tailmark.Node.Text
  alias Tailmark.Doctree

  defmodule Bracket do
    defstruct [:node, :position, :embed?, :delimiter_base, wiki?: false]
  end

  defstruct [:node, :tree, :subject, :pos, :delimiters, :brackets]

  @escapable_def "[!\"#$%&'()*+,.\\/:;<=>?@[\\]^_`{|}~-]"
  @entity_def "&(?:#x[a-f0-9]{1,6}|#[0-9]{1,7}|[a-z][a-z0-9]{1,31});"
  @main ~r/^[^\n`\[\]\\!<&*_]+/
  @escapable ~r/^#{@escapable_def}/
  @initial_space ~r/^ */
  @final_space ~r/ *$/
  @ticks_here ~r/^`+/
  @ticks ~r/^[^`]*(?<goal>`+)/
  @spnl ~r/^ *(?:\n *)?/
  @link_destination_braces ~r/^<(?<goal>(?:[^<>\n\\\x00]|\\.)*)>/
  @link_title ~r/^(?:"(?<goal1>(\\#{@escapable_def}|\\[^\\]|[^\\"\x00])*)"|'(?<goal2>(\\#{@escapable_def}|\\[^\\]|[^\\'\x00])*)'|\((?<goal3>(\\#{@escapable_def}|\\[^\\]|[^\\()\x00])*)\))/
  @entity ~r/^#{@entity_def}/i
  @whitespace_char ~r/^[ \t\n\x0b\x0c\x0d]/
  @unicode_whitespace_char ~r/^\s/u
  @punctuation ~r/^\p{P}/u
  @backslash_or_amp ~r/[\\&]/
  @entity_or_escaped ~r/\\#{@escapable_def}|#{@entity_def}/
  @callout ~r/^\[!(?<type>[a-z0-9-]+)(\|(?<meta>[a-z0-9-]+))?\]\s*?(?<title>[^\n]+)?(\n|$)/ui

  def parse(text) when is_binary(text) do
    node = Paragraph.new(text)
    tree = Doctree.new(node)

    parse(node, tree)
    |> Doctree.flatten_refs()
  end

  def parse(node = %{content: _}, tree) do
    state =
      %__MODULE__{
        node: node.ref,
        tree: tree,
        subject: String.trim(node.content),
        pos: 0,
        delimiters: [],
        brackets: []
      }
      |> parse_inline()
      |> process_emphasis(nil)

    state.tree
  end

  def parse(_, tree), do: tree

  defp parse_inline(state) do
    c = peek(state)

    if c == nil do
      state
    else
      {state, result} = parse_inline(state, c)

      if result do
        state
      else
        state
        |> advance()
        |> append_child(Tailmark.Node.Text.new(c))
      end
      |> parse_inline()
    end
  end

  defp parse_inline(state, "\n") do
    state = state |> advance()

    last_child =
      Doctree.get_node(state.tree, state.node).children
      |> List.last()
      |> then(&Doctree.get_node(state.tree, &1))

    with %Tailmark.Node.Text{content: content} <- last_child,
         " " <- content |> String.last() do
      hard_break = String.at(content, -2) == " "

      state
      |> update_node(last_child.ref, fn node ->
        %{node | content: Regex.replace(@final_space, node.content, "")}
      end)
      |> append_child(Tailmark.Node.Linebreak.new(hard_break))
    else
      _ ->
        state |> append_child(Tailmark.Node.Linebreak.new(false))
    end
    |> consume(@initial_space)
    |> result(true)
  end

  defp parse_inline(state, "\\") do
    state = state |> advance()

    cond do
      peek(state) == "\n" ->
        state
        |> advance()
        |> append_child(Tailmark.Node.Linebreak.new(true))

      peek(state) && Regex.match?(@escapable, peek(state)) ->
        state
        |> append_child(Tailmark.Node.Text.new(peek(state)))
        |> advance()

      true ->
        state
        |> append_child(Tailmark.Node.Text.new("\\"))
    end
    |> result(true)
  end

  defp parse_inline(state, "`") do
    {state, match} = extract(state, @ticks_here)

    if match do
      {state1, result} = match_closing_backtick(state, match, state.pos)

      if result do
        {state1, result}
      else
        state
        |> append_child(Tailmark.Node.Text.new(match))
        |> result(true)
      end
    else
      state |> result(false)
    end
  end

  defp parse_inline(state, c) when c in ["*", "_"] do
    result = state |> scan_delims(c)

    case result do
      %{delim: delim, can_open: can_open, can_close: can_close} ->
        node = Tailmark.Node.Text.new(delim)

        state
        |> advance(String.length(delim))
        |> append_child(node)
        |> push_delim(%{
          ref: make_ref(),
          c: c,
          num_delims: String.length(delim),
          orig_delims: String.length(delim),
          node: node.ref,
          can_open: can_open,
          can_close: can_close
        })
        |> result(true)

      nil ->
        state |> result(false)
    end
  end

  defp parse_inline(state = %{pos: pos}, "[") do
    case peek(state, 1) do
      "[" ->
        node = Text.new("[[")

        state
        |> advance(2)
        |> append_child(node)
        |> push_bracket(node, pos, false, true)
        |> result(true)

      "!" ->
        with node <- Doctree.get_node(state.tree, state.node),
             true <- is_reference(node.parent),
             parent <- Doctree.get_node(state.tree, node.parent),
             %Blockquote{} <- parent,
             [] <- node.children,
             {state, {type, meta, title}} <- parse_callout(state) do
          state
          |> update_node(parent.ref, fn blockquote ->
            %Blockquote{blockquote | callout: %{type: type, meta: meta, title: title}}
          end)
          |> then(fn state ->
            if rest(state) == "" do
              # the paragraph only contained callout markers, remove it
              remove_node(state, node)
            else
              state
            end
          end)
          |> result(true)
        else
          _ ->
            state |> result(false)
        end

      _ ->
        node = Text.new("[")

        state
        |> advance()
        |> append_child(node)
        |> push_bracket(node, pos, false, false)
        |> result(true)
    end
  end

  defp parse_inline(state = %{pos: pos}, "!") do
    if peek(state, 1) == "[" do
      if peek(state, 2) == "[" do
        node = Text.new("![[")

        state
        |> advance(3)
        |> append_child(node)
        |> push_bracket(node, pos, true, true)
        |> result(true)
      else
        node = Text.new("![")

        state
        |> advance(2)
        |> append_child(node)
        |> push_bracket(node, pos, true, false)
        |> result(true)
      end
    else
      state
      |> advance(1)
      |> append_child(Tailmark.Node.Text.new("!"))
      |> result(true)
    end
  end

  defp parse_inline(state, "]") do
    state = state |> advance()

    if Enum.empty?(state.brackets) do
      if peek(state) == "]" do
        state
        |> advance()
        |> append_child(Tailmark.Node.Text.new("]]"))
        |> result(true)
      else
        state
        |> append_child(Tailmark.Node.Text.new("]"))
        |> result(true)
      end
    else
      if peek(state) == "]" do
        state |> advance() |> match_closing_bracket(true)
      else
        state |> match_closing_bracket(false)
      end
    end
  end

  defp parse_inline(state, "&") do
    case extract(state, @entity) do
      {state, nil} ->
        state
        |> result(false)

      {state, entity} ->
        entity |> HtmlEntities.decode()

        state
        |> append_child(Tailmark.Node.Text.new(HtmlEntities.decode(entity)))
        |> result(true)
    end
  end

  defp parse_inline(state, _) do
    case extract(state, @main) do
      {state, nil} ->
        state
        |> result(false)

      {state, string} ->
        state
        |> append_child(Tailmark.Node.Text.new(string))
        |> result(true)
    end
  end

  defp parse_callout(state) do
    case extract(state, @callout) do
      {state, str} when is_binary(str) ->
        [info, meta, title] = Regex.run(@callout, str, capture: ["type", "meta", "title"])
        {state, {info, empty_to_nil(meta), empty_to_nil(title)}}

      result ->
        result
    end
  end

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(string), do: string

  defp scan_delims(state, c) do
    delim = consume_delim(state, c, "")

    if delim == "" do
      nil
    else
      char_before = if state.pos == 0, do: "\n", else: peek(state, -1)
      char_after = peek(state, String.length(delim)) || "\n"

      after_is_whitespace = Regex.match?(@unicode_whitespace_char, char_after)
      after_is_punctuation = Regex.match?(@punctuation, char_after)
      before_is_whitespace = Regex.match?(@unicode_whitespace_char, char_before)
      before_is_punctuation = Regex.match?(@punctuation, char_before)

      left_flanking =
        !after_is_whitespace &&
          (!after_is_punctuation || before_is_whitespace || before_is_punctuation)

      right_flanking =
        !before_is_whitespace &&
          (!before_is_punctuation || after_is_whitespace || after_is_punctuation)

      {can_open, can_close} =
        if c == "_" do
          {left_flanking && (!right_flanking || before_is_punctuation),
           right_flanking && (!left_flanking || after_is_punctuation)}
        else
          {left_flanking, right_flanking}
        end

      %{delim: delim, can_open: can_open, can_close: can_close}
    end
  end

  defp consume_delim(state, c, acc) do
    if peek(state) == c do
      state |> advance() |> consume_delim(c, acc <> c)
    else
      acc
    end
  end

  defp match_closing_backtick(state, opening, position) do
    {state, match} = extract(state, @ticks)

    if match do
      if match == opening do
        content =
          substring(state, position, state.pos - position)
          |> String.split_at(-String.length(match))
          |> elem(0)
          |> String.replace(~r/\n/, " ")
          |> strip_inline_code_spaces()

        state
        |> append_child(Tailmark.Node.Code.Inline.new(content))
        |> result(true)
      else
        match_closing_backtick(state, opening, position)
      end
    else
      state |> result(false)
    end
  end

  defp match_closing_bracket(state = %__MODULE__{brackets: [bracket | _]}, false) do
    embed? = bracket.embed?

    {state, inline_link} = try_match_inline_link(state)

    case inline_link do
      %{destination: destination, title: title} ->
        {state, [_opening_bracket | nodes]} = cut_from(state, bracket.node)
        link = Tailmark.Node.Link.new(URI.encode(URI.decode(destination)), title, embed?)

        state
        |> append_child(link)
        |> append_child(link.ref, nodes)
        |> process_emphasis(bracket.delimiter_base)
        |> pop_bracket()
        |> drop_nested_brackets(bracket.embed?)
        |> result(true)

      nil ->
        state
        |> append_child(Tailmark.Node.Text.new("]"))
        |> pop_bracket()
        |> result(true)
    end
  end

  defp match_closing_bracket(state = %__MODULE__{tree: tree, brackets: [bracket | _]}, true) do
    embed? = bracket.embed?

    with {state, [_opening_bracket, text]} <- cut_from(state, bracket.node),
         text <- Doctree.get_node(tree, text),
         split <- String.split(text.content, "|", parts: 2) do
      {destination, content} =
        case split do
          [destination, title] -> {destination, title}
          [destination] -> {destination, destination}
        end

      link = Tailmark.Node.Link.new(URI.encode(URI.decode(destination)), nil, embed?)

      state
      |> append_child(link)
      |> append_child(link.ref, Tailmark.Node.Text.new(content))
      |> pop_bracket()
      |> drop_nested_brackets(bracket.embed?)
      |> result(true)
    else
      _ ->
        state
        |> append_child(Tailmark.Node.Text.new("]]"))
        |> pop_bracket()
        |> result(true)
    end
  end

  defp drop_nested_brackets(state, opener_embed?)
  defp drop_nested_brackets(state, false), do: %__MODULE__{state | brackets: []}
  defp drop_nested_brackets(state, true), do: state

  defp strip_inline_code_spaces(string) do
    with true <- String.length(string) > 0,
         true <- Regex.match?(~r/[^ ]/, string),
         " " <- String.at(string, 0),
         " " <- String.at(string, -1) do
      string
      |> String.split_at(1)
      |> elem(1)
      |> String.split_at(-1)
      |> elem(0)
    else
      _ -> string
    end
  end

  defp try_match_inline_link(state = %__MODULE__{pos: pos}) do
    with "(" <- state |> peek(),
         state <- state |> advance() |> consume(@spnl),
         {:ok, state, destination} <- state |> parse_link_destination(),
         state <- state |> consume(@spnl),
         {:ok, state, title} <- state |> parse_link_title(),
         state <- state |> consume(@spnl),
         ")" <- state |> peek() do
      state |> advance() |> result(%{destination: unescape(destination), title: title})
    else
      # TODO: refmap
      _ -> state |> rewind(pos) |> result(nil)
    end
  end

  defp parse_link_destination(state) do
    case state |> extract(@link_destination_braces) do
      {state, nil} ->
        state |> parse_link_destination_manual()

      {state, destination} ->
        {:ok, state, destination}
    end
  end

  defp parse_link_destination_manual(state = %__MODULE__{pos: pos}) do
    if state |> peek() == "<" do
      nil
    else
      {state, c, open_parens} = parse_link_destination_manual(state, 0)

      cond do
        state.pos == pos && c != ")" -> nil
        open_parens != 0 -> nil
        true -> {:ok, state, substring(state, pos, state.pos - pos)}
      end
    end
  end

  defp parse_link_destination_manual(state, open_parens) do
    c = state |> peek()

    cond do
      c == nil ->
        {state, c, open_parens}

      c == "\\" && state |> peek(1) |> match_str?(@escapable) ->
        state = state |> advance()
        state = if state |> peek(), do: state |> advance(), else: state
        parse_link_destination_manual(state, open_parens)

      c == "(" ->
        state = state |> advance()
        parse_link_destination_manual(state, open_parens + 1)

      c == ")" ->
        if open_parens < 1 do
          {state, c, open_parens}
        else
          state = state |> advance()
          parse_link_destination_manual(state, open_parens - 1)
        end

      c |> match_str?(@whitespace_char) ->
        {state, c, open_parens}

      true ->
        state = state |> advance()
        parse_link_destination_manual(state, open_parens)
    end
  end

  defp parse_link_title(state) do
    {state, result} = state |> extract(@link_title)
    {:ok, state, result}
  end

  defp process_emphasis(state = %__MODULE__{delimiters: delimiters}, base) do
    case next_delim(delimiters, base) do
      nil ->
        state |> remove_delims_until(base)

      delim ->
        bases =
          for c <- ["*", "_"],
              can_open <- [true, false],
              length <- [0, 1, 2],
              into: %{},
              do: {%{c: c, can_open: can_open, length: length}, base}

        state
        |> process_emphasis(delim, base, bases)
    end
  end

  defp process_emphasis(state, nil, base, _) do
    state |> remove_delims_until(base)
  end

  defp process_emphasis(state = %__MODULE__{delimiters: delimiters}, closer, base, bases) do
    if closer.can_close do
      opener_key = %{c: closer.c, can_open: closer.can_open, length: rem(closer.orig_delims, 3)}
      opener_base = bases[opener_key]
      opener = find_opener(delimiters, closer, prev_delim(delimiters, closer), opener_base, base)

      if opener do
        use_delims = if closer.num_delims >= 2 && opener.num_delims >= 2, do: 2, else: 1
        opener_inl = opener.node
        closer_inl = closer.node

        state =
          state
          |> update_delim(opener, fn opener ->
            %{opener | num_delims: opener.num_delims - use_delims}
          end)
          |> update_delim(closer, fn closer ->
            %{closer | num_delims: closer.num_delims - use_delims}
          end)
          |> update_node(opener_inl, fn opener_inl ->
            %{opener_inl | content: opener_inl.content |> String.split_at(-use_delims) |> elem(0)}
          end)
          |> update_node(closer_inl, fn closer_inl ->
            %{closer_inl | content: closer_inl.content |> String.split_at(use_delims) |> elem(1)}
          end)

        emph =
          if use_delims == 1, do: Tailmark.Node.Emph.new(), else: Tailmark.Node.Strong.new()

        {state, children} = cut_children_between(state, opener_inl, closer_inl)
        children = Enum.map(children, &Doctree.get_node(state.tree, &1))
        state = state |> insert_child_after(emph, opener_inl) |> append_child(emph.ref, children)

        {state, next} =
          state
          |> remove_delims_between(opener, closer)
          |> cleanup_opener_delim(opener)
          |> cleanup_closer_delim(closer)

        state
        |> process_emphasis(next, base, bases)
      else
        bases = Map.put(bases, opener_key, prev_delim(delimiters, closer))
        process_emphasis(state, next_delim(delimiters, closer), base, bases)
      end
    else
      process_emphasis(state, next_delim(delimiters, closer), base, bases)
    end
  end

  defp find_opener(delimiters, closer, opener, opener_base, base)
  defp find_opener(_, _, nil, _, _), do: nil
  defp find_opener(_, _, %{ref: ref}, %{ref: ref}, _), do: nil
  defp find_opener(_, _, %{ref: ref}, _, %{ref: ref}), do: nil

  defp find_opener(delimiters, closer, opener, opener_base, base) do
    odd_match =
      (closer.can_open || opener.can_close) && rem(closer.orig_delims, 3) != 0 &&
        rem(opener.orig_delims + closer.orig_delims, 3) == 0

    if opener.c == closer.c && opener.can_open && !odd_match do
      opener
    else
      find_opener(delimiters, closer, prev_delim(delimiters, opener), opener_base, base)
    end
  end

  defp cleanup_opener_delim(state, opener) do
    opener = get_delim(state, opener)

    if opener.num_delims == 0 do
      state
      |> remove_node(opener.node)
      |> remove_delim(opener)
    else
      state
    end
  end

  defp cleanup_closer_delim(state, closer) do
    closer = get_delim(state, closer)

    if closer.num_delims == 0 do
      next = next_delim(state.delimiters, closer)

      state =
        state
        |> remove_node(closer.node)
        |> remove_delim(closer)

      {state, next}
    else
      {state, closer}
    end
  end

  defp remove_delim(state = %__MODULE__{delimiters: delimiters}, %{ref: ref}) do
    delims = delimiters |> Enum.reject(&(&1.ref == ref))
    %__MODULE__{state | delimiters: delims}
  end

  defp remove_delims_until(state = %__MODULE__{delimiters: delimiters}, ref)
       when is_reference(ref) do
    {_, delims} = delimiters |> Enum.split_while(&(&1.ref != ref))
    %__MODULE__{state | delimiters: delims}
  end

  defp remove_delims_until(state, nil) do
    %__MODULE__{state | delimiters: []}
  end

  defp remove_delims_between(state = %__MODULE__{delimiters: delims}, %{ref: from_ref}, %{
         ref: to_ref
       }) do
    {tail, [to | delims]} = delims |> Enum.split_while(&(&1.ref != to_ref))
    {_, head} = delims |> Enum.split_while(&(&1.ref != from_ref))
    %__MODULE__{state | delimiters: tail ++ [to | head]}
  end

  defp prev_delim([], _), do: nil
  defp prev_delim([%{ref: ref}, d2 | _], %{ref: ref}), do: d2
  defp prev_delim([_ | delims], base), do: prev_delim(delims, base)

  defp next_delim([], _), do: nil
  defp next_delim([delim], nil), do: delim
  defp next_delim([d1, %{ref: ref} | _], %{ref: ref}), do: d1
  defp next_delim([_ | delims], base), do: next_delim(delims, base)

  defp get_delim(%__MODULE__{delimiters: delims}, %{ref: ref}) do
    delims |> Enum.find(&(&1.ref == ref))
  end

  defp update_delim(state, %{ref: ref}, fun) do
    delims =
      state.delimiters
      |> Enum.map(fn delim -> if delim.ref == ref, do: fun.(delim), else: delim end)

    %__MODULE__{state | delimiters: delims}
  end

  defp push_bracket(
         state = %__MODULE__{brackets: brackets, delimiters: delimiters},
         node,
         position,
         embed?,
         wiki?
       ) do
    bracket = %Bracket{
      node: node.ref,
      position: position,
      embed?: embed?,
      wiki?: wiki?,
      delimiter_base: delimiter_base(delimiters)
    }

    %__MODULE__{state | brackets: [bracket | brackets]}
  end

  defp pop_bracket(state = %__MODULE__{brackets: [_ | brackets]}),
    do: %__MODULE__{state | brackets: brackets}

  defp delimiter_base([]), do: nil
  defp delimiter_base([%{ref: ref} | _]), do: ref

  defp push_delim(state = %__MODULE__{delimiters: delimiters}, delim),
    do: %__MODULE__{state | delimiters: [delim | delimiters]}

  defp peek(%__MODULE__{subject: subject, pos: pos}, shift \\ 0),
    do: String.at(subject, pos + shift)

  defp rest(%__MODULE__{subject: subject, pos: pos}), do: String.split_at(subject, pos) |> elem(1)

  defp substring(%__MODULE__{subject: subject}, start, length) do
    subject
    |> String.split_at(start)
    |> elem(1)
    |> String.split_at(length)
    |> elem(0)
  end

  defp unescape(str) do
    if Regex.match?(@backslash_or_amp, str) do
      Regex.replace(@entity_or_escaped, str, &unescape1/1)
    else
      str
    end
  end

  defp unescape1("\\" <> char), do: char
  defp unescape1(entity), do: HtmlEntities.decode(entity)

  defp advance(state = %__MODULE__{pos: pos}, n \\ 1), do: %__MODULE__{state | pos: pos + n}
  defp rewind(state = %__MODULE__{}, n), do: %__MODULE__{state | pos: n}

  defp consume(state, re) do
    case Regex.run(re, rest(state), capture: :first) do
      [match] ->
        state
        |> advance(String.length(match))

      _ ->
        state
    end
  end

  defp extract(state, re) do
    case Regex.run(re, rest(state), capture: :first) do
      [match] ->
        goals = re |> Regex.names() |> Enum.filter(&match?("goal" <> _, &1))

        result =
          if Enum.any?(goals) do
            captures = Regex.named_captures(re, match)

            goals
            |> Enum.reduce_while(nil, fn goal, acc ->
              result = captures[goal]
              if result == "", do: {:cont, acc}, else: {:halt, result}
            end)
          else
            match
          end

        state
        |> advance(String.length(match))
        |> result(result)

      _ ->
        state
        |> result(nil)
    end
  end

  defp match_str?(nil, _re), do: false
  defp match_str?(string, re), do: Regex.match?(re, string)

  defp update_node(%__MODULE__{tree: tree} = state, node, fun) when is_reference(node) do
    node = Doctree.get_node(tree, node)
    %__MODULE__{state | tree: Doctree.put_node(tree, fun.(node))}
  end

  defp append_child(%__MODULE__{tree: tree} = state, child) do
    tree = Doctree.append_child(tree, state.node, child)
    %__MODULE__{state | tree: tree}
  end

  defp append_child(%__MODULE__{tree: tree} = state, parent, child) do
    tree = Doctree.append_child(tree, parent, child)
    %__MODULE__{state | tree: tree}
  end

  defp insert_child_after(%__MODULE__{tree: tree} = state, child, after_child) do
    tree = Doctree.insert_after(tree, after_child, child)
    %__MODULE__{state | tree: tree}
  end

  defp cut_from(%__MODULE__{tree: tree} = state, ref) do
    {tree, nodes} = Doctree.cut_from(tree, ref)
    state = %__MODULE__{state | tree: tree}
    {state, nodes}
  end

  defp cut_children_between(%__MODULE__{tree: tree} = state, from_ref, to_ref) do
    {tree, nodes} = Doctree.cut_range(tree, from_ref, to_ref)
    state = %__MODULE__{state | tree: tree}
    {state, nodes}
  end

  defp remove_node(%__MODULE__{tree: tree} = state, child) do
    tree = Doctree.remove_node(tree, child)
    %__MODULE__{state | tree: tree}
  end

  defp result(state, result), do: {state, result}
end
