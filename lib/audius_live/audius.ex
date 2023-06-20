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
    
    query =
      from(t in AudiusLive.Track,
        where: t.audius_id == ^track["id"],
        limit: 1
      )

    is_valid = true

    if AudiusLive.Repo.one(query) do
      is_valid = false
    end

    if duration > 150 do
      IO.puts("Track duration is too long: #{duration}")
      is_valid = false
    end

    if track["is_streamable"] == false do
      is_valid = false
    end

    is_valid

  end

  def get_random_track() do
    # random_endpoint = api_url_for_endpoint("/v1/tracks/search") <> "&query=#{word}"
    all_time_trending_endpoint = api_url_for_endpoint("/v1/tracks/trending") <> "&time=allTime"
    month_trending_endpoint = api_url_for_endpoint("/v1/tracks/trending") <> "&time=month"
    underground_trending_endpoint = api_url_for_endpoint("/v1/tracks/trending/underground")
    week_trending_endpoint = api_url_for_endpoint("/v1/tracks/trending") <> "&time=week"
    year_trending_endpoint = api_url_for_endpoint("/v1/tracks/trending") <> "&time=year"

    response =
      HTTPoison.get!(
        Enum.random([
          all_time_trending_endpoint,
          month_trending_endpoint,
          underground_trending_endpoint,
          week_trending_endpoint,
          year_trending_endpoint
        ])
      )

    req = Jason.decode!(response.body)

    track_results = req["data"]

    if !length(track_results) do
      get_random_track()
    end

    track = Enum.random(track_results)

    if track_is_valid?(track) do
      Repo.insert(%Track{
        audius_id: track["id"],
        artist: track["user"]["name"],
        duration: track["duration"],
        title: track["title"]
      })

      IO.puts("Discovered new track: #{track["title"]} by #{track["user"]["name"]}")

      track_id = track["id"]

      stream_url = AudiusLive.Audius.get_stream_url(track_id)

      AudiusLive.Media.record_audio_stream(
        stream_url,
        track_id,
        track["duration"],
        "priv/static/tracks/#{track_id}/audio.mp3"
      )
      
    else
      get_random_track()
    end
  end

  def get_stream_redirect(endpoint) do
    response = HTTPoison.get!(endpoint)
    headers = Enum.into(response.headers, %{})
    location = headers["Location"] || headers["location"]

    if location == nil do
      get_stream_redirect(endpoint)
    end

    if !String.contains?(location, "tracks/cidstream") do
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
    backlog = Repo.all(from(t in Track, where: t.has_music_video == false))

    count = Enum.count(backlog)

    if count < 10 do
      get_random_track()
    end
  end
end
