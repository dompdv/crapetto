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
    game = Enum.reduce(1..100, game, fn _, g -> Game.show_three(g, "Alice") end)
  end

  test "Play card", %{game: game} do
    game = Game.start_game(game)
    assert Game.playable?(game, {"Alice", :blue, 2}) == false
    assert Game.playable?(game, {"Alice", :blue, 1})
    game = Game.play_on_stack(game,{"Alice", :blue, 1})
    game = Game.play_on_stack(game,{"Alice", :blue, 1})
    game = Game.play_on_stack(game,{"Alice", :yellow, 1})
    game = Game.play_on_stack(game,{"Alice", :blue, 2})
    assert Game.playable?(game, {"Alice", :blue, 2})
    assert Game.playable?(game, {"Alice", :blue, 3})
    assert Game.playable?(game, {"Alice", :blue, 4}) == false
    game = Game.play_on_stack(game,{"Alice", :yellow, 2})
    game = Game.play_on_stack(game,{"Alice", :blue, 2})
    game = Game.play_on_stack(game,{"Alice", :blue, 3})
    assert Game.playable?(game, {"Alice", :yellow, 3})
    #IO.inspect(game)
    %{players_decks: %{"Bob" => %{ligretto: ligretto} = player_deck}} = game
    new_player_deck = %{player_deck |ligretto: [{"Bob", :yellow, 3} | ligretto]}
    game = %{game | players_decks: Map.put(game.players_decks, "Bob", new_player_deck)}
    {res, game} = Game.play_ligretto(game, "Bob")
    #IO.inspect(game)
    #IO.inspect(res)
  end

  test "Play series", %{game: game} do
    game = Game.start_game(game)
    %{players_decks: %{"Bob" => %{series: series} = player_deck}} = game
    series = Map.put(series, 1, {"Bob", :blue, 1})
    new_player_deck = %{player_deck | series: series}
    game = %{game | players_decks: Map.put(game.players_decks, "Bob", new_player_deck)}
    IO.inspect(game.players_decks["Bob"])
    {res, game} = Game.play_serie(game, "Bob", 1)
    IO.inspect(game.players_decks["Bob"])
    IO.inspect(game.stacks)
    IO.inspect(res)
  end

end
