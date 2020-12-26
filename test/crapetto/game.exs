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
    IO.inspect(game)
  end
end
