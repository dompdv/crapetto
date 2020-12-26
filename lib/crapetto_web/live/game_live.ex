defmodule CrapettoWeb.GameLive do
  use CrapettoWeb, :live_view
  alias Crapetto.Accounts
  alias Crapetto.Casino
  alias CrapettoWeb.Router.Helpers, as: Routes


@impl true
def mount(_params, %{"user_token" => token}, socket) do
  # Find the current user from the session and put it in the LiveView sessio,n
  current_user = Accounts.get_user_by_session_token(token)
  {:ok, assign(socket, %{current_user: current_user})}
end

@impl true
def handle_params(%{"id" => id_game} = params, uri, socket) do
  IO.inspect({"HANDLE PARAMS", params, uri})
  case Casino.lookup(id_game) do
    :error -> {:noreply , push_redirect(socket, to: "/")}
    game ->  {:noreply , assign(socket, %{id_game: id_game, game: game})}
  end
end


end
