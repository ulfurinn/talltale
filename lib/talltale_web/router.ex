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

    live "/", GameLive

    live_session :editor do
      live "/edit/:tale", EditorLive

      live "/edit/:tale/qualities", EditorLive.Qualities, :index
      live "/edit/:tale/qualities/new", EditorLive.Qualities, :new
      live "/edit/:tale/quality/:slug", EditorLive.Quality, :edit

      live "/edit/:tale/decks", EditorLive.Decks, :index
      live "/edit/:tale/decks/new", EditorLive.Decks, :new
      live "/edit/:tale/deck/:id", EditorLive.Deck, :edit
      live "/edit/:tale/deck/:id/card/new", EditorLive.Deck, :new_card
      live "/edit/:tale/deck/:id/card/:card_id", EditorLive.Deck, :edit_card
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TalltaleWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:talltale, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TalltaleWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
