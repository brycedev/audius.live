defmodule AudiusLive.Audius do
  alias AudiusLive.{Repo, Track}
  import Ecto.Query

  def api_url_for_endpoint(endpoint) do
    url = "https://api.audius.co"
    response = HTTPoison.get!(url)
    req = Jason.decode!(response.body)
    host = Enum.random(req["data"])
    "#{host}#{endpoint}?app_name=audius_live"
  end

  def track_is_valid?(track) do
    duration = track["duration"]

    if String.contains?(track["title"], ["mix", "Mix"]) || duration > 170 ||
         track["is_streamable"] == false do
      false
    else
      true
    end
  end

  def get_random_track() do
    words =
      "priv/static/dictionary.txt"
      |> Path.expand()
      |> File.read!()
      |> String.split(~r/\n/)

    word = Enum.random(words)

    IO.puts("Searching for track with keyword: #{word}")

    endpoint = api_url_for_endpoint("/v1/tracks/search") <> "&query=#{word}"
    response = HTTPoison.get!(endpoint)
    req = Jason.decode!(response.body)

    track_results = req["data"]

    if !length(track_results) do
      get_random_track()
    end

    track = Enum.random(track_results)

    if !track_is_valid?(track) do
      get_random_track()
    end

    track
  end

  def get_random_trending_track() do
    endpoint = api_url_for_endpoint("/v1/tracks/trending") <> "&time=month"
    response = HTTPoison.get!(endpoint)
    req = Jason.decode!(response.body)

    track = Enum.random(req["data"])

    if !track_is_valid?(track) do
      get_random_trending_track()
    end

    track
  end

  def get_stream_redirect(endpoint) do
    response = HTTPoison.get!(endpoint)
    headers = Enum.into(response.headers, %{})
    location = headers["Location"] || headers["location"]

    if(location == nil) do
      IO.puts("Location is nil, retrying...")
      IO.puts(endpoint)
      get_stream_redirect(endpoint)
    end

    if(!String.contains?(location, "tracks/cidstream")) do
      IO.puts("Location does not contain tracks/cidstream, retrying...")
      get_stream_redirect(endpoint)
    end

    location
  end

  def get_stream_url(track_id) do
    endpoint = api_url_for_endpoint("/v1/tracks/#{track_id}/stream")
    location = get_stream_redirect(endpoint)
    location
  end

  def discover_next_track() do
    queued_tracks = Repo.all(from(t in Track, where: t.is_queued == true))

    count = Enum.count(queued_tracks)

    if count < 5 do
      track = get_random_trending_track()

      track_exists = Repo.get_by(Track, audius_id: track["id"])

      if track_exists !== nil do
        track = get_random_track()
      end

      IO.puts("Discovered new track: #{track["title"]} by #{track["user"]["name"]}")

      IO.puts("Fetching stream URL...")

      track_id = track["id"]

      stream_url = AudiusLive.Audius.get_stream_url(track_id)

      IO.puts("Recording audio stream...")

      AudiusLive.Media.record_audio_stream(
        stream_url,
        track_id,
        track["duration"],
        "priv/static/tracks/#{track_id}/audio.mp3"
      )

      Repo.insert(%Track{
        audius_id: track["id"],
        artist: track["user"]["name"],
        title: track["title"]
      })

      AudiusLive.Media.generate_music_video(track)
    end
  end
end
