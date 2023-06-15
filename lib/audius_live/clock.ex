defmodule AudiusLive.Clock do
  use GenServer
  alias Phoenix.PubSub

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def start_clock(clock, duration) do
    GenServer.call(clock, {:start, duration})
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
    {:ok, {:stopped, 0, 0}}
  end

  @impl true
  def handle_call({:start, length}, _from, {_status, time,_duration}) do
    Process.send_after(self(), :tick, 1000)
    {:reply, :running, {:running, time, length}}
  end

  @impl true
  def handle_call(:stop, _from, {_status, time, duration}) do
    {:reply, :stopped, {:stopped, time, 0}}
  end

  @impl true
  def handle_call(:state, _from, clock ) do
    {:reply, clock, clock}
  end

  @impl true
  def handle_call(:reset, _from, _clock) do
    {:reply, :reset, {:stopped, 0, 0}}
  end

  @impl true
  def handle_info(:tick, {status, time, duration} = clock) do
    if time < duration do 
      Process.send_after(self(), :tick, 1000)
      notify()
      {:noreply, {status, time + 1, duration}}
    else
      if time >= duration do
        notify()
        {:noreply, {:stopped, time, 0}}
      end
    end
  end

  def subscribe() do
    PubSub.subscribe(AudiusLive.PubSub, "audius_live:clock")
  end

  def notify() do
    PubSub.broadcast(AudiusLive.PubSub, "audius_live:clock", :clock_updated)
  end

  def running?() do
    GenServer.call(__MODULE__, :state) == {:running }
  end
end