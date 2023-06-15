defmodule AudiusLive.Clock do
  use GenServer
  alias Phoenix.PubSub

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def start_clock(clock) do
    GenServer.call(clock, :start)
  end

  def stop_clock(clock) do
    GenServer.call(clock, :stop)
  end

  def get_clock_state(clock) do
    GenServer.call(clock, :state)
  end

  def reset(clock) do
    GenServer.call(clock, :reset)
  end

  @impl true
  def init(:ok) do
    {:ok, {:stopped, ~T[00:00:00]}}
  end

  @impl true
  def handle_call(:start, _from, {_status, time}) do
    Process.send_after(self(), :tick, 1000)
    {:reply, :running, {:running, time}}
  end

  @impl true
  def handle_call(:stop, _from, {_status, time}) do
    {:reply, :stopped, {:stopped, time}}
  end

  @impl true
  def handle_info(:tick, {status, time} = clock) do
    if status == :running do
      Process.send_after(self(), :tick, 1000)
      notify()
      {:noreply, {status, Time.add(time, 1, :second)}}
    else
      {:noreply, clock}
    end
  end

  @impl true
  def handle_call(:state, _from, clock) do
    {:reply, clock, clock}
  end

  @impl true
  def handle_call(:reset, _from, _clock) do
    {:reply, :reset, {:stopped, ~T[00:00:00]}}
  end

  def subscribe() do
    PubSub.subscribe(AudiusLive.PubSub, "audius_live:clock")
  end

  def notify() do
    PubSub.broadcast(AudiusLive.PubSub, "audius_live:clock", :clock_updated)
  end
end