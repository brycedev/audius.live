defmodule AudiusLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AudiusLiveWeb.Telemetry,
      # Start the Ecto repository
      AudiusLive.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: AudiusLive.PubSub},
      # Start Finch
      {Finch, name: AudiusLive.Finch},
      # Start the Endpoint (http/https)
      AudiusLiveWeb.Endpoint,
      # Start a worker by calling: AudiusLive.Worker.start_link(arg)
      # {AudiusLive.Worker, arg}
      AudiusLive.Scheduler,
      :poolboy.child_spec(:worker, python_poolboy_config())
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AudiusLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AudiusLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp python_poolboy_config do
    [
      {:name, {:local, :python_worker}},
      {:worker_module, AudiusLive.Snek},
      {:size, 1},
      {:max_overflow, 2}
    ]
  end
end
