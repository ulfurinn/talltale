defmodule TallTaleWeb.AdminLive.Action do
  use TallTaleWeb, :html
  embed_templates "actions/**.html"

  @action_types ["screen"]

  def action(assigns) do
    assigns = assign(assigns, :action_types, @action_types)

    ~H"""
    <div class="action">
      {common(assigns)}
      {action_content(assigns, @action["type"].value)}
    </div>
    """
  end

  defp action_content(assigns, nil) do
    blank_action(assigns)
  end

  defp action_content(assigns, type) do
    fun = String.to_atom(type <> "_action")

    if function_exported?(__MODULE__, fun, 1) do
      apply(__MODULE__, fun, [assigns])
    else
      unspecified_action(assigns)
    end
  end
end
