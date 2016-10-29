defmodule Graphvix.Cluster do
  @moduledoc """
  `Graphvix.Cluster` provides functions for adding, updating, and deleting clusters in a graph.
  """

  @type node_id_or_ids :: pos_integer | [pos_integer]

  @doc """
  Create a new cluster.

  The cluster is empty by default, but can be provided with `nodes`
  already part of it.

      iex> {n_id, n} = Node.new
      iex> {n2_id, n2} = Node.new

      # Passing no node ids
      iex> Cluster.new
      {3, %{ node_ids: [] }

      # Passing a single node id
      iex> Cluster.new(n_id)
      {3, %{ node_ids: [1] }

      # Passing multiple node ids
      iex> Cluster.new([n_id, n2_id])
      {3, %{ node_ids: [1, 2] }

  """
  @spec new(node_id_or_ids | nil) :: {pos_integer, map}
  def new(nodes \\ []) do
    GenServer.call(Graphvix.Graph, {:add_cluster, extract_ids(nodes)})
  end

  @doc """
  Adds a node or nodes to an existing cluster.

      iex> {c_id, c} = Cluster.new
      iex> {n_id, n} = Node.new
      iex> {n2_id, n2} = Node.new

      # Adding a single node
      iex> Cluster.add(c_id, n_id)

      # Adding multiple nodes
      iex> Cluster.add(c_id, [n_id, n2_id])

  """
  @spec add(pos_integer, node_id_or_ids) :: map
  def add(cluster_id, nodes) do
    GenServer.call(Graphvix.Graph, {:add_to_cluster, cluster_id, extract_ids(nodes)})
  end

  @doc """
  Removes a node or nodes from an existing cluster.

      iex> {n_id, n} = Node.new
      iex> {n2_id, n2} = Node.new
      iex> {c_id, c} = Cluster.new([n_id, n2_id])

      # Removing a single node
      iex> Cluster.remove(c_id, n_id)

      # Removing multiple nodes
      iex> Cluster.remove(c_id, [n_id, n2_id])

  """
  @spec remove(pos_integer, node_id_or_ids) :: map
  def remove(cluster_id, nodes) do
    GenServer.call(Graphvix.Graph, {:remove_from_cluster, cluster_id, extract_ids(nodes)})
  end

  @doc """
  Deletes the cluster with the provided `cluster_id`.

      iex> {c_id, c} = Cluster.new
      iex> Cluster.delete(c_id)

  """
  @spec delete(pos_integer) :: :ok
  def delete(cluster_id) do
    GenServer.cast(Graphvix.Graph, {:remove, cluster_id})
  end

  @doc """
  Find the cluster in the graph that has the provided `cluster_id`.

  Returns the cluster, or `nil` if it is not found.

      iex> {c_id, c} = Cluster.new
      iex> Cluster.find(c_id) #=> returns `c`

  """
  @spec find(pos_integer) :: map | nil
  def find(cluster_id) do
    GenServer.call(Graphvix.Graph, {:find, cluster_id})
  end

  defp extract_ids([]), do: []
  defp extract_ids([id|nodes]) do
    [id|extract_ids(nodes)]
  end
  defp extract_ids(node) do
    extract_ids([node])
  end
end
