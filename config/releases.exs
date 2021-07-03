import Config

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

liveview_salt =
  System.get_env("LIVEVIEW_SALT") ||
    raise """
    environment variable LIVEVIEW_SALT is missing.
    You can generate one by calling: mix phx.gen.secret
    """

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

proxy_host = System.get_env("PROXY_HOST", "localhost")
proxy_port = String.to_integer(System.get_env("PROXY_PORT", "4000"))
proxy_scheme = System.get_env("PROXY_SCHEME", "http")
proxy_path = System.get_env("PROXY_PATH", "")
port = String.to_integer(System.get_env("PORT", "4000"))
pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")


config :crapetto_web, CrapettoWeb.Endpoint,
  url: [host: proxy_host, port: proxy_port, scheme: proxy_scheme, path: proxy_path],
  secret_key_base: secret_key_base,
  http: [
    port: port,
    transport_options: [socket_opts: [:inet6]]
  ],
  live_view: [signing_salt: liveview_salt]

config :crapetto, Crapetto.Repo,
  # ssl: true,
  url: database_url,
  pool_size: pool_size
