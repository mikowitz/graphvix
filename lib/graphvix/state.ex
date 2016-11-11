defmodule Graphvix.State do
  defstruct graphs: %{}, current_graph: nil

  @file_store_path Application.get_env(:graphvix, :file_storage_location)
  @default_file_store_path "/tmp"
  @file_store_name "graphvix.store"
  @empty_graph %{nodes: %{}, edges: %{}, clusters: %{}, attrs: []}

  use GenServer
  alias __MODULE__

  def start_link do
    state = case File.read(storage_location) do
      {:ok, content} ->
        {state, _} = Code.eval_string(content)
        state
      _ ->
        %State{}
    end
    GenServer.start_link(__MODULE__, state)
  end

  def current_graph(pid) do
    GenServer.call(pid, :current_graph)
  end

  def ls(pid) do
    GenServer.call(pid, :ls)
  end
  def new_graph(pid, name) do
    GenServer.call(pid, {:new, name})
  end
  def clear(pid) do
    GenServer.cast(pid, :clear)
  end

  def load(pid, name) do
    GenServer.call(pid, {:load, name})
  end

  def save(pid, name, graph) do
    GenServer.cast(pid, {:save, name, graph})
  end

  def init(state) do
    schedule_save()
    {:ok, state}
  end

  def handle_call(:current_graph, _from, state=%State{ current_graph: current_graph}) do
    {:reply, current_graph, state}
  end
  def handle_call(:ls, _from, state=%State{ graphs: graphs }) do
    {:reply, Map.keys(graphs), state}
  end
  def handle_call({:new, name}, _from, state) do
    new_graphs = Map.put(state.graphs, name, @empty_graph)
    new_state = %State{ state | graphs: new_graphs, current_graph: {name, @empty_graph}}
    {:reply, {name, @empty_graph}, new_state}
  end
  def handle_call({:load, name}, _from, state) do
    graph = case Map.get(state.graphs, name) do
      nil -> @empty_graph
      g -> g
    end
    new_state = %State{ state | current_graph: {name, graph} }
    {:reply, {name, graph}, new_state}
  end

  def handle_cast(:clear, _state) do
    {:noreply, %State{}}
  end
  def handle_cast(:save, state) do
    File.write(storage_location, inspect(state))
    {:noreply, state}
  end
  def handle_cast(:load, _state) do
    {new_state, _} = Code.eval_file(storage_location)
    {:noreply, new_state}
  end
  def handle_cast({:save, name, graph}, state) do
    new_graphs = Map.update(state.graphs, name, @empty_graph, fn _ -> graph end)
    new_state = %State{ state | graphs: new_graphs }
    {:noreply, new_state}
  end

  def handle_info(:save, state) do
    File.write(storage_location, inspect(state))
    schedule_save()
    {:noreply, state}
  end

  defp storage_location do
    file_store_path <> @file_store_name
  end

  defp file_store_path do
    @file_store_path || @default_file_store_path
  end

  defp schedule_save do
    Process.send_after(self(), :save, 60_000)
  end
end
