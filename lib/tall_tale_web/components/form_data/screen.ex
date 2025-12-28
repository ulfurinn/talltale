defimpl Phoenix.HTML.FormData, for: TallTale.Store.Screen do
  def to_form(%@for{} = screen, opts) do
    {name, opts} = Keyword.pop(opts, :as)
    name = to_string(name || "screen")
    id = Keyword.get(opts, :id) || name

    %Phoenix.HTML.Form{
      source: screen,
      impl: __MODULE__,
      options: opts,
      data: screen,
      id: id,
      name: name
    }
  end

  def to_form(%@for{} = screen, form, :blocks, opts) do
    {name, opts} = Keyword.pop(opts, :as)
    {id, opts} = Keyword.pop(opts, :id)
    id = to_string(id || form.id <> "_blocks")
    name = to_string(name || form.name <> "[blocks]")

    for {block, index} <- Enum.with_index(screen.blocks) do
      index_string = Integer.to_string(index)

      %Phoenix.HTML.Form{
        source: block,
        impl: __MODULE__,
        options: opts,
        data: block,
        index: index,
        id: id <> "_" <> index_string,
        name: name <> "[" <> index_string <> "]",
        hidden: [{"id", block["id"]}]
      }
    end
  end

  def to_form(%@for{} = screen, form, :actions, opts) do
    {name, opts} = Keyword.pop(opts, :as)
    {id, opts} = Keyword.pop(opts, :id)
    id = to_string(id || form.id <> "_actions")
    name = to_string(name || form.name <> "[actions]")

    for {action, index} <- Enum.with_index(screen.actions) do
      index_string = Integer.to_string(index)

      %Phoenix.HTML.Form{
        source: action,
        impl: __MODULE__,
        options: opts,
        data: action,
        index: index,
        id: id <> "_" <> index_string,
        name: name <> "[" <> index_string <> "]",
        hidden: [{"id", action["id"]}]
      }
    end
  end

  def to_form(nested, form, field, opts) when not is_struct(nested, @for) and is_map(nested) do
    {name, opts} = Keyword.pop(opts, :as)
    {id, opts} = Keyword.pop(opts, :id)
    id = to_string(id || form.id <> "_#{field}")
    name = to_string(name || form.name <> "[#{field}]")

    case Map.get(nested, field, default(field)) do
      nil ->
        [
          %Phoenix.HTML.Form{
            source: %{},
            impl: __MODULE__,
            options: opts,
            data: %{},
            id: id,
            name: name
          }
        ]

      list when is_list(list) ->
        for {element, index} <- Enum.with_index(list) do
          index_string = Integer.to_string(index)

          %Phoenix.HTML.Form{
            source: element,
            impl: __MODULE__,
            options: opts,
            data: element,
            index: index,
            id: id <> "_" <> index_string,
            name: name <> "[" <> index_string <> "]",
            hidden:
              if is_map(element) && Map.has_key?(element, "id") do
                [{"id", element["id"]}]
              else
                []
              end
          }
        end

      element ->
        [
          %Phoenix.HTML.Form{
            source: element,
            impl: __MODULE__,
            options: opts,
            data: element,
            id: id,
            name: name
          }
        ]
    end
  end

  def input_value(%@for{} = screen, _form, :blocks) do
    screen.blocks
  end

  def input_value(%@for{} = screen, _form, :actions) do
    screen.actions
  end

  def input_value(nested, _form, field) when not is_struct(nested, @for) and is_map(nested) do
    Map.get(nested, field, default(field))
  end

  def input_validations(_, _, _), do: []

  defp default(field)
  defp default("blocks"), do: []
  defp default("actions"), do: []
  defp default(_), do: nil
end
