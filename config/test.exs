import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :what_you_listen, WhatYouListenWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :what_you_listen, WhatYouListen.Tracks.Action, client: WhatYouListen.Tracks.Clients.Stub
