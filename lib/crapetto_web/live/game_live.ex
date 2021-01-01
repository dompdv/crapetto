defmodule CrapettoWeb.GameLive do
  use CrapettoWeb, :live_view
  alias Crapetto.Accounts
  alias Crapetto.Casino
  alias Crapetto.GameServer
  alias Crapetto.Game

#  alias CrapettoWeb.Router.Helpers, as: Routes

@lock_time 5
@lock_time_three 1

@impl true
def mount(_params, %{"user_token" => token}, socket) do
  # Find the current user from the session and put it in the LiveView session
  current_user = Accounts.get_user_by_session_token(token)

  if connected?(socket) do
    # Subscribe to the topic where news are broacasted about all games (creation, end, change of status,...)
  end

  {:ok, assign(socket, %{current_user: current_user, keyup: true})}
end


defp subscribe(id_game) do
  Phoenix.PubSub.unsubscribe(Crapetto.PubSub, "game:#{id_game}")
  Phoenix.PubSub.subscribe(Crapetto.PubSub, "game:#{id_game}")
end

@impl true
def handle_params(%{"id" => id_game}, _uri, socket) do
  case Casino.lookup(id_game) do
    :error -> {:noreply , push_redirect(socket, to: "/")}
    game ->  subscribe(id_game)
              game_pid  = Casino.game_pid(id_game)
             {:noreply , assign(socket, %{id_game: id_game, game: game, game_pid: game_pid})}
  end
end

defp play(socket, what) do
  game_pid  = socket.assigns.game_pid
  player = socket.assigns.current_user.email
  if not (GameServer.is_locked(game_pid, player)) do
    {result, _game} =
      case what do
        :ligretto-> GameServer.play_ligretto(game_pid, player)
        :displayed -> GameServer.play_displayed(game_pid, player)
        {:series, n} -> GameServer.play_series(game_pid, player, n)
        :show_three -> g = GameServer.show_three(game_pid, player)
              GameServer.lock_player(game_pid, player, @lock_time_three)
              Process.send_after(self(), :unlock_countdown, 1000)
                {:ok, g}
      end
    if result == :error do
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

@impl true
def handle_event("join", _params, socket) do
  id_game = socket.assigns.id_game
  game_pid  = socket.assigns.game_pid
  game = GameServer.add_player(game_pid, socket.assigns.current_user.email)
  {:noreply, assign(socket, :game,  game)}
end

@impl true
def handle_event("quit", _params, socket) do
  id_game = socket.assigns.id_game
  game_pid  = socket.assigns.game_pid
  game = GameServer.remove_player(game_pid, socket.assigns.current_user.email)
  {:noreply, assign(socket, :game,  game)}
end

@impl true
def handle_event("launch_game", _params, socket) do
  id_game = socket.assigns.id_game
  game_pid  = socket.assigns.game_pid
  game = GameServer.start_game(game_pid)
  {:noreply, assign(socket, :game,  game)}
end


@impl true
def handle_event("keydown", %{"key" => key}, socket) do
  if socket.assigns.keyup do
      case String.upcase(key) do
        "A" -> play(socket, :ligretto)
        "Z" -> play(socket, :displayed)
        "E" -> play(socket, {:series, 1})
        "R" -> play(socket, {:series, 2})
        "T" -> play(socket, {:series, 3})
        "Y" -> play(socket, {:series, 4})
        "U" -> play(socket, {:series, 5})
        "P" -> play(socket, :show_three)
        _ -> {:noreply, socket}
      end
  else
    {:noreply, socket}
  end
end


def handle_event("keydown", params, socket) do
  {:noreply, socket}
end

def handle_event("keyup", _params, socket) do
  {:noreply, assign(socket, :keyup,  true)}
end

def handle_event("stuck", _params, socket) do
  game_pid  = socket.assigns.game_pid
  game = GameServer.switch_stuck_player(game_pid, socket.assigns.current_user.email)
  {:noreply, assign(socket, :game,  game)}
end


def handle_event("card_click", %{"card" => "ligretto"}, socket) do
  play(socket, :ligretto)
end
def handle_event("card_click", %{"card" => "displayed"}, socket) do
  play(socket, :displayed)
end
def handle_event("card_click", %{"card" => "series", "serie" => serie}, socket) do
  parsed = Integer.parse(serie)
  cond do
    parsed == :error -> {:noreply, socket}
    true ->
      {serie, _} = parsed
      play(socket, {:series, serie})
    end
end

defp refresh_game(socket) do
  id_game = socket.assigns.id_game
  assign(socket, game: Casino.lookup(id_game))
end

def handle_info(:unlock_countdown, socket) do
  game_pid  = socket.assigns.game_pid
  player = socket.assigns.current_user.email
  GameServer.countdown_player(game_pid, player)
  if GameServer.is_locked(game_pid, player) do
    Process.send_after(self(), :unlock_countdown, 1000)
  end
  {:noreply, refresh_game(socket)}
end

def handle_info({:add_player, id_player}, socket) do
  {:noreply, refresh_game(socket)}
end
def handle_info({:remove_player, id_player}, socket) do
  {:noreply, refresh_game(socket)}
end

def handle_info(:start, socket) do
  Process.send_after(self(), :unlock_countdown, 1000)
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:play_displayed, _result, _player}, socket) do
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:play_series, _result, _player}, socket) do
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:play_ligretto, _result, _player}, socket) do
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:show_three, _player}, socket) do
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:lock_player, _player}, socket) do
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info({:countdown_player, _player}, socket) do
  {:noreply, refresh_game(socket)}
end
@impl true
def handle_info({:switch_stuck_player, _player}, socket) do
  {:noreply, refresh_game(socket)}
end

@impl true
def handle_info(params, socket) do
  {:noreply, socket}
end



end
