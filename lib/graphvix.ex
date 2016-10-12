defmodule Graphvix do
  @moduledoc """
  Use `Graphvix` to create a directed graph utilizing `GenServer`.

  `Graphvix` allows:

  * creating a new graph
  ```
  graph = Graphvix.new
  ```

  * adding/updating nodes and edges
  ```
  node1 = Graphvix.add_node(graph, label: "Start")
  node2 = Graphvix.add_node(graph, label: "End")

  edge = Graphvix.add_edge(graph, node1, node2, color: "red")

  Graphvix.update(graph, node1.id, color: "blue")
  ```

  * saving to a DOT file
  ```
  Graphvix.save(graph, "my_graph")
  ```

  * compiling to PDF (also saves the graph as an intermediate step)
  ```
  Graphvix.graph(graph)
  ```
  """

  use GenServer
  use Graphvix.Callbacks
  alias Graphvix.Writer

  @doc """
  Creates a new graph, and returns a PID pointing to the process managing
  the graph.

  ## Examples

      iex> graph = Graphvix.new
      #PID<0.522.0>

  """
  def new do
    {:ok, pid} = GenServer.start(__MODULE__, %{nodes: %{}, edges: %{}, clusters: %{}})
    pid
  end

  @doc """
  Returns the intetrnal structure of the graph, a map with nested maps for
  nodes and edges.

  ## Examples

      iex> graph = Graphvix.new
      iex> Graphvix.get(graph)
      %{ nodes: %{}, edges: %{} }

  """
  def get(graph) do
    GenServer.call(graph, :get)
  end

  @doc """
  Adds a new node to the `graph` with the provided `attrs` and a generated unique id.

  Returns the map containing the id and attributes for the new node.

  ## Examples

      iex> graph = Graphvix.new
      iex> Graphvix.add_node(graph, label: "First Node", color: "red")
      %{ id: 1, attrs: [label: "First Node", color: "red"] }

  """
  def add_node(graph, attrs \\ []) do
    GenServer.call(graph, {:add_node, attrs})
  end

  @doc """
  Adds a new edge to the `graph` between `node1` and `node2` with the provided `attrs`
  and a generated unique id.

  Returns the map containing the edge data

  ## Examples

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> node2 = Graphvix.add_node(graph, label: "End")
      iex> Graphvix.add_edge(graph, node1, node2)
      %{ id: 3, start_node: 1, end_node: 2, attrs: [] }


  You can also pass node ids instead of nodes as the 2nd and 3rd parameters.

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> node2 = Graphvix.add_node(graph, label: "End")
      iex> Graphvix.add_edge(graph, node1.id, node2.id)
      %{ id: 3, start_node: 1, end_node: 2, attrs: [] }

  """
  def add_edge(graph, n1, n2, attrs \\ [])
  def add_edge(graph, %{id: id}, n2, attrs) do
    add_edge(graph, id, n2, attrs)
  end
  def add_edge(graph, n1, %{id: id}, attrs) do
    add_edge(graph, n1, id, attrs)
  end
  def add_edge(graph, n1_id, n2_id, attrs) do
    GenServer.call(graph, {:add_edge, n1_id, n2_id, attrs})
  end

  @doc """
  Creates a new cluster with the listed nodes.

  ## Examples

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> node2 = Graphvix.add_node(graph, label: "End")
      iex> cluster = Graphvix.add_cluster(graph, [node1, node2])

  You can also pass node ids instead of nodes

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> node2 = Graphvix.add_node(graph, label: "End")
      iex> cluster = Graphvix.add_cluster(graph, [node1.id, node2.id])

  """
  def add_cluster(graph, nodes \\ []) do
    GenServer.call(graph, {:add_cluster, extract_ids(nodes)})
  end

  @doc """
  Add one or more nodes to the `cluster` in the `graph`.

  The third argument can be a single node id or a list of node ids.

  ## Examples

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> node2 = Graphvix.add_node(graph, label: "End")
      iex> node3 = Graphvix.add_node(graph, label: "Epilogue")
      iex> cluster = Graphvix.add_cluster(graph, [node1, node2])
      iex> Graphvix.add_to_cluster(graph, cluster.id, node3.id)

  """
  def add_to_cluster(graph, cluster_id, node_ids) when is_list(node_ids) do
    GenServer.call(graph, {:add_to_cluster, cluster_id, extract_ids(node_ids)})
  end
  def add_to_cluster(graph, cluster_id, node_id) do
    add_to_cluster(graph, cluster_id, [node_id])
  end

  @doc """
  Remove one or more nodes from the `cluster` in the `graph`.

  The third argument can be a single node id or a list of node ids.

  ## Examples

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> node2 = Graphvix.add_node(graph, label: "End")
      iex> node3 = Graphvix.add_node(graph, label: "Epilogue")
      iex> cluster = Graphvix.add_cluster(graph, [node1, node2, node3])
      iex> Graphvix.remove_from_cluster(graph, cluster.id, [node1.id, node3.id])

  """
  def remove_from_cluster(graph, cluster_id, node_ids) when is_list(node_ids) do
    GenServer.call(graph, {:remove_from_cluster, cluster_id, extract_ids(node_ids)})
  end
  def remove_from_cluster(graph, cluster_id, node_id) do
    remove_from_cluster(graph, cluster_id, [node_id])
  end

  @doc """
  Returns the node or edge in the `graph` with the provided `id`.

  ## Examples

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> Graphvix.find(graph, node1.id) == node1
      true

  Returns nil if no node or edge is found.

      iex> graph = Graphvix.new
      iex> Graphvix.find(graph, 3)
      nil

  """
  def find(graph, id) do
    GenServer.call(graph, {:find, id})
  end

  @doc """
  Updates the attributes for the node or edge in the `graph` with the provided `id`.

  ## Examples

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> Graphvix.update(graph, node1.id, color: "blue")
      iex> Graphvix.find(graph, node1.id)
      %{ id: 1, attrs: [label: "Start", color: "blue"] }

  """
  def update(graph, id, attrs) do
    GenServer.cast(graph, {:update, id, attrs})
  end

  @doc """
  Removes the node, edge, or cluster with the provided `id` from the graph

      iex> graph = Graphvix.new
      iex> node1 = Graphvix.add_node(graph, label: "Start")
      iex> Graphvix.remove(graph, node1.id)

  """
  def remove(graph, id) do
    GenServer.cast(graph, {:remove, id})
  end

  @doc """
  Returns a string representation in .dot format of the graph.

  ## Examples

      iex> graph = Graphvix.new
      iex> ...
      iex> ...
      iex> Graphvix.write(graph)
      "digraph G { ... }"

  """
  def write(graph) do
    get(graph) |> Writer.write
  end

  @doc """
  Saves the graph to a DOT file with the provided `filename` ("G" by default).

  ## Examples

      iex> graph = Graphvix.new
      iex> ...
      iex> ...
      iex> Graphvix.save(graph)
      :ok

  After running this, `G.dot` will exist in your working directory.

  """
  def save(graph, filename \\ "G") do
    write(graph) |> Writer.save(filename)
  end

  @doc """
  Saves the graph and compiles to the provided filetype.

  ## Examples

      iex> graph = Graphvix.new
      iex> ...
      iex> ...
      iex> Graphvix.compile(graph)

  """
  def compile(graph, filetype) when is_atom(filetype) do
    compile(graph, "G", filetype)
  end
  @doc """
  Saves the graph and compiles to the provided filename and filetype.

  Defaults are `G.dot` and `:pdf`

  ## Examples

      iex> graph = Graphvix.new
      iex> ...
      iex> ...
      iex> Graphvix.compile(graph)

  """
  def compile(graph, filename \\ "G", filetype \\ :pdf) do
    write(graph) |> Writer.save(filename) |> Writer.compile(filetype)
  end

  @doc """
  Save the graph to a DOT file, compile it to PDF, and open the PDF file.

  ## Examples

      iex> graph = Graphvix.new
      iex> ...
      iex> ...
      iex> Graphvix.graph(graph)
      :ok

  After running this, `G.dot` and `G.pdf` will exist in your working directory,
  and `G.pdf` will open in your preferred PDF viewer.

  """
  def graph(graph, filetype) when is_atom(filetype) do
    graph(graph, "G", filetype)
  end
  def graph(graph, filename \\ "G", filetype \\ :pdf) do
    write(graph) |> Writer.save(filename) |> Writer.compile(filetype) |> Writer.open
  end

  ## PRIVATE ##

  defp extract_ids([]), do: []
  defp extract_ids([%{id: id}|nodes]) do
    [id|extract_ids(nodes)]
  end
  defp extract_ids([id|nodes]) do
    [id|extract_ids(nodes)]
  end
end
