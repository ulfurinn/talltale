defmodule TalltaleWeb.Router do
  # alias TalltaleWeb.EditorLive
  use TalltaleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TalltaleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TalltaleWeb do
    pipe_through :browser

    live "/play/:tale", Game
  end
end
