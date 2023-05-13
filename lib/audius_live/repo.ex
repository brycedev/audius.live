defmodule AudiusLive.Repo do
  use Ecto.Repo,
    otp_app: :audius_live,
    adapter: Ecto.Adapters.Postgres
end
