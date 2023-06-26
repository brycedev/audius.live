defmodule AudiusLive.Media do
  @moduledoc """
  This module is responsible for handling video and audio related tasks.
  """
  alias AudiusLive.Track
  alias Phoenix.PubSub
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

    mp3_path = Path.absname("priv/tracks/#{track_id}/audio.mp3")
    wav_path = Path.absname("priv/tracks/#{track_id}/audio.wav")
    json_path = Path.absname("priv/tracks/#{track_id}/beats.json") 

    if !File.exists?(wav_path) do
      case System.cmd("sh", ["-c", "ffmpeg -i #{mp3_path} #{wav_path}"]) do
        {_output, 0} ->
          
          {:ok, wav_path}
        
        {output, _} ->
          {:error, "Conversion failed: #{output}"}
      end
    end

    if !File.exists?(json_path) do
      aubio_call = System.cmd("./aubioonset", [
        "--input",
        wav_path, 
        "--onset-threshold",
        "1"
        ], cd: Path.absname("priv/aubio/build/examples"))
  
      get_beats = elem(aubio_call, 0) |> String.split("\n")
  
      onset_times = Enum.take(get_beats, Enum.count(get_beats) - 1)
        |> Enum.map(&String.to_float/1)
  
      onset_time_deltas = onset_times
        |> Enum.with_index
        |> Enum.map(fn({x, i}) ->
            if i == 0 do
              x
            else
              x - Enum.at(onset_times, i - 1)
            end
          end)
  
      onset_time_deltas_to_frames = Enum.map(onset_time_deltas, fn(x) -> round(x * 24) end)
      onset_time_deltas_to_frames = Enum.map(onset_time_deltas_to_frames, fn(x) -> if x == 0 do 1 else x end end)
  
      File.write!(json_path, Jason.encode!(onset_time_deltas_to_frames))

    end
  end

  def generate_video(track_id) do
    IO.puts("Generating video...")

    video_path = "priv/videos/#{track_id}"
    gifs_path = "#{video_path}/threemotion/public/gifs"
    audio_path = "#{video_path}/threemotion/public/audio.mp3"

    System.cmd("cp", [
      "-r",
      "priv/threemotion",
      video_path
    ])

    System.cmd("rm", [
      "-rf",
      "#{gifs_path}/*}"
    ])

    System.cmd("rm", [
      audio_path
    ])

    json_file = File.read!("priv/gifs.json")
    available_gifs = Jason.decode!(json_file)["urls"]
    gifs = Enum.take_random(available_gifs, 32)

    # download gifs
    gifs
    |> Enum.with_index()
    |> Enum.each(fn {gif, i} ->
      gif_path = Path.absname("#{gifs_path}/#{i}.mp4")
      if !File.exists?(gif_path) do
        System.cmd("curl", [
          gif,
          "-o",
          gif_path
        ])
      end
    end)

    System.cmd("cp", [
      "priv/tracks/#{track_id}/audio.mp3",
      audio_path
    ])

    System.cmd("cp", [
      "priv/tracks/#{track_id}/beats.json",
      "#{video_path}/threemotion/public/beats.json"
    ])

    System.cmd(
      "npm",
      [
        "run",
        "go"
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
      video_path = "priv/videos/#{track.audius_id}"
      File.mkdir_p!(Path.absname(video_path))
      detect_beats(track.audius_id)
      generate_video(track.audius_id)
      if File.exists?("#{video_path}/musicvideo.mp4") do

        System.cmd("ffmpeg", [
          "-i",
          "#{video_path}/musicvideo.mp4",
          "-c:v",
          "libx264",
          "-crf",
          "23",
          "-preset",
          "veryfast",
          "#{video_path}/musicvideo_compressed.mp4"
        ])

        System.cmd("rm", [
          "#{video_path}/musicvideo.mp4"
        ])

        System.cmd("mv", [
          "#{video_path}/musicvideo_compressed.mp4",
          "#{video_path}/musicvideo.mp4"
        ])

        upload_video_to_r2(track.audius_id)
        changeset = Track.changeset_update(track, %{has_music_video: true})

        AudiusLive.Repo.update!(changeset)

        System.cmd("rm", [
          "-rf",
          "priv/tracks/#{track.audius_id}"
        ])
      end

      System.cmd("rm", [
        "-rf",
        "priv/videos/#{track.audius_id}"
      ])
    end
  end

  def upload_video_to_r2(track_id) do
    video_path = Path.absname("priv/videos/#{track_id}/musicvideo.mp4")

    ExAws.S3.put_object(
      "dexterslab",
      "audiuslive/videos/#{track_id}.mp4",
      File.read!(video_path)
    )
    |> ExAws.request!()
  end

  def queue_ready_video() do
    music_video_query =
      from(t in Track,
        where: t.has_music_video == true and t.status == :stopped
      )

    music_videos = AudiusLive.Repo.all(music_video_query)
    music_video_count = music_videos |> Enum.count()

    if music_video_count >= 2 do
      next_music_video = from(t in Track,
        where: t.status == :ready,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      next_track = AudiusLive.Repo.one(next_music_video)
      AudiusLive.Repo.update!(Track.changeset_update(next_track, %{status: :next}))

      ready_music_video =
          from(t in Track,
            where: t.has_music_video == true and t.status == :stopped,
            order_by: fragment("RANDOM()"),
            limit: 1
          )

      ready_track = AudiusLive.Repo.one(ready_music_video)
      AudiusLive.Repo.update!(Track.changeset_update(ready_track, %{status: :ready}))

      if !AudiusLive.Radio.running?() do
        play_next_video()
      end

    end
  end

  def play_next_video() do
    music_video_query =
      from(t in Track,
        where: t.status == :next,
        limit: 1
      )

    now_playing_track = AudiusLive.Repo.one(music_video_query)
    AudiusLive.Repo.update!(Track.changeset(now_playing_track, %{status: :playing, played_at: DateTime.utc_now()}))

    AudiusLive.Radio.start_clock(AudiusLive.Radio, now_playing_track.duration)
    PubSub.broadcast(AudiusLive.PubSub, "audius_live:track", :track_updated)
  end
end
