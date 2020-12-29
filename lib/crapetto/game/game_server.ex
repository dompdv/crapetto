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

  def start_game(game) do
    GenServer.call(game, :start)
  end
  def terminate_game(game) do
    GenServer.call(game, :terminate)
  end


  def play_ligretto(game, player) do
    GenServer.call(game, {:play_ligretto, player})
  end

  def play_displayed(game, player) do
    GenServer.call(game, {:play_displayed, player})
  end
  def play_series(game, player, serie) do
    GenServer.call(game, {:play_series, player, serie})
  end

  def show_three(game, player) do
    GenServer.call(game, {:show_three, player})
  end

  @impl true
  def init(%{owner: owner, id_owner: id_owner}) do
    new_game = Game.new_game(id_owner, owner)
    {:ok, new_game}
  end

  defp broadcast(game, what) do
    Phoenix.PubSub.broadcast(Crapetto.PubSub, "game:#{game.id_game}", what)
    Phoenix.PubSub.broadcast(Crapetto.PubSub, "games_arena", :game_modification)
  end


  @impl true
  def handle_call(:state, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call({:add, id_player}, _from, game) do
    new_game = Game.add_player(game, id_player)
    broadcast(new_game, {:add_player, id_player})
    {:reply, new_game, new_game}
  end

  @impl true
  def handle_call({:remove, id_player}, _from, game) do
    new_game = Game.remove_player(game, id_player)
    broadcast(new_game, {:remove_player, id_player})
    {:reply, new_game, new_game}
  end

  @impl true
  def handle_call(:start, _from, game) do
    new_game = Game.start_game(game)
    broadcast(new_game, :start)
    {:reply, new_game, new_game}
  end

  @impl true
  def handle_call(:terminate, _from, game) do
    new_game = Game.start_game(game)
    broadcast(new_game, :terminate)
    {:reply, new_game, new_game}
  end

  @impl true
  def handle_call({:play_ligretto, player}, _from, game) do
    if game.status == :playing do
      {result, new_game} = Game.play_ligretto(game, player)
      broadcast(new_game, {:play_ligretto, result, player})
      {:reply, {result, new_game}, new_game}
    else
      {:reply, {:ok, game}, game}
    end
  end

  @impl true
  def handle_call({:play_displayed, player}, _from, game) do
    if game.status == :playing do
      {result, new_game} = Game.play_displayed(game, player)
      broadcast(new_game, {:play_displayed, result, player})
      {:reply, {result, new_game}, new_game}
    else
      {:reply, {:ok, game}, game}
    end
  end

  @impl true
  def handle_call({:show_three, player}, _from, game) do
    if game.status == :playing do
      new_game = Game.show_three(game, player)
      broadcast(new_game, {:show_three, player})
      {:reply, new_game, new_game}
    else
      {:reply, game, game}
    end
  end

  @impl true
  def handle_call({:play_series, player, serie}, _from, game) do
    if game.status == :playing do
      {result, new_game} = Game.play_serie(game, player, serie)
      broadcast(new_game, {:play_series, result, player})
      {:reply, {result, new_game}, new_game}
    else
      {:reply, {:ok, game}, game}
    end
  end


end
