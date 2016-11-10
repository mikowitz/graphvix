use Mix.Config

config :mix_test_watch,
  clear: true,
  tasks: [
    "espec",
  ]

config :graphvix,
  file_storage_location: "/tmp/"
