defmodule CrapettoWeb.PageLive do
  use CrapettoWeb, :live_view

  alias CrapettoWeb.Presence
  alias CrapettoWeb.Router.Helpers, as: Routes

  alias Crapetto.Accounts
  alias Crapetto.Casino
  alias Crapetto.GameServer

  @impl true
  def mount(_params, %{"user_token" => token}, socket) do
    current_user = Accounts.get_user_by_session_token(token)
    players =
      if connected?(socket) do
        # Presence. Le topic est arbitraire (ici, la table de jeu)
        topic = "table:lobby"

        # Subscribe to the topic
        CrapettoWeb.Endpoint.subscribe(topic)
        # Track changes to the topic : utilise in Presence.track qui track le **process**
        # "player" est une méta qui contient seulement l'email du joueur
        Presence.track(self(), topic, socket.id, %{player: current_user.email, player_id: current_user.id})

        # Subscribe to the topic where news are broacasted about all games (creation, end, change of status,...)
        Phoenix.PubSub.unsubscribe(Crapetto.PubSub, "games_arena")
        Phoenix.PubSub.subscribe(Crapetto.PubSub, "games_arena")
        # Déduplique en utilisant un MapSet
        Presence.list(topic)
        |> Map.values()
        |> Enum.map(fn %{metas: [m]} -> m.player end)
        |> MapSet.new()
      else
        []
      end

    {:ok, games} = Casino.list()
    {:ok, assign(socket, %{
      players: players,
      current_user: current_user,
      games: games
      })}
  end

  # Evenement lancé par Presence à chaque fois qu'un joueur arrive ou s'en va
  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{players: players}} = socket
      ) do
    joiners = joins |> Map.values() |> Enum.map(fn %{metas: [m]} -> m.player end) |> MapSet.new()
    leavers = leaves |> Map.values() |> Enum.map(fn %{metas: [m]} -> m.player end) |> MapSet.new()
    updated_players = players |> MapSet.union(joiners) |> MapSet.difference(leavers)
    {:noreply, assign(socket, players: updated_players)}
  end

  # A new game has been created
  @impl true
  def handle_info(:new_game, socket) do
    {:ok, games} = Casino.list()
    {:noreply, assign(socket, games: games)}
  end
  @impl true
  def handle_info(:game_modification, socket) do
    {:ok, games} = Casino.list()
    {:noreply, assign(socket, games: games)}
  end

  @impl true
  def handle_info(params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_game", _params, socket) do
    user = socket.assigns.current_user
    id_user = user.id
    {:ok, id_game} = Casino.create(id_user, user.email)
    game_pid  = Casino.game_pid(id_game)
    GameServer.add_player(game_pid, socket.assigns.current_user.email)
    {:noreply, push_redirect(socket, to: "/games/#{id_game}")}
  end

end
