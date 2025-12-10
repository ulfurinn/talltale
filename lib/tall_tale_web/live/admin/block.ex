defmodule TallTaleWeb.AdminLive.Block do
  use TallTaleWeb, :html
  embed_templates "blocks/**.html"

  @block_types ["heading", "paragraph", "row", "button"]

  def block(assigns) do
    assigns = assign(assigns, :block_types, @block_types)

    ~H"""
    <div class="block">
      {common(assigns)}
      {block_content(assigns, @block["type"].value)}
    </div>
    """
  end

  defp block_content(assigns, nil) do
    blank_block(assigns)
  end

  defp block_content(assigns, type) do
    fun = String.to_atom(type <> "_block")

    if function_exported?(__MODULE__, fun, 1) do
      apply(__MODULE__, fun, [assigns])
    else
      unspecified_block(assigns)
    end
  end
end
