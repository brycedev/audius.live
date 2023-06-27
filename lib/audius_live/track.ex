defmodule AudiusLive.Track do
  @moduledoc """
  Track model
  """
  use Ecto.Schema

  schema "tracks" do
    field(:artist, :string)
    field(:audius_id, :string)
    field(:title, :string)
    field(:duration, :integer)
    field(:has_music_video, :boolean)
    field(:status, Ecto.Enum, values: [stopped: 1, next: 2, playing: 3], default: :stopped)
    field(:played_at, :utc_datetime)
    timestamps()
  end

end
