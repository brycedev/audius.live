defmodule AudiusLive.Radio do
  @moduledoc """
  This module implements a GenServer that acts as a clock for the radio.
  It is started by the application supervisor and is responsible for
  keeping track of the current time and duration of the current track.
  """
  use GenServer
  alias Phoenix.PubSub

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def play_song(clock, duration, url) do
    Logger.info("Clock started for #{duration} seconds")
    GenServer.call(clock, {:start, duration, url})
  end

  def stop_clock(clock) do
    GenServer.call(clock, :stop)
  end

  def get_state(clock) do
    GenServer.call(clock, :state)
  end

  @impl true
  def init(:ok) do
    {:ok, {:stopped, 0, 0, nil}}
  end

  @impl true
  def handle_call({:start, duration, url}, _from, {_status, time, _duration, _url}) do
    Process.send_after(self(), :tick, 1000)
    {:reply, :running, {:running, time, duration, url}}
  end

  @impl true
  def handle_call(:stop, _from, {_status, _time, _duration, _url}) do
    {:noreply, {:stopped, 0, 0, nil}}
  end

  @impl true
  def handle_call(:state, _from, clock) do
    {:reply, clock, clock}
  end

  @impl true
  def handle_info(:tick, {status, time, duration, url}) do
    if time < duration do
      Process.send_after(self(), :tick, 1000)
      notify()
      {:noreply, {status, time + 1, duration, url}}
    else
      if time >= duration do
        notify()
        AudiusLive.Media.prepare_next_video()
        {:noreply, {:stopped, 0, 0, nil}}
      end
    end
  end

  def subscribe() do
    PubSub.subscribe(AudiusLive.PubSub, "audius_live:clock")
    PubSub.subscribe(AudiusLive.PubSub, "audius_live:track")
  end

  def notify() do
    PubSub.broadcast(AudiusLive.PubSub, "audius_live:clock", :clock_updated)
  end
end
