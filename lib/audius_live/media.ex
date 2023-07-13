defmodule AudiusLive.Media do
  @moduledoc """
  This module is responsible for handling video and audio related tasks.
  """
  alias Phoenix.PubSub
  alias AudiusLive.{Track, Repo}
  import Ecto.Query
  require Logger

  def record_audio_stream(url, track_id, duration, output_file_path) do
    {_output, status} =
      System.cmd("ffmpeg", [
        "-hide_banner",
        "-loglevel",
        "error",
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
    Logger.info("Detecting beats...")

    mp3_path = System.user_home() |> Path.join("/audius_live/tracks/#{track_id}/audio.mp3")
    wav_path = System.user_home() |> Path.join("/audius_live/tracks/#{track_id}/audio.wav")
    json_path = System.user_home() |> Path.join("/audius_live/tracks/#{track_id}/beats.json")

    if !File.exists?(wav_path) do
      case System.cmd("sh", [
             "-c",
             "ffmpeg -hide_banner -loglevel error -i #{mp3_path} #{wav_path}"
           ]) do
        {_output, 0} ->
          {:ok, wav_path}

        {output, _} ->
          {:error, "Conversion failed: #{output}"}
      end
    end

    if !File.exists?(json_path) do
      aubio_path = :code.priv_dir(:audius_live) |> Path.join("/aubio/build/examples/aubioonset")

      aubio_call =
        System.cmd(
          "sh",
          [
            "-c",
            "#{aubio_path} --input #{wav_path} --onset-threshold 1"
          ]
        )

      get_beats = elem(aubio_call, 0) |> String.split("\n")

      onset_times =
        Enum.take(get_beats, Enum.count(get_beats) - 1)
        |> Enum.map(&String.to_float/1)

      onset_time_deltas =
        onset_times
        |> Enum.with_index()
        |> Enum.map(fn {x, i} ->
          if i == 0 do
            x
          else
            x - Enum.at(onset_times, i - 1)
          end
        end)

      onset_time_deltas_to_frames = Enum.map(onset_time_deltas, fn x -> round(x * 24) end)

      onset_time_deltas_to_frames =
        Enum.map(onset_time_deltas_to_frames, fn x ->
          if x == 0 do
            1
          else
            x
          end
        end)

      File.write!(json_path, Jason.encode!(onset_time_deltas_to_frames))
    end
  end

  def generate_video(track_id) do
    Logger.info("Generating video...")

    threemotion_path = :code.priv_dir(:audius_live) |> Path.join("/threemotion")

    video_path = System.user_home() |> Path.join("/audius_live/videos/#{track_id}")
    File.mkdir_p!(video_path)

    gifs_path = "#{video_path}/threemotion/public/gifs"
    audio_path = "#{video_path}/threemotion/public/audio.mp3"

    File.cp_r!(threemotion_path, "#{video_path}/threemotion")

    File.mkdir_p!(gifs_path)

    json_file = File.read!(:code.priv_dir(:audius_live) |> Path.join("/gifs.json"))
    available_gifs = Jason.decode!(json_file)["urls"]
    gifs = Enum.take_random(available_gifs, 32)

    # download gifs
    gifs
    |> Enum.with_index()
    |> Enum.each(fn {gif, i} ->
      gif_path = "#{gifs_path}/#{i}.mp4"

      if !File.exists?(gif_path) do
        System.cmd("curl", [
          gif,
          "-o",
          gif_path
        ])
      end
    end)

    File.cp!(
      System.user_home() |> Path.join("/audius_live/tracks/#{track_id}/audio.mp3"),
      audio_path
    )

    File.cp!(
      System.user_home() |> Path.join("/audius_live/tracks/#{track_id}/beats.json"),
      "#{video_path}/threemotion/public/beats.json"
    )

    Logger.info("Building video...")

    Logger.info("Installing threemotion dependencies...")

    System.cmd(
      "npm",
      [
        "install",
        "--legacy-peer-deps"
      ],
      cd: "#{video_path}/threemotion"
    )

    Logger.info("Building threemotion video...")

    video_output = "#{video_path}/musicvideo.mp4"

    Logger.info("Video output: #{video_output}")

    System.cmd(
      "sed",
      [
        "-i",
        '"s|videoout|#{video_output}|g"',
        "package.json"
      ],
      cd: "#{video_path}/threemotion"
    )

    System.cmd(
      "npm",
      [
        "run",
        "build"
      ],
      cd: "#{video_path}/threemotion"
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
      video_path = System.user_home() |> Path.join("/audius_live/videos/#{track.audius_id}")
      track_path = System.user_home() |> Path.join("/audius_live/tracks/#{track.audius_id}")
      File.mkdir_p!(video_path)
      detect_beats(track.audius_id)
      generate_video(track.audius_id)

      Logger.info("Generated music video")

      Logger.info("Checking for file existence...")

      if File.exists?("#{video_path}/musicvideo.mp4") do
        Logger.info("Compressing video...")

        System.cmd("ffmpeg", [
          "-hide_banner",
          "-loglevel",
          "error",
          "-i",
          "#{video_path}/musicvideo.mp4",
          "-c:v",
          "libx265",
          "-crf",
          "28",
          "#{video_path}/musicvideo_compressed.mp4"
        ])

        System.cmd("rm", [
          "#{video_path}/musicvideo.mp4"
        ])

        upload_video_to_r2(track.audius_id)

        Track |> where(id: ^track.id) |> Repo.update_all(set: [has_music_video: true])

        System.cmd("rm", [
          "-rf",
          track_path
        ])
      end

      # System.cmd("rm", [
      #   "-rf",
      #   video_path
      # ])
    end
  end

  def upload_video_to_r2(track_id) do
    Logger.info("Uploading video to R2...")

    video_path =
      System.user_home()
      |> Path.join("/audius_live/videos/#{track_id}/musicvideo_compressed.mp4")

    ExAws.S3.put_object(
      "dexterslab",
      "audiuslive/videos/#{track_id}.mp4",
      File.read!(video_path)
    )
    |> ExAws.request()

    case HTTPoison.get("https://cdn.dexterslab.sh/audiuslive/videos/#{track_id}.mp4") do
      {:ok, %{status_code: 200}} ->
        Logger.info("Video upload successful")

      _ ->
        Logger.error("Video upload failed")
        upload_video_to_r2(track_id)
    end
  end

  def start_station() do
    playing_track_query =
      from(t in Track,
        where: t.status == :playing
      )

    if !AudiusLive.Repo.one(playing_track_query) do
      music_video_query =
        from(t in Track,
          where: t.has_music_video == true and t.status != :playing
        )

      music_videos = AudiusLive.Repo.all(music_video_query)
      music_video_count = music_videos |> Enum.count()

      if music_video_count >= 2 do
        queue_next_video()
      end

      play_next_video()
    end
  end

  def prepare_next_video() do
    Track |> where(status: :playing) |> Repo.update_all(set: [status: :stopped])
  end

  def play_next_video() do
    music_video_query =
      from(t in Track,
        where: t.status == :next,
        limit: 1
      )

    if now_playing_track = AudiusLive.Repo.one(music_video_query) do
      Track
      |> where(id: ^now_playing_track.id)
      |> Repo.update_all(set: [status: :playing, played_at: DateTime.utc_now()])

      AudiusLive.Radio.play_song(
        AudiusLive.Radio,
        now_playing_track.duration,
        "https://cdn.dexterslab.sh/audiuslive/videos/#{now_playing_track.audius_id}.mp4"
      )

      PubSub.broadcast(AudiusLive.PubSub, "audius_live:track", :track_updated)
    end
  end

  def queue_next_video() do
    if !AudiusLive.Repo.one(from(t in Track, where: t.status == :next)) do
      ready_track_query =
        from(t in Track,
          where: t.status == :stopped and t.has_music_video == true,
          order_by: fragment("RANDOM()"),
          limit: 1
        )

      if ready_track = AudiusLive.Repo.one(ready_track_query) do
        Track |> where(id: ^ready_track.id) |> Repo.update_all(set: [status: :next])
        play_next_video()
      end
    end
  end
end
