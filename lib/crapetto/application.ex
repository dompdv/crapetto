defmodule Crapetto.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Crapetto.Repo,
      # Start the Telemetry supervisor
      CrapettoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Crapetto.PubSub},
      # Start the Endpoint (http/https)
      CrapettoWeb.Endpoint,
      # Start a worker by calling: Crapetto.Worker.start_link(arg)
      # {Crapetto.Worker, arg}
      CrapettoWeb.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Crapetto.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CrapettoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
