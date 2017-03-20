use Mix.Config

config :mix_test_watch,
  clear: true,
  tasks: [
    "espec",
  ]

config :graphvix,
  data_path: "/tmp/graphvix"
