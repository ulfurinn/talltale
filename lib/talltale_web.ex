defmodule TalltaleWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use TalltaleWeb, :controller
      use TalltaleWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: TalltaleWeb.Layouts]

      import Plug.Conn
      import TalltaleWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view(args \\ []) do
    quote do
      use Phoenix.LiveView,
        layout: {TalltaleWeb.Layouts, unquote(args)[:mode] || :game}

      unquote(html_helpers())
      unquote(live_helpers(args[:mode] || :game))
    end
  end

  def live_component(args \\ []) do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
      unquote(live_helpers(args[:mode] || :game))
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      import Phoenix.HTML.Tag
      # Core UI components and translation
      import TalltaleWeb.CoreComponents
      import TalltaleWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  defp live_helpers() do
    quote do
      import TalltaleWeb.LiveHelpers
    end
  end

  defp live_helpers(:game) do
    quote do
      import TalltaleWeb.LiveHelpers
      import TalltaleWeb.LiveHelpers.Game
    end
  end

  defp live_helpers(:editor) do
    quote do
      import TalltaleWeb.LiveHelpers
      import TalltaleWeb.LiveHelpers.Editor

      alias Talltale.Editor.Area
      alias Talltale.Editor.Card
      alias Talltale.Editor.Deck
      alias Talltale.Editor.Location
      alias Talltale.Editor.Quality
      alias Talltale.Editor.Tale
      alias Talltale.Repo
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: TalltaleWeb.Endpoint,
        router: TalltaleWeb.Router,
        statics: TalltaleWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__([which | args]) when is_atom(which) do
    apply(__MODULE__, which, [args])
  end
end
