defmodule Graphvix do
  use Application

  @moduledoc """
  Use `Graphvix` to create a directed graphs utilizing `GenServer`.

  See `Graphvix.Graph` for full documentation.
  """

  def start(_type, _) do
    {:ok, _pid} = Graphvix.Supervisor.start_link()
  end
end
