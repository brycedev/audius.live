defmodule AudiusLive.Media do
  alias AudiusLive.Track
  import Ecto.Query

  def record_audio_stream(url, track_id, duration, output_file_path) do
    File.mkdir_p!(Path.dirname(output_file_path))

    {_output, status} =
      System.cmd("ffmpeg", [
        "-i",
        url,
        "-ss",
        to_string(0),
        "-t",
        to_string(duration),
        "-c",
        "copy",
        "-y",
        output_file_path
      ])

    if status !== 0 do
      stream_url = AudiusLive.Audius.get_stream_url(track_id)
      record_audio_stream(stream_url, track_id, duration, output_file_path)
    end
  end

  def detect_beats(track_id) do
    IO.puts("Detecting beats...")

    track_path = Path.absname("priv/static/tracks/#{track_id}/audio.mp3")

    detection_result = AudiusLive.Snek.detect_beats(track_path)
    beat_times = Jason.decode!(elem(detection_result, 1))
    File.write!("priv/static/tracks/#{track_id}/beats.json", Jason.encode!(beat_times))
  end

  def generate_video(track_id) do
    IO.puts("Generating video...")

    _track_path = Path.absname("priv/static/tracks/#{track_id}")
    json_file = File.read!("priv/static/gifs.json")
    available_gifs = Jason.decode!(json_file)["urls"]

    gifs = Enum.take_random(available_gifs, 32)

    download_path = Path.absname("priv/static/videos/#{track_id}/gifs")
    File.mkdir_p!(download_path)

    # download gifs
    gifs
    |> Enum.with_index()
    |> Enum.each(fn {gif, i} ->
      gif_path = Path.absname("priv/static/videos/#{track_id}/gifs/#{i}.mp4")

      if !File.exists?(gif_path) do
        System.cmd("curl", [
          gif,
          "-o",
          gif_path
        ])
      end
    end)

    System.cmd("cp", [
      "-r",
      "priv/threemotion",
      "priv/static/videos/#{track_id}"
    ])

    System.cmd("rm", [
      "-rf",
      "priv/static/videos/#{track_id}/threemotion/public/gifs"
    ])

    System.cmd("mv", [
      "priv/static/videos/#{track_id}/gifs",
      "priv/static/videos/#{track_id}/threemotion/public/gifs"
    ])

    System.cmd("rm", [
      "priv/static/videos/#{track_id}/threemotion/public/audio.mp3"
    ])

    System.cmd("cp", [
      "priv/static/tracks/#{track_id}/audio.mp3",
      "priv/static/videos/#{track_id}/threemotion/public/audio.mp3"
    ])

    System.cmd("cp", [
      "priv/static/tracks/#{track_id}/beats.json",
      "priv/static/videos/#{track_id}/threemotion/public/beats.json"
    ])

    System.cmd(
      "npm",
      [
        "run",
        "go"
      ],
      cd: "#{Path.absname("priv/static/videos/#{track_id}/threemotion")}"
    )
  end

  def compose_music_video() do
    query =
      from(t in Track,
        where: t.has_music_video == false,
        order_by: fragment("RANDOM()"),
        limit: 1
      )

    if track = AudiusLive.Repo.one(query) do
      detect_beats(track.audius_id)
      generate_video(track.audius_id)
      if(File.exists?("priv/static/videos/#{track.audius_id}/musicvideo.mp4")) do
        upload_video_to_r2(track.audius_id)
        changeset = Track.changeset(track, %{has_music_video: true})

        AudiusLive.Repo.update!(changeset)
      end

      System.cmd("rm", [
        "-rf",
        "priv/static/videos/#{track.audius_id}"
      ])

      System.cmd("rm", [
        "-rf",
        "priv/static/tracks/#{track.audius_id}"
      ])
      
    end
  end

  def upload_video_to_r2(track_id) do
    video_path = Path.absname("priv/static/videos/#{track_id}/musicvideo.mp4")

    ExAws.S3.put_object(
      System.get_env("R2_BUCKET_NAME"),
      "audiuslive/videos/#{track_id}.mp4",
      File.read!(video_path)
    )
    |> ExAws.request!()
  end

  def queue_next_video() do
    music_video_query =
      from(t in Track,
        where: t.has_music_video == true
      )

    music_video_count =
      AudiusLive.Repo.all(music_video_query)
      |> Enum.count()

    if music_video_count > 2 do
      queue_query = from(t in Track, where: t.is_queued == true)

      if AudiusLive.Repo.all(queue_query) |> Enum.count() < 2 do
        music_video_query =
          from(t in Track,
            where: t.has_music_video == true and t.is_queued == false,
            order_by: fragment("RANDOM()"),
            limit: 1
          )

        track = AudiusLive.Repo.one(music_video_query)
        AudiusLive.Repo.update!(Track.changeset(track, %{is_queued: true}))
      end
    end
  end
end
