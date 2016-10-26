defmodule Graphvix.Edge do
  @moduledoc """
  `Graphvix.Edge` provides functions for adding, updating, and deleting edges in a graph.
  """

  @doc """
  Adds an edge to the graph.

  The edge connects the two nodes with ids matching the first two parameters,
  and sets its starting attributes to `attrs`.

      iex> {n1_id, n1} = Node.new
      iex> {n2_id, n2} = Node.new
      iex> Edge.new(n1_id, n2_id)
      {3, %{ start_node: 1, end_node: 2, attrs: [] }}

  """
  @spec new(pos_integer, pos_integer, Keyword.t | nil) :: {pos_integer, map}
  def new(node1, node2, attrs \\ [])
  def new(%{id: n1_id}, node2, attrs) do
    new(n1_id, node2, attrs)
  end
  def new(node1, %{id: n2_id}, attrs) do
    new(node1, n2_id, attrs)
  end
  def new(n1_id, n2_id, attrs) do
    GenServer.call(Graphvix.Graph, {:add_edge, n1_id, n2_id, attrs})
  end

  @doc """
  Updates the attributes for an edge with the provided `edge_id`.

  If `nil` is passed as a value in the `attrs` keyword list, it will remove
  the key entirely from the edge's attributes.

      iex> {e_id, e} = Edge.new(n1, n2, color: "blue")
      iex> Edge.update(e_id, color: nil, label: "Connection")

  """
  @spec update(pos_integer, Keyword.t) :: :ok
  def update(edge_id, attrs) do
    GenServer.cast(Graphvix.Graph, {:update, edge_id, attrs})
  end

  @doc """
  Deletes the edge with the provided `edge_id`.

  Does nothing if the edge does not exist.

      iex> {e_id, e} = Edge.new(n1, n2)
      iex> Edge.delete(e_id)

  """
  @spec delete(pos_integer) :: :ok
  def delete(edge_id) do
    GenServer.cast(Graphvix.Graph, {:remove, edge_id})
  end

  @doc """
  Find the edge in the graph that has the provided `edge_id`.

  Returns the edge, or `nil` if it is not found.

      iex> {e_id, e} = Edge.new(n1, n2)
      iex> Edge.find(e_id) #=> returns `e`

  """
  @spec find(pos_integer) :: map | nil
  def find(edge_id) do
    GenServer.call(Graphvix.Graph, {:find, edge_id})
  end
end
