defmodule TallTaleWeb.PlayLive.Block do
  use TallTaleWeb, :html
  embed_templates "blocks/**.html"

  def block(assigns) do
    ~H"""
    <div id={"block-#{@block["id"]}"} class={["block", @block["type"]]}>
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
      (no template for block type {@block["type"]})
      """
    end
  end

  defp markdown(assigns = %{node: %Tailmark.Document{}}) do
    ~H[<div class="markdown"><.markdown :for={node <- @node.children} node={node} /></div>]
  end

  defp markdown(assigns = %{node: %Tailmark.Node.Paragraph{}}) do
    ~H"<p><.markdown :for={node <- @node.children} node={node} /></p>"
  end

  defp markdown(assigns = %{node: %Tailmark.Node.Text{}}) do
    ~H"{@node.content}"
  end

  defp markdown(assigns = %{node: %Tailmark.Node.Link{}}) do
    ~H"<.markdown :for={node <- @node.children} node={node} />"
  end
end
