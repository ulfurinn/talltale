defmodule TallTaleWeb.PlayLive.Block do
  use TallTaleWeb, :html
  embed_templates "blocks/**.html"

  def block(assigns) do
    ~H"""
    <div id={"block-#{@block["id"]}"} class="block">
      {block_content(assigns, @block["type"])}
    </div>
    """
  end

  defp block_content(assigns, type) do
    fun = String.to_atom(type <> "_block")

    if function_exported?(__MODULE__, fun, 1) do
      apply(__MODULE__, fun, [assigns])
    else
      ~H""
    end
  end
end
