defimpl Phoenix.HTML.FormData, for: TallTale.Store.Quality do
  def to_form(%@for{} = quality, opts) do
    {name, opts} = Keyword.pop(opts, :as)
    name = to_string(name || "quality")
    id = Keyword.get(opts, :id) || name

    %Phoenix.HTML.Form{
      source: quality,
      impl: __MODULE__,
      options: opts,
      data: quality,
      id: id,
      name: name
    }
  end

  def input_value(%@for{} = quality, _form, :name) do
    quality.name
  end

  def input_value(%@for{} = quality, _form, :identifier) do
    quality.identifier
  end
end
