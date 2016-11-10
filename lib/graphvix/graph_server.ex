defmodule Graphvix.GraphServer do
  use GenServer

  @empty_graph %{nodes: %{}, edges: %{}, clusters: %{}, attrs: []}

  def start_link(state_pid) do
    GenServer.start_link(__MODULE__, {state_pid, nil}, name: __MODULE__)
  end

  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  def graphs do
    GenServer.call(__MODULE__, :ls)
  end

  def new(name) do
    GenServer.cast(__MODULE__, {:new, name})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:ls, _from, state={state_pid, _}) do
    graph_names = Graphvix.State.ls
    {:reply, graph_names, state}
  end

  def handle_cast({:new, name}, state={state_pid, _}) do
    Graphvix.State.new_graph(state_pid, name)
    {:noreply, state}
  end
  def handle_cast(:clear, {state_pid, _}) do
    Graphvix.State.clear(state_pid)
    {:noreply, {state_pid, nil}}
  end
end

