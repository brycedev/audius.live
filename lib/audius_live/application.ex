defmodule AudiusLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AudiusLiveWeb.Telemetry,
      AudiusLive.Repo,
      {Phoenix.PubSub, name: AudiusLive.PubSub},
      {Finch, name: AudiusLive.Finch},
      AudiusLiveWeb.Endpoint,
      AudiusLive.Scheduler,
      {AudiusLive.Radio, name: AudiusLive.Radio}
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
end
