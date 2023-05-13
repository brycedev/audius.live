defmodule AudiusLive.Track do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tracks" do
    field(:artist, :string)
    field(:audius_id, :string)
    field(:title, :string)
    field(:has_music_video, :boolean)
    field(:is_queued, :boolean)
    timestamps()
  end

  @doc false
  def changeset(track, attrs) do
    track
    |> cast(attrs, [:audius_id, :artist, :title])
    |> validate_required([:audius_id, :artist, :title])
  end
end
