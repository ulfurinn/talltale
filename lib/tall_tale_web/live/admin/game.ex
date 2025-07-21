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

  def handle_event("create-quality", %{"quality" => params}, socket) do
    %{game: game} = socket.assigns

    case Admin.create_quality(game, params) do
      {:ok, quality} ->
        socket
        |> assign_game(Admin.reload_game(game))
        |> push_patch(to: ~p"/admin/#{game}/qualities/#{quality}")
        |> noreply()

      {:error, _reason} ->
        socket |> noreply()
    end
  end

  def handle_event("update-screen", params, socket) do
    %{screen: screen} = socket.assigns

    params = process_block_indexes(params)
    %{"screen" => %{"blocks" => blocks}} = params

    {:ok, screen} = Admin.put_screen_blocks(screen, blocks)

    socket
    |> assign_screen(screen)
    |> noreply()
  end

  def handle_event("update-game", params, socket) do
    %{game: game} = socket.assigns
    %{"game" => params} = params

    case Admin.update_game(game, params) do
      {:ok, game} ->
        socket
        |> assign_game(game)
        |> noreply()

      {:error, reason} ->
        dbg(reason)
        socket |> noreply()
    end
  end

  defp process_block_indexes(params) when is_map(params) do
    params =
      case params do
        %{"block_order" => block_order} ->
          blocks = Map.get(params, "blocks", %{})

          blocks =
            Enum.map(block_order, fn index ->
              remove_internal_fields(
                Map.get_lazy(blocks, index, fn ->
                  id = Uniq.UUID.uuid7()
                  name = "block_#{index}"
                  %{"id" => id, "name" => name}
                end)
              )
            end)

          Map.put(params, "blocks", blocks)

        _ ->
          params
      end

    Enum.into(params, %{}, fn {k, v} ->
      {k, process_block_indexes(v)}
    end)
  end

  defp process_block_indexes(list) when is_list(list) do
    Enum.map(list, &process_block_indexes/1)
  end

  defp process_block_indexes(value), do: value

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
    socket
    |> assign_screen(nil)
    |> assign_quality(nil)
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

  defp assign_tab_param(%{assigns: %{tab: "qualities"}} = socket, %{"tab_param" => quality_id}) do
    %{game: game} = socket.assigns
    %Game{qualities: qualities} = game

    socket
    |> assign_quality(Enum.find(qualities, &(&1.id == quality_id)))
  end

  defp assign_tab_param(socket, _params) do
    socket
  end

  defp assign_screen(socket, screen) do
    assign(socket, :screen, screen)
  end

  defp assign_quality(socket, quality) do
    assign(socket, :quality, quality)
  end

  defp remove_internal_fields(term)

  defp remove_internal_fields(map) when is_map(map) do
    map
    |> Stream.reject(fn {key, _} -> String.starts_with?(key, "_") end)
    |> Stream.map(fn {key, value} -> {key, remove_internal_fields(value)} end)
    |> Enum.into(%{})
  end

  defp remove_internal_fields(list) when is_list(list) do
    Enum.map(list, &remove_internal_fields/1)
  end

  defp remove_internal_fields(term), do: term
end
