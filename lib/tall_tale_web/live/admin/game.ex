defmodule TallTaleWeb.AdminLive.Game do
  use TallTaleWeb, :live_view
  alias TallTale.Admin
  alias TallTale.Store.Game
  alias TallTaleWeb.AdminLive.Block

  embed_templates "tabs/**.html"
  embed_templates "panels/**.html"

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
    %{"block_order" => block_order} = params

    blocks =
      case params do
        %{"screen" => %{"blocks" => blocks}} -> blocks
        _ -> %{}
      end

    blocks =
      Enum.map(block_order, fn index ->
        Map.get_lazy(blocks, index, fn ->
          id = Uniq.UUID.uuid7()
          name = "block_#{index}"
          %{"id" => id, "name" => name}
        end)
      end)

    {:ok, screen} = Admin.put_screen_blocks(screen, blocks)

    socket
    |> assign_screen(screen)
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
end
