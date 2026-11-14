defmodule Graphvix.Cluster do
  @moduledoc """
  A cluster: a named group of nodes, subgraphs and clusters that Graphviz
  draws inside a box. It is emitted as `cluster_<id>`.

  Clusters are built inside-out and then added to their parent with
  `add_subgraph/2` or `add_cluster/2`; every function returns the
  receiving struct, so they chain with pipes. `attributes` holds `:graph`
  (the cluster's own attributes) and `:node` (defaults for its nodes).
  Edges live only at the root of a graph, so a cluster has none.
  """

  alias Graphvix.{Builder, Cluster, Subgraph}

  defstruct id: nil, nodes: [], subgraphs: [], clusters: [], attributes: %{graph: %{}, node: %{}}

  @type t :: %__MODULE__{
          id: String.t(),
          nodes: [Graphvix.Node.t()],
          subgraphs: [Subgraph.t()],
          clusters: [Cluster.t()],
          attributes: %{graph: map(), node: map()}
        }

  @doc "Returns an empty cluster with the given id."
  @spec new(Builder.id()) :: t()
  def new(id), do: %__MODULE__{id: Builder.id(id)}

  @doc """
  Adds a node to this cluster. Re-adding an id merges attributes into the
  existing node and keeps its position.
  """
  @spec add_node(t(), Builder.id(), Builder.attrs()) :: t()
  def add_node(%__MODULE__{} = cluster, id, attrs \\ []) do
    %{cluster | nodes: Builder.put_node(cluster.nodes, id, attrs)}
  end

  @doc "Nests a subgraph inside this cluster."
  @spec add_subgraph(t(), Subgraph.t()) :: t()
  def add_subgraph(%__MODULE__{} = cluster, %Subgraph{} = subgraph) do
    %{cluster | subgraphs: cluster.subgraphs ++ [subgraph]}
  end

  @doc "Nests a cluster inside this cluster."
  @spec add_cluster(t(), Cluster.t()) :: t()
  def add_cluster(%__MODULE__{} = parent, %Cluster{} = child) do
    %{parent | clusters: parent.clusters ++ [child]}
  end

  @doc """
  Merges attributes into this cluster's own attributes (`:graph`) or into
  the defaults for its nodes (`:node`).
  """
  @spec set_attributes(t(), :graph | :node, Builder.attrs()) :: t()
  def set_attributes(%__MODULE__{} = cluster, target, attrs) when target in [:graph, :node] do
    %{cluster | attributes: Map.update!(cluster.attributes, target, &Builder.merge(&1, attrs))}
  end
end
