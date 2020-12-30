defmodule CrapettoWeb.GameLive do
  use CrapettoWeb, :live_view
  alias Crapetto.Accounts
  alias Crapetto.Casino
  alias Crapetto.GameServer
  alias Crapetto.Game

#  alias CrapettoWeb.Router.Helpers, as: Routes

@lock_time 3

@impl true
def mount(_params, %{"user_token" => token}, socket) do
  # Find the current user from the session and put it in the LiveView sessio,n
  current_user = Accounts.get_user_by_session_token(token)

  if connected?(socket) do
    IO.inspect("CONNECTED2")
    # Subscribe to the topic where news are broacasted about all games (creation, end, change of status,...)
  end

  {:ok, assign(socket, %{current_user: current_user, keyup: true})}
end


defp subscribe(id_game) do
  IO.inspect("SUBSCRIBE game:#{id_game}")
  Phoenix.PubSub.unsubscribe(Crapetto.PubSub, "game:#{id_game}")
  Phoenix.PubSub.subscribe(Crapetto.PubSub, "game:#{id_game}")
end

@impl true
def handle_params(%{"id" => id_game} = params, uri, socket) do
  IO.inspect({"HANDLE PARAMS", params, uri})
  case Casino.lookup(id_game) do
    :error -> {:noreply , push_redirect(socket, to: "/")}
    game ->  subscribe(id_game)
              game_pid  = Casino.game_pid(id_game)
             {:noreply , assign(socket, %{id_game: id_game, game: game, game_pid: game_pid})}
  end
end


@impl true
def handle_event("join", _params, socket) do
  id_game = socket.assigns.id_game
  game_pid  = socket.assigns.game_pid
  game = GameServer.add_player(game_pid, socket.assigns.current_user.email)
  IO.inspect({"JOIN", game_pid, id_game, game})
  {:noreply, assign(socket, :game,  game)}
end

@impl true
def handle_event("quit", _params, socket) do
  id_game = socket.assigns.id_game
  game_pid  = socket.assigns.game_pid
  game = GameServer.remove_player(game_pid, socket.assigns.current_user.email)
  IO.inspect({"QUIT", game_pid, id_game, game})
  {:noreply, assign(socket, :game,  game)}
end

@impl true
def handle_event("launch_game", _params, socket) do
  id_game = socket.assigns.id_game
  game_pid  = socket.assigns.game_pid
  game = GameServer.start_game(game_pid)
  IO.inspect({"launch_game", game_pid, id_game, game})
  {:noreply, assign(socket, :game,  game)}
end

@impl true
def handle_event("keydown", %{"key" => key}, socket) do
  game_pid  = socket.assigns.game_pid
  player = socket.assigns.current_user.email
  IO.inspect({"keydown", key, socket.assigns.keyup, GameServer.is_locked(game_pid, player)})
  if socket.assigns.keyup and not (GameServer.is_locked(game_pid, player)) do
    IO.inspect({"Keydown", String.upcase(key)})
    {result, game} =
      case String.upcase(key) do
        "A" -> GameServer.play_ligretto(game_pid, player)
        "Z" -> GameServer.play_displayed(game_pid, player)
        "E" -> GameServer.play_series(game_pid, player, 1)
        "R" -> GameServer.play_series(game_pid, player, 2)
        "T" -> GameServer.play_series(game_pid, player, 3)
        "Y" -> GameServer.play_series(game_pid, player, 4)
        "U" -> GameServer.play_series(game_pid, player, 5)
        "P" -> g = GameServer.show_three(game_pid, player)
              {:ok, g}
        _ -> {:ok, nil}
      end
    if result == :error do
      IO.inspect("ERRRRRROOOOORR")
      GameServer.lock_player(game_pid, player, @lock_time)
      Process.send_after(self(), :unlock_countdown, 1000)
      {:noreply, assign(socket, :keyup,  false)}
    else
      {:noreply, assign(socket, :keyup,  false)}
    end
  else
    {:noreply, socket}
  end
end

def handle_event("keydown", params, socket) do
  IO.inspect({"Keydown", params})
  {:noreply, socket}
end

def handle_event("keyup", _params, socket) do
  IO.inspect({"Keyup"})
  {:noreply, assign(socket, :keyup,  true)}
end

defp refresh_game(socket) do
  id_game = socket.assigns.id_game
  assign(socket, game: Casino.lookup(id_game))
end

def handle_info(:unlock_countdown, socket) do
  IO.inspect({"unlock_countdown"})
  game_pid  = socket.assigns.game_pid
  player = socket.assigns.current_user.email
  GameServer.countdown_player(game_pid, player)
  if GameServer.is_locked(game_pid, player) do
    Process.send_after(self(), :unlock_countdown, 1000)
  end
  {:noreply, refresh_game(socket)}
end

def handle_info({:add_player, id_player}, socket) do
  IO.inspect({"add_player", id_player})
  {:noreply, refresh_game(socket)}
end
def handle_info({:remove_player, id_player}, socket) do
  IO.inspect({"add_player", id_player})
  {:noreply, refresh_game(socket)}
end

def handle_info(:start, socket) do
  IO.inspect({"start"})
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:play_displayed, _result, _player}, socket) do
  IO.inspect({"handle play_displayed"})
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:play_series, _result, _player}, socket) do
  IO.inspect({"handle play_displayed"})
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:play_ligretto, _result, _player}, socket) do
  IO.inspect({"handle play_ligretto"})
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:show_three, _player}, socket) do
  IO.inspect({"handle show_three"})
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:lock_player, _player}, socket) do
  IO.inspect({"handle lock_player"})
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:countdown_player, _player}, socket) do
  IO.inspect({"handle countdown_player"})
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info(params, socket) do
  IO.inspect({"handle info", params})
  {:noreply, socket}
end



end
