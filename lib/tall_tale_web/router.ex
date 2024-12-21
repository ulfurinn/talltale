defmodule TallTaleWeb.Router do
  use TallTaleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TallTaleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TallTaleWeb do
    pipe_through :browser

    live_session :admin, layout: {TallTaleWeb.Layouts, :admin} do
      live "/admin", AdminLive.Index, :index
      live "/admin/:game", AdminLive.Game, :game
      live "/admin/:game/:tab", AdminLive.Game, :game
      live "/admin/:game/:tab/:tab_param", AdminLive.Game, :game
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TallTaleWeb do
  #   pipe_through :api
  # end
end
