defmodule Subtle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SubtleWeb.Telemetry,
      # Start the Ecto repository
      Subtle.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Subtle.PubSub},
      # Start Finch
      {Finch, name: Subtle.Finch},
      # Start the Endpoint (http/https)
      SubtleWeb.Endpoint,
      # Start the PuzzleDictionary (one copy in memory)
      Subtle.PuzzleDictionary
      # Start a worker by calling: Subtle.Worker.start_link(arg)
      # {Subtle.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Subtle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SubtleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
