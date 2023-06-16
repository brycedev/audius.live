defmodule AudiusLiveWeb.PlayerLive do
  use AudiusLiveWeb, :live_view
  import Ecto.Query

  use Phoenix.Component

  alias AudiusLive.Radio
  alias AudiusLive.Track

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

    {status, time, duration} = Radio.get_clock_state(AudiusLive.Radio)

    {:ok, assign(socket, status: status, time: time, duration: duration)}
  end

  def handle_info(:clock_updated, socket) do
    {status, time, duration} = Radio.get_clock_state(AudiusLive.Radio)

    socket = assign(socket, status: status, time: time, duration: duration)

    {:noreply, push_event(socket, "clockUpdated", %{
      status: status,
      time: time,
      duration: duration
    })}
  end

  def handle_info(:track_updated, socket) do 
    {status, time, duration} = Radio.get_clock_state(AudiusLive.Radio)

    socket = assign(socket, status: status, time: time, duration: duration)

    playing_track_query =
      from(t in Track,
        where: t.status == :playing,
        limit: 1
      )

    

    track = AudiusLive.Repo.one(playing_track_query)

    {:noreply, push_event(socket, "trackUpdated", %{
      url: "https://cdn.dexterslab.sh/dexterslab/audiuslive/videos/#{track.audius_id}.mp4",
      status: status,
      time: time,
      duration: duration
    })}
  end

  defp track_title(%{artist: artist}) do
    "(Now Playing) #{artist}"
  end

end
