# Crapetto

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

# Authentication

Utilisé: mix phx.auth.gen Accounts User users
qui génère le code complet pour le login, etc...
- Cela crée des tables (users, tokens,...)
- un context "accounts" avec un répertoire associé : 3 fichiers user.ex, user_token.ex et user_notifier.ex

Pour récupérer le user dans la session liveview, 
def mount(params, session, socket) do
devient
def mount(params, %{"user_token" => token}, socket) do 
avec     current_user = Accounts.get_user_by_session_token(token)
pour récupérer le user


# Créer un CSS avec Tailwind
npx tailwindcss-cli build -o assets/css/tailwind.css

# Tests
