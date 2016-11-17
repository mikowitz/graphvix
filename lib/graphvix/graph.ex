defmodule Graphvix.Graph do
  @moduledoc """
  `Graphvix.Graph` manages saving, loading, and presenting the state
  of a graph.

  NB. All examples below assume you have run

      iex> alias Graphvix.{Graph, Node, Edge, Cluster}

  To reduce user effort, the module keeps only a single graph in state
  at any given time. Graphs can be saved and reloaded to switch between working
  with several different graphs at a time.

      iex> Graph.new(:first_graph)

      iex> ... # Add some data to the first graph

      iex> Graph.switch(:second_graph) # Creates a new graph and loads it, saving the old graph at the same time.

      iex> ... # Add some data to the second graph

      iex> Graph.switch(:first_graph) # Saves `:second_graph` and reloads `first_graph`

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

  @doc false
  def start_link(state_pid) do
    GenServer.start_link(__MODULE__, {state_pid, nil}, name: __MODULE__)
  end

  ## API

  @doc """
  Returns a list of graphs currently stored by Graphvix
  """
  @spec ls :: [atom]
  def ls do
    GenServer.call(__MODULE__, :ls)
  end

  @doc """
  Creates a new graph named `name` and sets it to the current graph
  """
  @spec new(atom) :: :ok
  def new(name) do
    GenServer.cast(__MODULE__, {:new, name})
  end

  @doc """
  Switches the current graph to the graph named `name`.

  Creates a new graph if it doesn't exist.
  """
  @spec switch(atom) :: :ok
  def switch(name) do
    GenServer.cast(__MODULE__, {:switch, name})
  end

  @doc """
  Returns a tuple of the current graph's name and contents
  """
  @spec current_graph :: {atom, map}
  def current_graph do
    GenServer.call(__MODULE__, :current_graph)
  end

  @doc """
  Empties the stored state of Graphvix.

  Caution: Will delete all stored data from disk.
  """
  @spec clear :: :ok
  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

end

