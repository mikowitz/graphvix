import Config

config :mix_test_watch,
  clear: true,
  tasks: [
    "test",
    "credo --all --strict",
    "docs"
  ]

config :graphvix, :compiler, "echo"
