defmodule Graphvix.Graph do
  @moduledoc """
  This module manages starting, restarting, saving, and presenting the state
  of a graph.

  NB. All examples below assume you have run

      iex> alias Graphvix.{Graph, Node, Edge, Cluster}

  To reduce user effort, the module keeps only a single graph in state
  at any given time. Graphs can be saved and reloaded to switch between working
  with several different graphs at a time.

      iex> Graph.start

      iex> ... # Add some data to the first graph

      iex> Graph.save(:txt, "graph1")

      iex> Graph.restart # Clear the current state of the graph process

      iex> ... # Add some data to the second graph

      iex> Graph.save(:txt, "graph2")

      iex> Graph.load("graph1.txt") # Sets the process state to the last state of the first graph

  Elements are added and removed from the graph using the `Node`, `Edge`,
  and `Cluster` modules.

      iex> node1 = Node.new(label: "Start", color: "blue")
      iex> node2 = Node.new(label: "End", color: "red")
      iex> edge1 = Edge.new(node1, node2, color: "green")
      iex> cluster1 = Cluster.new([node1, node2])

  Settings can be added to an element. Setting an attribute's value to `nil`
  will remove the attribute.

      iex> Node.update(node1.id, shape: "triangle")
      iex> Node.update(node2.id, color: nil) # Removes the key `color` from the node`s attributes keyword map

  A cluster's contents can be updated using `add` and `remove`

      iex> node3 = Node.new(label: "Something else")
      iex> Cluster.add(cluster1.id, node3)
      iex> Cluster.remove(cluster1.id, node1)

  In addition to saving the graph to a text file, it can be rendered in .dot
  format and saved

      iex> Graph.save(:dot) # Saves the current state of the graph as a .dot file

  These files can then be compiled to .pdf/.png/etc at the command line,
  or via additional helper functions on the `Graph` module

      iex> Graph.compile # Generates files "G.dot" and "G.pdf"
      iex> Graph.compile(:png) # Generates files "G.dot" and "G.png"
      iex> Graph.compile("my_graph") # Generates files "my_graph.dot" and "my_graph.pdf"
      iex> Graph.compile("my_graph", :png) # Generates files "my_graph.dot" and "my_graph.png"

  To immediately view the current state of a graph, there is `Graph.graph`

      iex> Graph.graph # Generates "G.dot" and "G.pdf", and opens "G.pdf" in your OS's default viewer
      iex> Graph.graph(:png) # Same as above, but generates and opens a .png file
      iex> Graph.graph("my_graph", :png) Same as above, but generates and opens files named "my_graph"

  """
  use GenServer
  use Graphvix.Callbacks
  alias Graphvix.Writer

  @empty_graph %{nodes: %{}, edges: %{}, clusters: %{}}

  @doc """
  Start up the graph state process with an empty graph.

      iex> Graph.start

  """
  @spec start :: :ok
  def start do
    GenServer.start_link(
      __MODULE__,
      @empty_graph,
      name: __MODULE__
    )
  end

  @doc """
  Resets the state of the graph state process

      iex> Graph.restart

  """
  @spec restart :: :ok
  def restart do
    case Process.whereis(__MODULE__) do
      nil -> start
      process ->
        case Process.alive?(process) do
          true -> GenServer.cast(__MODULE__, :reset)
          false -> start
        end
    end
  end

  @doc """
  Returns the current state of the graph as a map.

      iex> Graph.get
      %{
        nodes: %{ ... },
        edges: %{ ... },
        clusters: %{ ... }
      }

  """
  @spec get :: map
  def get do
    GenServer.call(__MODULE__, :get)
  end

  @doc """
  Return the node, edge, or cluster with the provided id

      iex> Graph.find(3)

  NB. Prefer `Graphvix.Node.find/1`, `Graphvix.Edge.find/1`, or `Graphvix.Cluster.find/1` when possible.

  """
  @spec find(pos_integer) :: map | nil
  def find(id) do
    GenServer.call(__MODULE__, {:find, id})
  end

  @doc """
  Remove the node, edge, or cluster with the provided id from the graph

      iex> Graph.remove(2)

  NB. Prefer `Graphvix.Node.delete/1`, `Graphvix.Edge.delete/1`, or `Graphvix.Cluster.delete/1` when possible.

  """
  @spec remove(pos_integer) :: :ok
  def remove(id) do
    GenServer.cast(__MODULE__, {:remove, id})
  end

  @doc """
  Load a graph state from a text file

      iex> Graph.load("my_graph.txt")

  NB. This reads and evals the provided file as a string. *Please* be sure
  you know what is in the file before loading it!

  """
  @spec load(String.t) :: :ok
  def load(filename) do
    with {:ok, graph_str} = File.read(filename) do
      {graph_map, _} = Code.eval_string(graph_str)
      GenServer.cast(__MODULE__, {:load, graph_map})
    end
  end

  @doc """
  Saves the file with the provided format and filename (defaults to "G")

  Saving as a .txt file saves the inspected Elixir format of the graph
  to a text file, for use with `Graphvix.Graph.load/1`.

      iex> Graph.save(:txt)

  Saving as a .dot file renders the current state of the graph into dot format,
  ready to be compiled to an output format at the command line

      iex> Graph.save(:dot, "my_graph")

  """
  @spec save(atom, String.t | nil) :: :ok
  def save(filetype, filename \\ "G") do
    GenServer.cast(__MODULE__, {:save, filename, filetype})
  end

  @doc """
  Convert the graph to .dot format and return the .dot string

      iex> Graph.write
      "digraph G {
        ...
      }"

  """
  @spec write :: String.t
  def write do
    get |> Writer.write
  end

  @doc """
  Saves the graph in .dot format and generates a viewable version of the graph
  in the output format provided

      iex> Graph.compile(:pdf) # Generates "G.dot" and "G.pdf"

  """
  @spec compile(atom) :: :ok
  def compile(filetype) when is_atom(filetype) do
    compile("G", filetype)
  end
  @doc """
  Saves the graph in .dot format and generates a viewable version of the graph
  in the output format provided, with the filename given

      iex> Graph.compile("my_graph") # Generates "my_graph.dot" and "my_graph.pdf"
      iex> Graph.compile("my_graph", :png) # Generates "my_graph.dot" and "my_graph.png"

  """
  @spec compile(String.t | nil, atom | nil) :: :ok
  def compile(filename \\ "G", filetype \\ :pdf) do
    write |> Writer.save(filename) |> Writer.compile(filetype)
  end

  @doc """
  Saves, compiles, and opens a viewable version of the graph.

  Accepts optional parameters for filename (defaults to "G") and filetype
  (defaults to :pdf), and opens a file of the provided filetype in your OS's
  default viewer.

      iex> Graph.graph # Creates "G.dot" and "G.pdf"; opens "G.pdf"
      iex> Graph.graph("my_graph")
      iex> Graph.graph("graph2", :png)

  """
  @spec graph(String.t | nil, atom | nil) :: :ok
  def graph(filename \\ "G", filetype \\ :pdf) do
    write |> Writer.save(filename) |> Writer.compile(filetype) |> Writer.open
  end
end
