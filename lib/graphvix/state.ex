defmodule Graphvix.State do
  @moduledoc false
  defstruct [
    graphs: %{},
    current_graph: nil,
    data_path: "/tmp/graphvix",
    data_file: "graphvix.store",
  ]

  @empty_graph %{nodes: %{}, edges: %{}, clusters: %{}, attrs: []}

  use GenServer
  alias __MODULE__

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(opts) do
    # initialize state and pull in any opts
    state = struct(%__MODULE__{}, opts)

    # try to create the data_path if it doesn't already exist
    File.mkdir_p!(state.data_path)

    # load any terms saved on disk
    data_file_path = Path.join([state.data_path, state.data_file])
    saved_data =
      case load_data(data_file_path) do
        {:ok, data} -> data
        {:error, _} -> %{}
      end

    # update state with any stored data
    GenServer.cast(self(), :load)

    # schedule a save
    schedule_save()

    # finish init
    {:ok, state}
  end

  # API

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

  # Callbacks

  def handle_call(:current_graph, _from, state) do
    reply = {state.current_graph, Map.get(state.graphs, state.current_graph)}
    {:reply, reply, state}
  end
  def handle_call(:ls, _from, state=%State{ graphs: graphs }) do
    {:reply, Map.keys(graphs), state}
  end
  def handle_call({:new, name}, _from, state) do
    new_graphs = Map.put(state.graphs, name, @empty_graph)
    new_state = %State{ state | graphs: new_graphs, current_graph: name}
    {:reply, {name, @empty_graph}, new_state}
  end
  def handle_call({:load, name}, _from, state) do
    {new_graphs, graph} = case Map.get(state.graphs, name) do
      nil -> {Map.put(state.graphs, name, @empty_graph), @empty_graph}
      g -> {state.graphs, g}
    end
    new_state = %State{ state | current_graph: name, graphs: new_graphs }
    {:reply, {name, graph}, new_state}
  end

  def handle_cast(:clear, _state) do
    {:noreply, %State{}}
  end
  def handle_cast(:save, state) do
    data_file_path = Path.join([state.data_path, state.data_file])
    save_data(data_file_path, state)
    {:noreply, state}
  end
  def handle_cast(:load, state) do
    # load any terms saved on disk
    data_file_path = Path.join([state.data_path, state.data_file])
    saved_data =
      case load_data(data_file_path) do
        {:ok, data} -> data
        {:error, _} -> %{}
      end

    # update state with any stored data
    params = %{
      graphs: Map.get(saved_data, :graphs, %{}),
      current_graph: Map.get(saved_data, :current_graph, nil),
    }
    state = struct(state, params)
    {:noreply, state}
  end
  def handle_cast({:save, name, graph}, state) do
    new_graphs = Map.update(state.graphs, name, @empty_graph, fn _ -> graph end)
    new_state = %State{ state | graphs: new_graphs }
    {:noreply, new_state}
  end

  def handle_info(:save, state) do
    data_file_path = Path.join([state.data_path, state.data_file])
    save_data(data_file_path, state)
    schedule_save()
    {:noreply, state}
  end

  # Helpers

  defp save_data(path, data) do
    File.write(path, :erlang.term_to_binary(data))
  end

  defp load_data(path) do
    case File.read(path) do
      {:ok, data_raw} -> {:ok, :erlang.binary_to_term(data_raw)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp schedule_save do
    Process.send_after(self(), :save, 60_000)
  end
end
