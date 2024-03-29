# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :audius_live,
  ecto_repos: [AudiusLive.Repo]

# Configures the endpoint
config :audius_live, AudiusLiveWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: AudiusLiveWeb.ErrorHTML, json: AudiusLiveWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AudiusLive.PubSub,
  live_view: [signing_salt: "i8X/PYbH"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/models/* --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger,
  backends: [:console, {LoggerFileBackend, :error_log}, {LoggerFileBackend, :info_log}],
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :error_log,
  path: "/var/log/audius_live/error.log",
  level: :error

config :logger, :info_log,
  path: "/var/log/audius_live/info.log",
  level: :info

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_aws,
  access_key_id: System.get_env("R2_ACCESS_KEY_ID"),
  region: "auto",
  max_attempts: 3,
  secret_access_key: System.get_env("R2_SECRET_ACCESS_KEY"),
  s3: [
    scheme: "https://",
    host: "#{System.get_env("R2_ACCOUNT_ID")}.r2.cloudflarestorage.com"
  ]

# Configure the scheduler (Quantum)
config :audius_live, AudiusLive.Scheduler,
  jobs: [
    {"* * * * *", {AudiusLive.Audius, :discover_next_track, []}},
    {"* * * * *", {AudiusLive.Media, :start_station, []}},
    {"*/5 * * * *", {AudiusLive.Media, :compose_music_video, []}}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
