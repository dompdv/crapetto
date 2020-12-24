defmodule CrapettoWeb.PageLive do
  use CrapettoWeb, :live_view
  alias CrapettoWeb.Presence
  alias Crapetto.Accounts
  alias Crapetto.Casino

  @impl true
  def mount(_params, %{"user_token" => token}, socket) do
    current_user = Accounts.get_user_by_session_token(token)

    # Presence. Le topic est arbitraire (ici, la table de jeu)
    topic = "table:lobby"
    # Déduplique en utilisant un MapSet
    players =
      Presence.list(topic)
      |> Map.values()
      |> Enum.map(fn %{metas: [m]} -> m.player end)
      |> MapSet.new()

    # Subscribe to the topic
    CrapettoWeb.Endpoint.subscribe(topic)
    # Track changes to the topic : utilise in Presence.track qui track le **process**
    # "player" est une méta qui contient seulement l'email du joueur
    Presence.track(self(), topic, socket.id, %{player: current_user.email, player_id: current_user.id})

    # Subscribe to the topic where news are broacasted about all games (creation, end, change of status,...)
    Phoenix.PubSub.unsubscribe(Crapetto.PubSub, "games_arena")
    Phoenix.PubSub.subscribe(Crapetto.PubSub, "games_arena")

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
    IO.inspect({"handle new_game"})
    {:ok, games} = Casino.list()
    {:noreply, assign(socket, games: games)}
  end

  @impl true
  def handle_info(params, socket) do
    IO.inspect({"handle info", params})
    {:noreply, socket}
  end

  def handle_event("new_game", _params, socket) do
    user = socket.assigns.current_user
    id_user = user.id
    Casino.create(id_user, user.email)
    IO.inspect({"CLICK", user.email, id_user})

    {:noreply, socket}
  end


  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end


  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  defp search(query) do
    if not CrapettoWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end
end
