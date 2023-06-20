defmodule AudiusLive.Snek do
  use GenServer

  @timeout 60_000

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

    with {:ok, pid} <- :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}]) do
      {:ok, pid}
    end
  end

  @impl true
  def handle_call({:detect_beats, audio_path}, _from, pid) do
    result = :python.call(pid, :detect_beats, :detect, [audio_path])
    {:reply, {:ok, result}, pid}
  end

  @impl true
  def handle_call({:fetch_gifs}, _from, pid) do
    result = :python.call(pid, :fetch_gifs, :fetch, [])
    {:reply, {:ok, result}, pid}
  end

  def detect_beats(audio_path) do
    Task.async(fn ->
      :poolboy.transaction(
        :python_worker,
        fn pid ->
          GenServer.call(pid, {:detect_beats, audio_path})
        end,
        @timeout
      )
    end)
    |> Task.await(@timeout)
  end

  def fetch_gifs() do
    Task.async(fn ->
      :poolboy.transaction(
        :python_worker,
        fn pid ->
          GenServer.call(pid, {:fetch_gifs})
        end,
        @timeout
      )
    end)
    |> Task.await(@timeout)
  end
end
