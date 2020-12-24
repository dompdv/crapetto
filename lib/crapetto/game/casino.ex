defmodule Crapetto.Casino do
  use GenServer

  alias Crapetto.Game
  alias Crapetto.GameServer

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
  def create(server, id_owner, owner) do
    GenServer.call(server, {:create, %{owner: owner, id_owner: id_owner}})
  end
  def create(id_owner, owner) do
    GenServer.call(Crapetto.Casino, {:create, %{owner: owner, id_owner: id_owner}})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, id_game}, _from, games) do
    game_pid = Map.fetch(games, id_game)
    {:reply, GameServer.get_state(game_pid), games}
  end

  @impl true
  def handle_call(:list, _from, games) do
    game_states =
      games
      |> Enum.to_list()
      |> Enum.map(fn {k, v} -> {k, GameServer.get_state(v)} end)
      |> Map.new()
    {:reply, {:ok, game_states}, games}
  end

  @impl true
  def handle_call({:create, %{owner: owner, id_owner: id_owner}}, _from, games) do
    {:ok, new_game_pid} = GameServer.create(id_owner, owner)
    new_game = GameServer.get_state(new_game_pid)
    new_state = Map.put(games, new_game.id_game, new_game_pid)
    Phoenix.PubSub.broadcast(Crapetto.PubSub, "games_arena", :new_game)
    {:reply, {:ok, new_game.id_game} , new_state}
  end
end
