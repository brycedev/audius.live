defmodule AudiusLive.Media do
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

  def generate_music_video(track) do
    IO.puts("Detecting beats...")

    detection_result =
      AudiusLive.Snek.detect_beats(Path.absname("priv/static/tracks/#{track["id"]}/audio.mp3"))

    IO.inspect(detection_result)
    IO.puts("Fetching assets...")
    IO.puts("Generating video...")
  end
end
