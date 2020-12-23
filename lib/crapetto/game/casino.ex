defmodule Crapetto.Casino do
  use GenServer

  alias Crapetto.Game

@doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the game whose id is `id_game` stored in `server`.

  Returns `{:ok, game_desc}` if the game exists, `:error` otherwise.
  """
  def lookup(casino, id_game) do
    GenServer.call(casino, {:lookup, id_game})
  end

  def lookup(id_game) do
    GenServer.call(Crapetto.Casino, {:lookup, id_game})
  end


  def list(casino) do
    GenServer.call(casino, :list)
  end
  def list() do
    GenServer.call(Crapetto.Casino, :list)
  end

  @doc """
  Create a new game with some initial game_description
  Returns `{:ok, id_game}` if creation succeeds, `:error` otherwise.
  """
  def create(server, %{owner: owner} = params) do
    GenServer.call(server, {:create, %{owner: owner}})
  end
  def create(%{owner: owner} = params) do
    GenServer.call(Crapetto.Casino, {:create, %{owner: owner}})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, id_game}, _from, games) do
    {:reply, Map.fetch(games, id_game), games}
  end

  @impl true
  def handle_call(:list, _from, games) do
    {:reply, {:ok, games}, games}
  end

  @impl true
  def handle_call({:create, %{owner: owner}}, _from, games) do
    id_game = Enum.reduce(1..20, "", fn _, acc -> Enum.random(String.graphemes("ABCDEFGHIJKLMNOPQRSTUVWXYZ23456789")) <> acc end)
    new_game = Game.new_game(id_game, owner)
    new_state = Map.put(games, id_game, new_game)
    {:reply, {:ok, id_game} , new_state}
  end
end
