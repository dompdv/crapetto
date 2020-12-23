defmodule CrapettoWeb.PageLive do
  use CrapettoWeb, :live_view
  alias CrapettoWeb.Presence
  alias Crapetto.Accounts

  @impl true
  def mount(_params,  %{"user_token" => token}, socket) do
    current_user = Accounts.get_user_by_session_token(token)

    # Presence
    topic = "table:lobby"
    players = Presence.list(topic) |> Map.values() |> Enum.map(fn %{metas: [m]} -> m.player end) |> MapSet.new() # Déduplique en utilisant un MapSet
    # Subscribe to the topic
    CrapettoWeb.Endpoint.subscribe(topic)
    # Track changes to the topic : utilise in Presence.track qui track le **process**
    Presence.track(self(), topic, socket.id, %{player: current_user.email})

    {:ok, assign(socket, %{players: players,current_user: current_user})}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{players: players}} = socket
      ) do
        IO.inspect({"DIFF", joins, leaves, players})
        joiners = joins  |> Map.values() |> Enum.map(fn %{metas: [m]} -> m.player end) |> MapSet.new()
        leavers = leaves |> Map.values() |> Enum.map(fn %{metas: [m]} -> m.player end) |> MapSet.new()
        updated_players = players |> MapSet.union(joiners) |> MapSet.difference(leavers)
    IO.inspect({"updated", joiners, leavers, updated_players})
    {:noreply, assign(socket, players: updated_players)}
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
