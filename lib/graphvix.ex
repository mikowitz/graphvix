defmodule Graphvix do
  use Application

  @moduledoc """
  Use `Graphvix` to create a directed graphs in Elixir.

  See `Graphvix.Graph` for full documentation.
  """

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    opts = Application.get_all_env(:graphvix)

    children = [
      worker(Graphvix.State, [opts]),
      worker(Graphvix.Graph, [opts]),
    ]

    opts = [strategy: :one_for_one, name: Graphvix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
