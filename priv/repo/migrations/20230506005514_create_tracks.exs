defmodule AudiusLive.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add(:audius_id, :string)
      add(:artist, :string)
      add(:title, :text)
      add(:has_music_video, :boolean, default: false)
      add(:is_queued, :boolean, default: true)
      timestamps()
    end
  end
end
