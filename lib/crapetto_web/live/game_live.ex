defmodule CrapettoWeb.GameLive do
  use CrapettoWeb, :live_view
  alias Crapetto.Accounts
  alias Crapetto.Casino
  alias Crapetto.GameServer
  alias Crapetto.Game

#  alias CrapettoWeb.Router.Helpers, as: Routes


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
  if socket.assigns.keyup do
    IO.inspect({"Keydown", String.upcase(key)})
    game_pid  = socket.assigns.game_pid
    {result, game} =
      case String.upcase(key) do
        "A" -> GameServer.play_ligretto(game_pid, socket.assigns.current_user.email)
        "Z" -> GameServer.play_displayed(game_pid, socket.assigns.current_user.email)
        "E" -> GameServer.play_series(game_pid, socket.assigns.current_user.email, 1)
        "R" -> GameServer.play_series(game_pid, socket.assigns.current_user.email, 2)
        "T" -> GameServer.play_series(game_pid, socket.assigns.current_user.email, 3)
        "Y" -> GameServer.play_series(game_pid, socket.assigns.current_user.email, 4)
        "U" -> GameServer.play_series(game_pid, socket.assigns.current_user.email, 5)
        "P" -> g = GameServer.show_three(game_pid, socket.assigns.current_user.email)
              {:ok, g}
        _ -> {:ok, nil}
      end
    {:noreply, assign(socket, :keyup,  false)}
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
def handle_info(params, socket) do
  IO.inspect({"handle info", params})
  {:noreply, socket}
end



end
