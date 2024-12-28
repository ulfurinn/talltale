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

  defp block_content(assigns, type)

  defp block_content(assigns, "heading") do
    heading_block(assigns)
  end

  defp block_content(assigns, "button") do
    button_block(assigns)
  end

  defp block_content(assigns, _) do
    unspecified_block(assigns)
  end
end
