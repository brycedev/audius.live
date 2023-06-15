defmodule AudiusLiveWeb.PlayerLive do
  use AudiusLiveWeb, :live_view

  use Phoenix.Component

  alias AudiusLive.Clock
  alias AudiusLive.Track
  alias AudiusLive.VideoPlayer

  def render(assigns) do
    ~H"""
    <div id="app" class="h-screen w-screen" role="region">
      <div phx-update="ignore" id="three" class="w-full h-full" phx-ignore></div>
    </div>
    """
  end

  def mount(_params, _session, socket) do

    if connected?(socket) do
      Clock.subscribe()
      if !Clock.running?() do
        Clock.start_clock(AudiusLive.Clock, 20)
      end
    end

    {status, time, duration} = Clock.get_clock_state(AudiusLive.Clock)

    {:ok, assign(socket, status: status, time: time, duration: duration)}
  end

  def handle_info(:clock_updated, socket) do
    {status, time, duration} = Clock.get_clock_state(AudiusLive.Clock)

    socket = assign(socket, status: status, time: time, duration: duration)

    {:noreply, push_event(socket, "clockUpdated", %{
      status: status,
      time: time,
      duration: duration
    })}
  end

  defp track_title(%{artist: artist}) do
    "(Now Playing) some #{artist}"
  end

end
