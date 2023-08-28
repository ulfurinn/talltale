defmodule Talltale.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TalltaleWeb.Telemetry,
      # Start the Ecto repository
      Talltale.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Talltale.PubSub},
      # Start Finch
      {Finch, name: Talltale.Finch},
      # Start the Endpoint (http/https)
      TalltaleWeb.Endpoint
      # Start a worker by calling: Talltale.Worker.start_link(arg)
      # {Talltale.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Talltale.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TalltaleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
