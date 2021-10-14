# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :what_you_listen, WhatYouListenWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "eR030nqJga55OsfPMDg/mvAAHVgkSyBnopIhMERHwRS/ZlLtjZkp1gr1gh9zvFNA",
  render_errors: [view: WhatYouListenWeb.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :what_you_listen, :mq,
  host: "localhost",
  port: "5672",
  user: "guest",
  pass: "guest"

config :what_you_listen, :music_service, url: "https://api.deezer.com"

config :what_you_listen, WhatYouListen.Tracks.Action, client: WhatYouListen.Tracks.Clients.Basic

config :what_you_listen, RateLimiter, timeframe_max_requests: 50, timeframe: 5

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
