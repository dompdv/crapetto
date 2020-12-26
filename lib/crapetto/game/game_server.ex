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

  def add_player(game, id_player) do
    GenServer.call(game, {:add, id_player})
  end

  def remove_player(game, id_player) do
    GenServer.call(game, {:remove, id_player})
  end

  @impl true
  def init(%{owner: owner, id_owner: id_owner}) do
    new_game = Game.new_game(id_owner, owner)
    {:ok, new_game}
  end

  @impl true
  def handle_call(:state, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call({:add, id_player}, _from, game) do
    new_game = Game.add_player(game, id_player)
    Phoenix.PubSub.broadcast(Crapetto.PubSub, "game:#{game.id_game}", {:add_player, id_player})
    Phoenix.PubSub.broadcast(Crapetto.PubSub, "games_arena", :game_modification)

    {:reply, new_game, new_game}
  end

  @impl true
  def handle_call({:remove, id_player}, _from, game) do
    new_game = Game.remove_player(game, id_player)
    Phoenix.PubSub.broadcast(Crapetto.PubSub, "game:#{game.id_game}", {:remove_player, id_player})
    Phoenix.PubSub.broadcast(Crapetto.PubSub, "games_arena", :game_modification)
    {:reply, new_game, new_game}
  end

end
