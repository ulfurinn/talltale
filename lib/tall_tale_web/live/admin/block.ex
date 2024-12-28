defmodule TallTaleWeb.AdminLive.Block do
  use TallTaleWeb, :html
  embed_templates "blocks/**.html"

  def block(assigns) do
    ~H"""
    <div class="block">
      {common(assigns)}
      {block_content(assigns, @block["type"].value)}
    </div>
    """
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
