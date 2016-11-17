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
  use Graphvix.Callbacks
  alias Graphvix.Writer

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

  @doc """
  Updates a graph-wide setting.
  """
  @spec update(Keyword.t) :: :ok
  def update(attrs) do
    GenServer.cast(__MODULE__, {:update, attrs})
  end

  @doc """
  Returns a string of the current graph in .dot format.
  """
  @spec write :: String.t
  def write do
    GenServer.call(__MODULE__, :write)
  end

  @doc """
  Returns the Elixir map form of the current graph.
  """
  @spec compile :: map
  def get do
    GenServer.call(__MODULE__, :get)
  end

  @doc """
  Writes the current graph to a .dot file and compiles it.

  Defaults to `pdf`.
  """
  @spec compile(atom | nil) :: :ok
  def compile(filetype \\ :pdf) do
    GenServer.cast(__MODULE__, {:compile, filetype})
  end

  @doc """
  Saves the current graph to a .dot file.
  """
  @spec save :: :ok
  def save do
    GenServer.cast(__MODULE__, :save)
  end

  @doc """
  Writes the current graph to a .dot file, compiles it, and opens the compiled graph.

  Defaults to `pdf`.
  """
  @spec graph(atom | nil) :: :ok
  def graph(filetype \\ :pdf) do
    GenServer.cast(__MODULE__, {:graph, filetype})
  end
end


