defmodule Graphvix.State do
  defstruct graphs: [], current_graph: nil

  use GenServer
  alias __MODULE__

  def start_link do
    GenServer.start_link(__MODULE__, %State{})
  end

  def ls(pid) do
    GenServer.call(pid, :ls)
  end

  def handle_call(:ls, _from, state=%State{ graphs: graphs }) do
    {:reply, Keyword.keys(graphs), state}
  end
end
