defmodule Crapetto.GameServer do
  use GenServer

  alias Crapetto.Game

  ## Defining GenServer Callbacks

  def create(id_owner, owner) do
    GenServer.start_link(Crapetto.GameServer, %{owner: owner, id_owner: id_owner})
  end

  def get_state(game) do
    GenServer.call(game, :state)
  end

  @impl true
  def init(%{owner: owner, id_owner: id_owner}) do
    id_game = Enum.reduce(1..6, "", fn _, acc -> Enum.random(String.graphemes("ABCDEFGHIJKLMNOPQRSTUVWXYZ23456789")) <> acc end)
    new_game = Game.new_game(id_game, id_owner, owner)
    {:ok, new_game}
  end

  @impl true
  def handle_call(:state, _from, game) do
    {:reply, game, game}
  end
end
