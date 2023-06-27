defmodule AudiusLive do
  @moduledoc """
  Main module for AudiusLive
  """

  def config([main_key | rest] = keyspace) when is_list(keyspace) do
    main = Application.fetch_env!(:audius_live, main_key)

    Enum.reduce(rest, main, fn next_key, current ->
      case Keyword.fetch(current, next_key) do
        {:ok, val} -> val
        :error -> raise ArgumentError, "no config found under #{inspect(keyspace)}"
      end
    end)
  end

end
