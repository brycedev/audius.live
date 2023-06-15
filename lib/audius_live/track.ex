defmodule AudiusLive.Track do
  use Ecto.Schema
  import Ecto.Changeset

  alias AudiusLive.Track

  schema "tracks" do
    field(:artist, :string)
    field(:audius_id, :string)
    field(:title, :string)
    field(:has_music_video, :boolean)
    field(:is_queued, :boolean)
    field(:status, Ecto.Enum, values: [stopped: 1, playing: 2, next: 3], default: :stopped)
    field(:played_at, :utc_datetime)
    timestamps()
  end

  def playing?(%Track{} = track), do: track.status == :playing
  def ready?(%Track{} = track) do
    track.status == :stopped and DateTime.diff(DateTime.utc_now(), track.played_at, :day) > 1
  end
  def stopped?(%Track{} = track), do: track.status == :stopped
  def next?(%Track{} = track), do: track.status == :next



  @doc false
  def changeset(track, attrs) do
    track
    |> cast(attrs, [:audius_id, :artist, :title])
    |> validate_required([:audius_id, :artist, :title])
    |> unique_constraint(:audius_id)
  end

  def put_duration(%Ecto.Changeset{} = changeset, duration) when is_integer(duration) do
    changeset
    |> Ecto.Changeset.change(%{duration: duration})
    |> Ecto.Changeset.validate_number(:duration,
      greater_than: 0,
      less_than: 171
    )
  end
end
