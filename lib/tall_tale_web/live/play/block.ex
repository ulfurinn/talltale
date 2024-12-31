defmodule TallTaleWeb.PlayLive.Block do
  use TallTaleWeb, :html
  embed_templates "blocks/**.html"

  def block(assigns) do
    ~H"""
    <div id={"block-#{@block["id"]}"} phx-hook="Animated" class={["block", @block["type"]]}>
      {block_content(assigns, @block["type"])}
    </div>
    """
  end

  defp block_content(assigns, type) do
    fun = String.to_atom(type <> "_block")

    if function_exported?(__MODULE__, fun, 1) do
      apply(__MODULE__, fun, [assigns])
    else
      ~H"""
      no template found for block type {@block["type"]}
      """
    end
  end
end
