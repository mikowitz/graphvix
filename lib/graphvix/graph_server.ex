defmodule Graphvix.GraphServer do
  use GenServer

  def start_link(state_pid) do
    GenServer.start_link(__MODULE__, {state_pid, nil}, name: __MODULE__)
  end

  ## API

  def ls do
    GenServer.call(__MODULE__, :ls)
  end

  def new(name) do
    GenServer.cast(__MODULE__, {:new, name})
  end

  def switch(name) do
    GenServer.cast(__MODULE__, {:switch, name})
  end

  def current_graph do
    GenServer.call(__MODULE__, :current_graph)
  end

  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  ## CALLBACKS

  def init(state) do
    {:ok, state}
  end

  def handle_call(:current_graph, _from, state={_, graph}) do
    {:reply, graph, state}
  end
  def handle_call(:ls, _from, state={state_pid, _}) do
    graph_names = Graphvix.State.ls(state_pid)
    {:reply, graph_names, state}
  end

  def handle_cast({:new, name}, {state_pid, _}) do
    new_graph = Graphvix.State.new_graph(state_pid, name)
    {:noreply, {state_pid, new_graph}}
  end
  def handle_cast(:clear, {state_pid, _}) do
    Graphvix.State.clear(state_pid)
    {:noreply, {state_pid, nil}}
  end
  def handle_cast({:switch, name}, {state_pid, {current_name, current_graph}}) do
    Graphvix.State.save(state_pid, current_name, current_graph)
    new_graph = Graphvix.State.load(state_pid, name)
    {:noreply, {state_pid, new_graph}}
  end

  def terminate(_reason, {state_pid, current_graph}) do
    IO.inspect state_pid
    IO.inspect current_graph
  end
end

