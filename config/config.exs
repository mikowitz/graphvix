import Config

config :graphvix, :compiler, "dot"

import_config "#{Mix.env()}.exs"
