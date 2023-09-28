defmodule TalltaleWeb.LiveHelpers do
  def ok(socket) do
    {:ok, socket}
  end

  def noreply(socket) do
    {:noreply, socket}
  end

  defmodule Editor do
    use TalltaleWeb, :html

    alias Talltale.Repo

    def setup(socket, slug, tab) do
      socket
      |> ensure_tale_loaded(slug)
      |> assign(:theme, "editor")
      |> then(&put_tabs(&1, tabs(tale(&1), tab)))
    end

    def ensure_tale_loaded(socket = %{assigns: %{tale: %{slug: slug}}}, slug), do: socket

    def ensure_tale_loaded(socket, slug) do
      socket
      |> put_tale(Repo.load_tale_for_editing(slug))
    end

    def tale(%{assigns: %{tale: tale}}), do: tale
    def deck(%{assigns: %{deck: deck}}), do: deck

    def put_tale(socket, tale) do
      socket
      |> assign(:tale, tale)
    end

    def put_form(socket, source) do
      socket
      |> assign(:form, source)
    end

    def put_tabs(socket, tabs) do
      socket
      |> assign(:tabs, tabs)
    end

    def tabs(tale, current \\ :tale) do
      %{
        tabs: [
          tale: {"Tale", ~p"/edit/#{tale.slug}"},
          qualities: {"Qualities", ~p"/edit/#{tale.slug}/qualities"},
          areas: {"Areas/Locations", ~p"/edit/#{tale.slug}/areas"},
          decks: {"Card decks", ~p"/edit/#{tale.slug}/decks"}
        ],
        current: current
      }
    end

    def notify_parent(msg), do: send(self(), msg)
  end

  defmodule Game do
  end
end
