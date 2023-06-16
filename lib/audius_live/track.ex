defmodule AudiusLive.Track do
  use Ecto.Schema
  import Ecto.Changeset

  alias AudiusLive.Track

  schema "tracks" do
    field(:artist, :string)
    field(:audius_id, :string)
    field(:title, :string)
    field(:duration, :integer)
    field(:has_music_video, :boolean)
    field(:status, Ecto.Enum, values: [stopped: 1, playing: 2, ready: 3, next: 4], default: :stopped)
    field(:played_at, :utc_datetime)
    timestamps()
  end

  def playing?(%Track{} = track), do: track.status == :playing
  def eligible?(%Track{} = track) do
    track.status == :stopped and DateTime.diff(DateTime.utc_now(), track.played_at, :day) > 1
  end
  def stopped?(%Track{} = track), do: track.status == :stopped
  def next?(%Track{} = track), do: track.status == :next

  @doc false
  def changeset(track, attrs) do
    track
    |> cast(attrs, [:audius_id, :artist, :title, :duration])
    |> validate_required([:audius_id, :artist, :title, :duration])
    |> unique_constraint(:audius_id)
  end

end
