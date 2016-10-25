defmodule Graphvix.Cluster do
  @type node_or_nodes :: pos_integer | [pos_integer]
  @type cluster_or_id :: pos_integer | map

  @doc """
  Create a new cluster.

  The cluster is empty by default, but can be provided with `nodes`
  already part of it.

      iex> n = Node.new
      iex> n2 = Node.new
      iex> Cluster.new # or
      iex> Cluster.new(n) # or
      iex> Cluster.new([n, n2])

  """
  @spec new(node_or_nodes | nil) :: map
  def new(nodes \\ []) do
    GenServer.call(Graphvix.Graph, {:add_cluster, extract_ids(nodes)})
  end

  @doc """
  Adds a node or nodes to an existing cluster identified by `cluster_id`

      iex> c = Cluster.new
      iex> n = Node.new
      iex> Cluster.add(c.id, n)

  """
  @spec add(pos_integer, node_or_nodes) :: map
  def add(cluster_id, nodes) do
    GenServer.call(Graphvix.Graph, {:add_to_cluster, cluster_id, extract_ids(nodes)})
  end

  @doc """
  Removes a node or nodes from an existing cluster identified by `cluster_id`

  iex> n = Node.new
  iex> c = Cluster.new(n)
  iex> Cluster.remove(c.id, n)

  """
  @spec remove(pos_integer, node_or_nodes) :: map
  def remove(cluster_id, nodes) do
    GenServer.call(Graphvix.Graph, {:remove_from_cluster, cluster_id, extract_ids(nodes)})
  end

  @doc """
  Deletes the cluster with the provided `cluster_id`.

      iex> c = Cluster.new
      iex> Cluster.delete(c.id)

  A cluster can be passed in place of its id for ease of use.

      iex> Cluster.delete(c)

  """
  @spec delete(cluster_or_id) :: :ok
  def delete(%{id: id}=cluster), do: delete(id)
  def delete(cluster_id) do
    GenServer.cast(Graphvix.Graph, {:remove, cluster_id})
  end

  @doc """
  Find the cluster in the graph that has the provided `cluster_id`.

  Returns the cluster, or `nil` if it is not found.

  iex> c = Cluster.new
  iex> Cluster.find(c.id) #=> returns `c`

  """
  @spec find(pos_integer) :: map | nil
  def find(cluster_id) do
    GenServer.call(Graphvix.Graph, {:find, cluster_id})
  end

  defp extract_ids([]), do: []
  defp extract_ids([%{id: id}|nodes]) do
    [id|extract_ids(nodes)]
  end
  defp extract_ids([id|nodes]) do
    [id|extract_ids(nodes)]
  end
  defp extract_ids(node) do
    extract_ids([node])
  end
end
