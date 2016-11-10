defmodule Graphvix.State do
  defstruct graphs: [], current_graph: nil

  @file_storage_location Application.get_env(:graphvix, :file_storage_location)
  @default_file_location "/tmp"
  @storage_file_name "graphvix.store"
  @empty_graph %{nodes: %{}, edges: %{}, clusters: %{}, attrs: []}

  use GenServer
  alias __MODULE__

  def start_link do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  def save do
    GenServer.cast(__MODULE__, :save)
  end
  def load do
    GenServer.cast(__MODULE__, :load)
  end

  def ls do
    GenServer.call(__MODULE__, :ls)
  end
  def new_graph(_pid, name) do
    GenServer.cast(__MODULE__, {:new, name})
  end
  def clear(pid) do
    GenServer.cast(pid, :clear)
  end

  def handle_call(:ls, _from, state=%State{ graphs: graphs }) do
    {:reply, Keyword.keys(graphs), state}
  end

  def handle_cast({:new, name}, state) do
    new_graphs = [{name, @empty_graph}|state.graphs]
    {:noreply, %State{ state | graphs: new_graphs}}
  end
  def handle_cast(:clear, _state) do
    {:noreply, %State{}}
  end
  def handle_cast(:save, state) do
    File.write(@file_storage_location <> @storage_file_name, inspect(state))
    #IO.inspect state
    {:noreply, state}
  end
  def handle_cast(:load, _state) do
    {new_state, _} = Code.eval_file(@file_storage_location <> @storage_file_name)
    #IO.inspect new_state
    {:noreply, new_state}
  end
end
