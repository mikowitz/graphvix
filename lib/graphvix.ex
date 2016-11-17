defmodule Graphvix do
  use Application

  @moduledoc """
  Use `Graphvix` to create a directed graphs in Elixir.

  See `Graphvix.Graph` for full documentation.
  """

  @doc false
  def start(_type, _) do
    {:ok, _pid} = Graphvix.Supervisor.start_link()
  end
end
