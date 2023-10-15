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
    def area(%{assigns: %{area: area}}), do: area
    def storylet(%{assigns: %{storylet: storylet}}), do: storylet

    def put_tale(socket, tale), do: assign(socket, :tale, tale)
    def put_quality(socket, quality), do: assign(socket, :quality, quality)
    def put_deck(socket, deck), do: assign(socket, :deck, deck)
    def put_card(socket, card), do: assign(socket, :card, card)
    def put_area(socket, area), do: assign(socket, :area, area)
    def put_location(socket, location), do: assign(socket, :location, location)
    def put_storylet(socket, storylet), do: assign(socket, :storylet, storylet)
    def put_form(socket, source), do: assign(socket, :form, source)

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
          decks: {"Card decks", ~p"/edit/#{tale.slug}/decks"},
          storylets: {"Storylets", ~p"/edit/#{tale.slug}/storylets"}
        ],
        current: current
      }
    end

    def notify_view(msg), do: send(self(), msg)
  end

  defmodule Game do
  end
end
