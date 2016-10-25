defmodule Graphvix.Edge do
  @type node_or_id :: map | pos_integer
  @type edge_or_id :: map | pos_integer

  @doc """
  Adds an edge to the graph connecting `node1` and `node2`.

  The edge sets its starting attributes to `attrs`.

  Edges can be created by passing node ids or nodes themselves.

      iex> n1 = Node.new
      iex> n2 = Node.new
      iex> n3 = Node.new
      iex> Edge.new(n1.id, n2.id) # or
      iex> Edge.new(n2, n3)

  """
  @spec new(node_or_id, node_or_id, Keyword.t | nil) :: map
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

      iex> e = Edge.new(n1, n2, color: "blue")
      iex> Edge.update(e.id, color: nil, label: "Connection")

  An edge can be passed in place of its id for ease of use.

      iex> Edge.update(e, color: nil, label: "Connection")

  """
  @spec update(edge_or_id, Keyword.t) :: :ok
  def update(%{id: id}=edge, attrs), do: update(id, attrs)
  def update(edge_id, attrs) do
    GenServer.cast(Graphvix.Graph, {:update, edge_id, attrs})
  end

  @doc """
  Deletes the edge with the provided `edge_id`.

  Does nothing if the edge does not exist.

      iex> e = Edge.new(n1, n2)
      iex> Edge.delete(e.id)

  An edge can be passed in place of its id for ease of use.

      iex> Edge.delete(e)

  """
  @spec delete(pos_integer) :: :ok
  def delete(edge_id) do
    GenServer.cast(Graphvix.Graph, {:remove, edge_id})
  end

  @doc """
  Find the edge in the graph that has the provided `edge_id`.

  Returns the edge, or `nil` if it is not found.

      iex> e = Edge.new(n1, n2)
      iex> Edge.find(e.id) #=> returns `e`

  """
  @spec find(pos_integer) :: map | nil
  def find(edge_id) do
    GenServer.call(Graphvix.Graph, {:find, edge_id})
  end
end
