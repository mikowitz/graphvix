defmodule Graphvix.GraphServer do
  use GenServer

  def start_link(state_pid) do
    GenServer.start_link(__MODULE__, state_pid, name: __MODULE__)
  end

  def graphs do
    GenServer.call(__MODULE__, :ls)
  end


  def init(state_pid) do
    {:ok, state_pid}
  end

  def handle_call(:ls, _from, state_pid) do
    graph_names = Graphvix.State.ls(state_pid)
    {:reply, graph_names, state_pid}
  end
end

