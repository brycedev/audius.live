defmodule AudiusLive.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add(:audius_id, :string)
      add(:artist, :string)
      add(:duration, :integer, default: 0, null: false)
      add(:has_music_video, :boolean, default: false)
      add(:is_queued, :boolean, default: true)
      add(:played_at, :utc_datetime)
      add(:status, :integer, null: false, default: 1)
      add(:title, :text)
      timestamps()
    end
  end
end
