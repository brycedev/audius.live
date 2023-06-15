defmodule AudiusLive.VideoPlayer do

  require Logger
  import Ecto.Query, warn: false

  alias AudiusLive.Repo
  alias AudiusLive.Track
  alias AudiusLive.VideoPlayer.Events
  alias Ecto.{Multi, Changeset}

  @pubsub AudiusLive.PubSub
  @auto_next_threshold_seconds 5

  defdelegate playing?(track), to: Track
  defdelegate stopped?(track), to: Track

  def play_track(%Track{id: id}) do
    play_track(id)
  end

  def play_track(id) do
    track = get_track!(id)

    played_at =
      cond do
        playing?(track) ->
          track.played_at

        true ->
          DateTime.utc_now()
      end

    changeset =
      Changeset.change(track, %{
        played_at: DateTime.truncate(played_at, :second),
        status: :playing
      })

    {:ok, %{now_playing: next_track}} =
      Multi.new()
      |> Multi.update(:now_playing, changeset)
      |> Repo.transaction()

    elapsed = elapsed_playback(next_track)

    broadcast!(track.user_id, %Events.Play{track: track, elapsed: elapsed})

    next_track
  end

  def play_next_track_auto() do
    track = get_current_active_track()

    if track && elapsed_playback(track) >= track.duration - @auto_next_threshold_seconds do
      get_next_track()
      |> play_track()
    end
  end

  def get_current_active_track() do
    Repo.replica().one(
      from t in Track, where: t.status in [:playing]
    )
  end

  def elapsed_playback(%Track{} = track) do
    start_seconds = track.played_at |> DateTime.to_unix()
    System.os_time(:second) - start_seconds
  end

  def get_track!(id), do: Repo.replica().get!(Track, id)

  def get_next_track() do
    next =
      from(t in Track,
        where: t.status in [:next],
        limit: 1)
      |> Repo.replica().one()
        next
  end

  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  defp broadcast!(user_id, msg) when is_integer(user_id) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(user_id), {__MODULE__, msg})
  end

  defp topic(user_id) when is_integer(user_id), do: "presence:#{user_id}"

end
