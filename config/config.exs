# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :elm_phoenix_chat, ElmPhoenixChat.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "XMYqS/zpgf5KUJZaw18DYs30apVKK4SoHD7iJ3UR6+RkePWDtQxTO2QoTKTxLING",
  render_errors: [view: ElmPhoenixChat.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ElmPhoenixChat.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
