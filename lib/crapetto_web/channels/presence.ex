defmodule CrapettoWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence, otp_app: :crapetto,
                        pubsub_server: Crapetto.PubSub

alias Crapetto.Accounts

def fetch3(_topic, presences) do
  #IO.inspect({"fetch presencze", presences})
  presences
end

def fetch2(_topic, presences) do
  IO.inspect({"fetch presencze", presences})
  presences
  users = presences |> Map.keys() |> Accounts.get_users_map()

  for {key, %{metas: metas}} <- presences, into: %{} do
    {key, %{metas: metas, user: users[String.to_integer(key)]}}
  end
end

end
