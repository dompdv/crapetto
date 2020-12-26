defmodule Crapetto.Game do
  @enforce_keys [:id_game, :owner, :id_owner]
  defstruct [:id_game, :owner, :id_owner, status: :starting, num_players: 0, players: [], players_decks: %{}, stacks: %{}, series: 0]

  # Colors = :red :blue :green :yellow
  #
  def new_game(id_owner, owner) do
    id_game = Enum.reduce(1..6, "", fn _, acc -> Enum.random(String.graphemes("ABCDEFGHIJKLMNOPQRSTUVWXYZ23456789")) <> acc end)
    %Crapetto.Game{id_game: id_game, owner: owner, id_owner: id_owner}
  end

  def add_player(%Crapetto.Game{status: :starting, players: players} = game, a_player) do
    new_players = if Enum.member?(players, a_player), do: players, else: [a_player | players]
    %Crapetto.Game{game | players: new_players, num_players: Enum.count(new_players)}
  end

  def remove_player(%Crapetto.Game{status: :starting, players: players} = game, a_player) do
    new_players = List.delete(players, a_player)
    %Crapetto.Game{game | players: new_players, num_players: Enum.count(new_players)}
  end

  def deck_to_ligretto(game, player) do
    %{players_decks: %{^player => %{deck: deck, ligretto: ligretto} = player_deck}} = game
    {card, deck}  = List.pop_at(deck, 0)
    new_player_deck = %{player_deck | deck: deck, ligretto: (if card == nil, do: ligretto, else: [card | ligretto])}
    %{game | players_decks: Map.put(game.players_decks, player, new_player_deck)}
  end

  defp ligretto_to_series(game, player, location) do
    %{players_decks: %{^player => %{ligretto: ligretto, series: series} = player_deck}} = game
    if series[location] != nil do
      game
    else
      {card, ligretto} = List.pop_at(ligretto, 0)
      series = Map.put series, location, card
      new_player_deck = %{player_deck | ligretto: ligretto, series: series}
      %{game | players_decks: Map.put(game.players_decks, player, new_player_deck)}
    end
  end

  # Status : :starting = waiting to start
  #          :playing  = players are currently playing
  #          :over = the game is naturally over
  #          :terminated = the game has been forced to terminate

  defp fill_ligretto(game) do
    Enum.reduce(game.players, game, fn player, game1 -> Enum.reduce(1..(10 + game.series), game1, fn _, g -> deck_to_ligretto(g, player) end) end )
  end

  defp fill_series(game) do
    Enum.reduce(game.players, game,
      fn player, game1 -> Enum.reduce(1..game.series, game1, fn location, g -> ligretto_to_series(g, player, location) end) end
    )
  end

  def start_game(%Crapetto.Game{status: :starting, players: players, num_players: num_players} = game) do
    series = case num_players do
                  2 -> 5
                  3 -> 4
                  _ -> 3
                end
    players_decks =
      players
      |> Enum.map(
        fn p -> {p,
        %{deck: (for c <- [:red, :green, :blue, :yellow], n <- 1..10, do: {p,c,n}) |> Enum.shuffle(),
          ligretto: [],
          series: 1..series |> Enum.map(fn x -> {x, nil} end) |> Map.new(),
          displayed: []}
        } end
      )
      |> Map.new()
    stacks = 1..(num_players * 4) |> Enum.map(fn x -> {x, []} end) |> Map.new()
    # Game is initialized
    %Crapetto.Game{game | status: :playing, players_decks: players_decks, series: series, stacks: stacks}
    # Fill the ligretto
      |> fill_ligretto()
      |> fill_series()
  end

  def terminate_game(%Crapetto.Game{status: :playing} = game) do
    %Crapetto.Game{game | status: :terminated}
  end

end
