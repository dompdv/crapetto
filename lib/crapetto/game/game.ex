defmodule Crapetto.Game do
  @enforce_keys [:id_game, :owner, :id_owner]
  defstruct [:id_game, :owner, :id_owner, status: :starting, players: []]

  def new_game(id_game, id_owner, owner), do: %Crapetto.Game{id_game: id_game, owner: owner, id_owner: id_owner}

  def add_player(%Crapetto.Game{status: :starting, players: players} = game, a_player) do
    new_players = if Enum.member?(players, a_player), do: players, else: [a_player | players]
    %Crapetto.Game{game | players: new_players}
  end
end
