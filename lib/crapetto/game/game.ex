defmodule Crapetto.Game do
  @enforce_keys [:id_game, :owner, :id_owner]
  defstruct [:id_game, :owner, :id_owner, status: :starting, winner: nil, num_players: 0, players: [], players_decks: %{}, stacks: %{}, series: 0]

  # Colors = :red :blue :green :yellow
  # Status : :starting = waiting to start
  #          :playing  = players are currently playing
  #          :over = the game is naturally over
  #          :terminated = the game has been forced to terminate


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

  # remplir une serie vide d'un joueur avec le ligretto
  defp ligretto_to_series(game, player, location) do
    %{players_decks: %{^player => %{ligretto: ligretto, series: series} = player_deck}} = game
    if series[location] != nil do
      game
    else
      {card, ligretto} = List.pop_at(ligretto, 0)
      series = Map.put series, location, card
      new_player_deck = %{player_deck | ligretto: ligretto, series: series}
      empty_ligretto = Enum.count(ligretto) == 0
      %{status: status, winner: winner} = game
      %{game | players_decks: Map.put(game.players_decks, player, new_player_deck),
                     status: (if empty_ligretto, do: :over, else: status),
                     winner: (if empty_ligretto and winner == nil, do: player, else: winner)}
    end
  end

  # retourne 3 cartes (au maximum) du deck vers la pile displayed
  def show_three(game, player) do
    %{players_decks: %{^player => %{deck: deck, displayed: displayed} = player_deck}} = game
    count_deck = Enum.count(deck)
    {displayed, deck} = if count_deck == 0, do: {[], Enum.reverse(displayed)}, else: {displayed, deck}
    {displayed, deck} = Enum.reduce(
        1..min(3, Enum.count(deck)),
        {displayed, deck},
        fn _, {disp, dec} -> {card, dec} = List.pop_at(dec, 0)
                             {[card | disp], dec} end
    )
    new_player_deck = %{player_deck | deck: deck, displayed: displayed}
    %{game | players_decks: Map.put(game.players_decks, player, new_player_deck)}
  end

  # Vérifie si on peut jouer une carte quelque part
  def playable?(game, {_, color, number}) do
    if number == 1 do
      true
    else
      Enum.count(
        game.stacks
        |> Enum.filter(fn {_, stack} -> Enum.count(stack) > 0 end)
        |> Enum.map(fn {_, [{_, c, n} | _]} -> {c, n} end)
        |> Enum.filter(fn {c, n} -> c == color and number == n + 1 end)
      ) > 0
    end
  end

  # Joue une carte sur une stack
  def play_on_stack(game, {_, color, number} = card) do
    if number == 1 do
      # Choisis une stack vide au hasard
      {stack, _} =
        game.stacks
        |> Enum.filter(fn {_, stack} -> Enum.count(stack) == 0 end)
        |> Enum.shuffle()
        |> hd()
      %{game | stacks: Map.put(game.stacks, stack, [card])}
    else
      # Trouve une stack où poser la carte
      {stack, stack_content} =
        game.stacks
        |> Enum.filter(fn {_, stack} -> Enum.count(stack) > 0 end)
        |> Enum.filter(fn {_, [{_, c, n} | _]} -> c == color and number == n + 1 end)
        |> hd()
      %{game | stacks: Map.put(game.stacks, stack, [card | stack_content])}
    end
  end

  def play_ligretto(game, player) do
    %{players_decks: %{^player => %{ligretto: ligretto} = player_deck}} = game
    case ligretto do
      [] -> {:error, game}
      [card|r_ligretto] ->
        if not playable?(game, card) do
          {:error, game}
        else
          game = play_on_stack(game, card)
          new_player_deck = %{player_deck | ligretto: r_ligretto}
          # Si on vide le ligretto, on a un gagnant !
          empty_ligretto = Enum.count(r_ligretto) == 0
          %{status: status, winner: winner} = game
          {:ok, %{game | players_decks: Map.put(game.players_decks, player, new_player_deck),
                         status: (if empty_ligretto, do: :over, else: status),
                         winner: (if empty_ligretto and winner == nil, do: player, else: winner)}}
        end
    end
  end

  def play_serie(game, player, location) do
    %{players_decks: %{^player => %{series: %{^location => serie} = series} = player_deck}} = game
    case serie do
      nil -> {:error, game}
      card ->
        if not playable?(game, card) do
          {:error, game}
        else
          game = play_on_stack(game, card)
          new_player_deck = %{player_deck | series: Map.put(series, location, nil)}
          game = %{game | players_decks: Map.put(game.players_decks, player, new_player_deck)}
          game = ligretto_to_series(game, player, location)
          {:ok, game}
        end
    end
  end



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
