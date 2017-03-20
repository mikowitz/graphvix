defmodule Graphvix.Graph do
  @moduledoc """
  `Graphvix.Graph` manages saving, loading, and presenting the state
  of a graph.

  NB. All examples below assume you have run

      iex> alias Graphvix.{Graph, Node, Edge, Cluster}

  ## Overview

  To reduce user effort, the module keeps only a single graph in state
  at any given time. Graphs can be saved and reloaded to switch between working
  with several different graphs at a time.

      iex> Graph.new(:first_graph)

      iex> ... # Add some data to the first graph

      iex> Graph.switch(:second_graph) # Creates a new graph and loads it, saving the old graph at the same time.

      iex> ... # Add some data to the second graph

      iex> Graph.switch(:first_graph) # Saves `:second_graph` and reloads `first_graph`


  ## State

  State is managed by the `Graphvix.State` module. This module is responsible for maintaining in memory
  the state of any created graphs, as well as persisting the data to disk and loading it back into memory.
  The `State` module should never be accessed directly. All interaction with it occurs through functions
  availabel on `Graph`.

  In the event of a process crash, the supervision tree managing `State` and `Graph` will make sure that the
  most current state of a graph is saved and reloaded when the `Graph` process restarts.

  ## Modifying graphs

  Elements are added and removed from the graph using the `Node`, `Edge`,
  and `Cluster` modules.

      iex> {n_id, node} = Node.new(label: "Start", color: "blue")
      iex> {n2_id, node2} = Node.new(label: "End", color: "red")
      iex> {e_id, edge} = Edge.new(n_id, n2_id, color: "green")
      iex> {c_id, cluster} = Cluster.new([n_id, n2_id])

  Settings can be added to an element. Setting an attribute's value to `nil`
  will remove the attribute.

      iex> Node.update(n_id, shape: "triangle")
      iex> Node.update(n2_id, color: nil) # Removes the key `color` from the node`s attributes keyword map

  A cluster's contents can be updated using `add` and `remove`

      iex> {n3_id, node3} = Node.new(label: "Something else")
      iex> Cluster.add(c_id, n3_id)
      iex> Cluster.remove(c_id, n_id)

  ## Saving and viewing graphs

  Graphs can be easily saved in .dot format

      iex> Graph.save # Saves the current state of the graph as a .dot file

  These files can then be compiled to .pdf/.png/etc at the command line,
  or via additional helper functions on the `Graph` module

      iex> Graph.compile # Generates dot and pdf files named for the graph
      iex> Graph.compile(:png) # Generates dot and png files named for the graph

  To immediately view the current state of a graph, there is `Graph.graph`

      iex> Graph.graph # Generates dot and pdf files named for the graph, and opens the PDF in your OS's default viewer
      iex> Graph.graph(:png) # Same as above, but generates and opens a .png file

  """
  use GenServer
  alias Graphvix.Writer
  import Graphvix.Graph.Helpers
  require Logger

  defstruct [
    state_pid: Graphvix.State,
    graph: nil,
    data_path: "/tmp/graphvix"
  ]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    # initialize state
    state = struct(%__MODULE__{}, opts)

    # init the current graph
    params = %{graph: Graphvix.State.current_graph(state.state_pid)}
    state = struct(state, params)

    # finish init
    {:ok, state}
  end

  ## API

  @doc """
  Returns a list of graphs currently stored by Graphvix

      iex> Graph.new(:first)
      iex> Graph.ls
      [:first]

  """
  @spec ls :: [atom]
  def ls do
    GenServer.call(__MODULE__, :ls)
  end

  @doc """
  Creates a new graph named `name` and sets it to the current graph

      iex> Graph.new(:first)
      :ok

  """
  @spec new(atom) :: :ok
  def new(name) do
    GenServer.cast(__MODULE__, {:new, name})
  end

  @doc """
  Switches the current graph to the graph named `name`.

  Creates a new graph if it doesn't exist.

      iex> Graph.new(:first)
      iex> Graph.switch(:second) # creates a graph named `:second`
      iex> Graph.switch(:first) # loads the existing graph named `:first`

  """
  @spec switch(atom) :: :ok
  def switch(name) do
    GenServer.cast(__MODULE__, {:switch, name})
  end

  @doc """
  Returns the name of the current graph.

      iex> Graph.new(:first)
      iex> Graph.current_graph
      :first

  """
  @spec current_graph :: {atom, map}
  def current_graph do
    GenServer.call(__MODULE__, :current_graph)
  end

  @doc """
  Empties the stored state of Graphvix.

  Caution: Will delete all stored data from disk.

      iex> Graph.clear
      iex> Graph.ls
      []

  """
  @spec clear :: :ok
  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  @doc """
  Updates a graph-wide setting.

      iex> Graph.new(:first)
      iex> Graph.update(size: "4, 4")
      :ok

  """
  @spec update(Keyword.t) :: :ok
  def update(attrs) do
    GenServer.cast(__MODULE__, {:update, attrs})
  end

  @doc """
  Returns a string of the current graph in .dot format.

      iex> Graph.new(:first)
      iex> Graph.write
      "digraph G {
      }"

  """
  @spec write :: String.t
  def write do
    GenServer.call(__MODULE__, :write)
  end

  @doc """
  Returns the Elixir map form of the current graph.

      iex> Graph.new(:first)
      iex> Graph.get
      %{
        nodes: %{},
        edges: %{},
        clusters: %{},
        attrs: []
      }

  """
  @spec get :: map
  def get do
    GenServer.call(__MODULE__, :get)
  end

  @doc """
  Writes the current graph to a .dot file and compiles it.

  Defaults to `pdf`.

      iex> Graph.new(:first)
      iex> Graph.compile
      :ok #=> creates "first.dot" and "first.pdf"
      iex> Graph.compile(:png)
      :ok #=> creates "first.dot" and "first.png"

  """
  @spec compile(atom | nil) :: :ok
  def compile(filetype \\ :pdf) do
    GenServer.cast(__MODULE__, {:compile, filetype})
  end

  @doc """
  Saves the current graph to a .dot file.

      iex> Graph.new(:first)
      iex> Graph.save
      :ok #=> creates "first.dot"

  """
  @spec save :: :ok
  def save do
    GenServer.cast(__MODULE__, :save)
  end

  @doc """
  Writes the current graph to a .dot file, compiles it, and opens the compiled graph.

  Defaults to `pdf`.

      iex> Graph.new(:first)
      iex> Graph.graph
      :ok #=> creates "first.dot" and "first.pdf"; opens "first.pdf"
      iex> Graph.graph(:png)
      :ok #=> creates "first.dot" and "first.png"; opens "first.png"

  """
  @spec graph(atom | nil) :: :ok
  def graph(filetype \\ :pdf) do
    GenServer.cast(__MODULE__, {:graph, filetype})
  end

  # Callbacks

  def handle_call(:current_graph, _from, state=%__MODULE__{graph: {name, _graph}}) do
    {:reply, name, state}
  end
  def handle_call(:ls, _from, state=%__MODULE__{state_pid: state_pid}) do
    graph_names = Graphvix.State.ls(state_pid)
    {:reply, graph_names, state}
  end
  def handle_call({:add_node, attrs}, _from, state=%__MODULE__{graph: graph}) do
    Logger.debug("graph: #{inspect graph}")
    case graph do
      nil ->
        {:reply, {:error, :enograph}, state}
      {name, graph} ->
        id = get_id
        new_node = %{ attrs: attrs }
        new_nodes = Map.put(graph.nodes, id, new_node)
        new_graph = %{ graph | nodes: new_nodes }
        {:reply, {id, new_node}, Map.put(state, :graph, {name, new_graph})}
    end
  end
  def handle_call({:add_edge, start_id, end_id, attrs}, _from, state=%__MODULE__{graph: {name, graph}}) do
    id = get_id
    new_edge = %{ start_node: start_id, end_node: end_id, attrs: attrs }
    new_edges = Map.put(graph.edges, id, new_edge)
    new_graph = %{ graph | edges: new_edges }
    {:reply, {id, new_edge}, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_call({:add_cluster, node_ids}, _from, state=%__MODULE__{graph: {name, graph}}) do
    id = get_id
    new_cluster = %{ node_ids: node_ids }
    new_clusters = Map.put(graph.clusters, id, new_cluster)
    new_graph = %{ graph | clusters: new_clusters }
    {:reply, {id, new_cluster}, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_call({:add_to_cluster, cluster_id, node_ids}, _from, state=%__MODULE__{graph: {name, graph}}) do
    cluster = Map.get(graph.clusters, cluster_id)
    new_node_ids = (cluster.node_ids ++ node_ids) |> Enum.uniq
    new_cluster = %{ cluster | node_ids: new_node_ids }
    new_clusters = %{ graph.clusters | cluster_id => new_cluster }
    new_graph = %{ graph | clusters: new_clusters }
    {:reply, new_cluster, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_call({:remove_from_cluster, cluster_id, node_ids}, _from, state=%__MODULE__{graph: {name, graph}}) do
    cluster = Map.get(graph.clusters, cluster_id)
    new_node_ids = (cluster.node_ids -- node_ids) |> Enum.uniq
    new_cluster = %{ cluster | node_ids: new_node_ids }
    new_clusters = %{ graph.clusters | cluster_id => new_cluster }
    new_graph = %{ graph | clusters: new_clusters }
    {:reply, new_cluster, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_call({:find, id, type}, _from, state=%__MODULE__{graph: {name, graph}}) do
    res = case find_element(graph, id, type) do
      nil -> {:error, {:enotfound, type}}
      element -> element
    end
    {:reply, res, state}
  end
  def handle_call({:delete, id, type}, _from, state=%__MODULE__{graph: {name, graph}}) do
    {res, new_graph} = case kind_of_element(graph, id) do
      ^type -> {:ok, remove(type, id, graph)}
      _ -> {{:error, {:enotfound, type}}, graph}
    end
    {:reply, res, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_call(:get, _from, state=%__MODULE__{graph: {name, graph}}) do
    {:reply, graph, state}
  end
  def handle_call(:write, _from, state=%__MODULE__{graph: {name, graph}}) do
    {:reply, Writer.write(graph), state}
  end

  def handle_cast({:update, type, id, attrs}, state=%__MODULE__{graph: {name, graph}}) do
    new_graph = case find_element(graph, id, type) do
      nil -> graph
      _ ->
        case kind_of_element(graph, id) do
          :node -> update_attrs_for_element_in_graph(graph, id, Map.get(graph.nodes, id), :nodes, attrs)
          :edge -> update_attrs_for_element_in_graph(graph, id, Map.get(graph.edges, id), :edges, attrs)
          _ -> graph
        end
    end
    {:noreply, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_cast({:new, name}, state=%__MODULE__{state_pid: state_pid}) do
    {name, new_graph} = Graphvix.State.new_graph(state_pid, name)
    {:noreply, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_cast(:clear, state=%__MODULE__{state_pid: state_pid}) do
    Graphvix.State.clear(state_pid)
    {:noreply, Map.put(state, :graph, nil)}
  end
  def handle_cast({:switch, name}, state=%__MODULE__{state_pid: state_pid, graph: {current_name, current_graph}}) do
    Graphvix.State.save(state_pid, current_name, current_graph)
    {name, new_graph} = Graphvix.State.load(state_pid, name)
    {:noreply, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_cast({:update, attrs}, state=%__MODULE__{graph: {name, graph}}) do
    new_graph = %{ graph | attrs: merge_without_nils(graph.attrs, attrs) }
    {:noreply, Map.put(state, :graph, {name, new_graph})}
  end
  def handle_cast(:save, state=%__MODULE__{graph: {name, graph}}) do
    graph_path = Path.join([state.data_path, to_string(name)])
    graph
    |> Writer.write()
    |> Writer.save(graph_path)
    {:noreply, state}
  end
  def handle_cast({:compile, filetype}, state=%__MODULE__{graph: {name, graph}}) do
    graph_path = Path.join([state.data_path, to_string(name)])
    graph
    |> Writer.write()
    |> Writer.save(graph_path)
    |> Writer.compile(filetype)
    {:noreply, state}
  end
  def handle_cast({:graph, filetype}, state=%__MODULE__{graph: {name, graph}}) do
    graph_path = Path.join([state.data_path, to_string(name)])
    graph
    |> Writer.write()
    |> Writer.save(graph_path)
    |> Writer.compile(filetype)
    |> Writer.open()
    {:noreply, state}
  end

  def terminate(_reason, state=%{state_pid: state_pid, graph: {current_name, current_graph}}) do
    Graphvix.State.save(state_pid, current_name, current_graph)
  end
end
