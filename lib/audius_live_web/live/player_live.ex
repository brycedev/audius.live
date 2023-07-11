defmodule AudiusLiveWeb.PlayerLive do
  use AudiusLiveWeb, :live_view

  use Phoenix.Component

  alias AudiusLive.Radio

  def render(assigns) do
    ~H"""
    <div id="app" class="h-screen w-screen" role="region">
      <div phx-update="ignore" id="three" class="w-full h-full" phx-ignore></div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Radio.subscribe()
    end

    {:ok, socket}
  end

  def handle_info(:clock_updated, socket) do
    {status, time, duration, url} = Radio.get_state(Radio)

    socket = assign(socket, status: status, time: time, duration: duration, url: url)

    {:noreply,
     push_event(socket, "clockUpdated", %{
       status: status,
       time: time,
       duration: duration,
       url: url
     })}
  end

  def handle_info(:track_updated, socket) do
    {status, time, duration, url} = Radio.get_state(Radio)

    socket = assign(socket, status: status, time: time, duration: duration, url: url)

    {:noreply,
     push_event(socket, "trackUpdated", %{
       url: url,
       status: status,
       time: time,
       duration: duration
     })}
  end

  defp track_title(%{artist: artist}) do
    "(Now Playing) #{artist}"
  end
end
