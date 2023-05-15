defmodule AudiusLive.Snek do
  use GenServer

  @timeout 20_000

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_args) do
    path =
      [:code.priv_dir(:audius_live), "python"]
      |> Path.join()

    with {:ok, pid} <- :python.start([{:python_path, to_charlist(path)}, {:python, 'python'}]) do
      IO.puts("[#{__MODULE__}] Started python worker")
      {:ok, pid}
    end
  end

  @impl true
  def handle_call({:detect, audio_path}, _from, pid) do
    result = :python.call(pid, :detect_beats, :detect, [audio_path])
    {:reply, {:ok, result}, pid}
  end

  @impl true
  def handle_call({:generate, audio_path, beat_times}, _from, pid) do
    result = :python.call(pid, :music_video, :generate, [audio_path, beat_times])
    {:reply, {:ok, result}, pid}
  end

  def detect_beats(audio_path) do
    Task.async(fn ->
      :poolboy.transaction(
        :python_worker,
        fn pid ->
          GenServer.call(pid, {:detect, audio_path})
        end,
        @timeout
      )
    end)
    |> Task.await(@timeout)
  end

  def generate_music_video(audio_path, beat_times) do
    Task.async(fn ->
      :poolboy.transaction(
        :python_worker,
        fn pid ->
          GenServer.call(pid, {:generate, audio_path, beat_times})
        end,
        @timeout
      )
    end)
    |> Task.await(@timeout)
  end
end
