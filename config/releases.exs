import Config

config :what_you_listen, WhatYouListenWeb.Endpoint,
  http: [:inet6, port: System.get_env("PORT") || 4000]

config :what_you_listen, :mq,
  host: System.fetch_env!("MQ_HOST"),
  port: System.fetch_env!("MQ_PORT"),
  user: System.fetch_env!("MQ_USERNAME"),
  pass: System.fetch_env!("MQ_PASSWORD")
