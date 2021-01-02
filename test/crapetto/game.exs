defmodule Crapetto.GameTest do
  use ExUnit.Case

  alias Crapetto.Game

  setup do
    game = Game.new_game(100, "dompdv")
    game = Game.add_player(game, "Alice")
    game = Game.add_player(game, "Bob")
    game = Game.add_player(game, "Charles")
    %{game: game}
  end

  test "basic Game tests", %{game: game} do
    assert game.owner == "dompdv"
    game = Game.start_game(game)
    before_count = Enum.count(game.players_decks["Alice"].displayed) + Enum.count(game.players_decks["Alice"].deck)
    Enum.reduce(1..59, game, fn _, g -> Game.show_three(g, "Alice") end)
    assert before_count == Enum.count(game.players_decks["Alice"].displayed) + Enum.count(game.players_decks["Alice"].deck)
  end

  test "Play card", %{game: game} do
    game = Game.start_game(game)
    assert Game.playable?(game, {"Alice", :blue, 2}) == false
    assert Game.playable?(game, {"Alice", :blue, 1})
    game = Game.play_on_stack(game, {"Alice", :blue, 1})
    game = Game.play_on_stack(game, {"Alice", :blue, 1})
    game = Game.play_on_stack(game, {"Alice", :yellow, 1})
    game = Game.play_on_stack(game, {"Alice", :blue, 2})
    assert Game.playable?(game, {"Alice", :blue, 2})
    assert Game.playable?(game, {"Alice", :blue, 3})
    assert Game.playable?(game, {"Alice", :blue, 4}) == false
    game = Game.play_on_stack(game, {"Alice", :yellow, 2})
    game = Game.play_on_stack(game, {"Alice", :blue, 2})
    game = Game.play_on_stack(game, {"Alice", :blue, 3})
    assert Game.playable?(game, {"Alice", :yellow, 3})
    #IO.inspect(game)
    %{players_decks: %{"Bob" => %{ligretto: ligretto} = player_deck}} = game
    new_player_deck = %{player_deck |ligretto: [{"Bob", :yellow, 3} | ligretto]}
    game = %{game | players_decks: Map.put(game.players_decks, "Bob", new_player_deck)}
    {res, _} = Game.play_ligretto(game, "Bob")
    assert res == :ok
    #IO.inspect(game)
    #IO.inspect(res)
  end

  test "Play series", %{game: game} do
    game = Game.start_game(game)
    %{players_decks: %{"Bob" => %{series: series} = player_deck}} = game
    series = Map.put(series, 1, {"Bob", :blue, 1})
    new_player_deck = %{player_deck | series: series}
    game = %{game | players_decks: Map.put(game.players_decks, "Bob", new_player_deck)}
    {res, _game} = Game.play_serie(game, "Bob", 1)
    assert res == :ok
  end

  test "Play displayed", %{game: game} do
    game = Game.start_game(game)
    %{players_decks: %{"Bob" => %{displayed: displayed} = player_deck}} = game
    displayed = [{"Bob", :blue, 1} |displayed]
    new_player_deck = %{player_deck | displayed: displayed}
    game = %{game | players_decks: Map.put(game.players_decks, "Bob", new_player_deck)}
    #IO.inspect(game.players_decks["Bob"])
    {res, _game} = Game.play_displayed(game, "Bob")
    #IO.inspect(game.players_decks["Bob"])
    #IO.inspect(game.stacks)
    #IO.inspect(res)
    assert res == :ok
  end
  test "Compute scores", %{game: game} do
    game = Game.start_game(game)
    %{players_decks: %{"Bob" => %{displayed: displayed} = player_deck}} = game
    displayed = [{"Bob", :blue, 1} |displayed]
    new_player_deck = %{player_deck | displayed: displayed}
    game = %{game | players_decks: Map.put(game.players_decks, "Bob", new_player_deck)}
    #IO.inspect(game.players_decks["Bob"])
    {res, game} = Game.play_displayed(game, "Bob")
    #IO.inspect(game.stacks)
    game = %{game | status: :over}
    game = Game.update_score(game)
    assert res == :ok
    assert game.players_scores["Alice"] == -20
    assert game.players_scores["Bob"] == -19
    assert game.players_scores["Charles"] == -20
  end

  test "Overall winner", %{game: _game} do
    game = Game.new_game(100, "dompdv")
    game = Game.add_player(game, "Alice")
    game = Game.add_player(game, "Bob")
    game = Game.add_player(game, "Charles")

    game = Game.start_game(game)
    game = %{game | score_to_win: 0}
    %{players_decks: %{"Bob" => player_deck}} = game
    ligretto = [{"Bob", :blue, 1}]
    new_player_deck = %{player_deck | ligretto: ligretto}
    game = %{game | players_decks: Map.put(game.players_decks, "Bob", new_player_deck)}
    #IO.inspect(game.players_decks["Bob"])
    {_res, game} = Game.play_ligretto(game, "Bob")
    #IO.inspect(game.stacks)
    #IO.inspect(game)
    assert game.overall_winner == "Bob"
    assert game.status == :overall_over
    assert game.players_scores["Bob"] == 1

  end

  test "Shuffle when stuck", %{game: _game} do
    players = ["Alice", "Bob", "Charles"]
    game = players |> Enum.reduce(Game.new_game(100, "dompdv"), fn p, g -> Game.add_player(g, p) end) |> Game.start_game()
    game = Enum.reduce(["Alice", "Alice", "Bob"], game, fn p, g -> Game.show_three(g, p) end)
    initial_counts = Enum.map(game.players_decks,
      fn {p, %{deck: deck, ligretto: ligretto, displayed: displayed, series: series}} ->
        {p, Enum.count(deck) + Enum.count(ligretto) + Enum.count(displayed) + Enum.count(series)}
      end) |> Map.new()
    game = Game.switch_stuck_player(game, "Alice")
    game = Game.switch_stuck_player(game, "Bob")
    assert game.stuck_players == MapSet.new(["Alice", "Bob"])
    game = Game.switch_stuck_player(game, "Charles")
    after_counts = Enum.map(game.players_decks,
      fn {p, %{deck: deck, ligretto: ligretto, displayed: displayed, series: series}} ->
        {p, Enum.count(deck) + Enum.count(ligretto) + Enum.count(displayed) + Enum.count(series)}
      end) |> Map.new()
    assert after_counts == initial_counts
  end
  end
