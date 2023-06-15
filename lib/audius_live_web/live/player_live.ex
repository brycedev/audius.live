defmodule AudiusLiveWeb.PlayerLive do
  use AudiusLiveWeb, :live_view

  use Phoenix.Component

  alias AudiusLive.Clock
  alias AudiusLive.Track
  alias AudiusLive.VideoPlayer

  def render(assigns) do
    ~H"""
    <div id="app" phx-hook="AudiusStage" class="h-screen w-screen" role="region" aria-label="AudiusStage">
      <div id="three" class="w-full h-full"></div>
    </div>
    """
  end

  def mount(_params, _session, socket) do

    if connected?(socket) do
      Clock.subscribe()
    end

    {clock_status, time} = Clock.get_clock_state(AudiusLive.Clock)

    {:ok, assign(socket, clock_status: clock_status, time: time)}
  end

  def handle_event("start", _value, socket) do
    :running = Clock.start_clock(AudiusLive.Clock)
    Clock.notify()
    {:noreply, socket}
  end

  def handle_event("stop", _value, socket) do
    :stopped = Clock.stop_timer(AudiusLive.Clock)
    Clock.notify()
    {:noreply, socket}
  end

  def handle_event("reset", _value, socket) do
    :reset = Clock.reset(AudiusLive.Clock)
    Clock.notify()
    {:noreply, socket}
  end

  def handle_info(:clock_updated, socket) do
    {clock_status, time} = Clock.get_clock_state(AudiusLive.Clock)

    {:noreply, assign(socket, time: time, clock_status: clock_status)}
  end

  def handle_event("next_track", _value, socket) do
    

    {:noreply, socket}
  end

  def handle_info("play_current", socket) do
    {:noreply, socket}
  end

  def handle_info({VideoPlayer, %VideoPlayer.Events.Play{} = play}, socket) do
    {:noreply, play_track(socket, play.track, play.elapsed)}
  end

  def handle_info({VideoPlayer, _}, socket), do: {:noreply, socket}

  defp play_track(socket, %Track{} = track, _elapsed) do
    socket
    # |> push_play(track, elapsed)
    |> assign(track: track, playing: true, page_title: track_title(track))
  end

  defp track_title(%{artist: artist}) do
    "(Now Playing) some #{artist}"
  end

  defp js_listen_now(js \\ %JS{}) do
    JS.dispatch(js, "js:listen_now", to: "#app")
  end
end
