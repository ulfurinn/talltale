defmodule TallTaleWeb.AdminLive.Game do
  alias TallTale.Store.Screen
  use TallTaleWeb, :live_view
  alias TallTale.Admin
  alias TallTale.Store.Game

  embed_templates "tabs/**.html"
  embed_templates "panels/**.html"
  embed_templates "blocks/**.html"

  @tabs [
    %{id: "screens", label: "Screens"},
    %{id: "qualities", label: "Qualities"},
    %{id: "general", label: "General"}
  ]

  def mount(%{"game" => game_name}, _session, socket) do
    socket
    |> assign_game(game_name)
    |> assign_tabs()
    |> assign_defaults()
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    socket
    |> assign_tab(params)
    |> assign_tab_param(params)
    |> noreply()
  end

  def handle_event("create-screen", params, socket) do
    %{game: game} = socket.assigns

    case Admin.create_screen(game, params) do
      {:ok, screen} ->
        socket
        |> assign_game(Admin.reload_game(game))
        |> push_patch(to: ~p"/admin/#{game}/screens/#{screen}")
        |> noreply()

      {:error, _reason} ->
        socket |> noreply()
    end
  end

  def handle_event("update-screen", params, socket) do
    %{screen: screen} = socket.assigns
    %{"blocks" => blocks, "block_order" => block_order} = params

    blocks = Enum.map(block_order, &blocks[&1])
    {:ok, screen} = Admin.put_screen_blocks(screen, blocks)

    socket
    |> assign_screen(screen)
    |> noreply()
  end

  def handle_event("add-block", _, socket) do
    %{screen: screen} = socket.assigns

    socket
    |> assign_screen(%Screen{screen | blocks: screen.blocks ++ [%{}]})
    |> noreply()
  end

  defp tab(assigns) do
    %{tab: tab} = assigns
    apply(__MODULE__, String.to_existing_atom(tab), [assigns])
  end

  defp assign_game(socket, game_name) when is_binary(game_name) do
    assign_game(socket, TallTale.Admin.load_game(game_name))
  end

  defp assign_game(socket, %Game{} = game) do
    assign(socket, :game, game)
  end

  defp assign_tabs(socket) do
    assign(socket, :tabs, @tabs)
  end

  defp assign_defaults(socket) do
    socket |> assign_screen(nil)
  end

  defp assign_tab(socket, %{"tab" => tab}) do
    assign_tab(socket, tab)
  end

  defp assign_tab(socket, %{}) do
    assign_tab(socket, List.first(@tabs).id)
  end

  defp assign_tab(socket, tab) do
    assign(socket, :tab, tab)
  end

  defp assign_tab_param(%{assigns: %{tab: "screens"}} = socket, %{"tab_param" => screen_id}) do
    %{game: game} = socket.assigns
    %Game{screens: screens} = game

    socket
    |> assign_screen(Enum.find(screens, &(&1.id == screen_id)))
  end

  defp assign_tab_param(socket, _params) do
    socket
  end

  defp assign_screen(socket, screen) do
    assign(socket, :screen, screen)
  end

  defp block(assigns) do
    ~H"""
    <div class="block">
      <input type="hidden" name="block_order[]" value={@index} />
      <.input
        type="select"
        name={"blocks[#{@index}][type]"}
        value={@block["type"]}
        options={["heading"]}
        prompt="Type"
      />
      {block_content(assigns)}
    </div>
    """
  end

  defp block_content(assigns)

  defp block_content(assigns) do
    unspecified(assigns)
  end
end
