defmodule Graphvix.Subgraph do
  @moduledoc """
  A subgraph: a named group of nodes, subgraphs and clusters with their own
  attributes. It is emitted with its id as its name. A plain subgraph does not
  draw a box; use it for attributes such as `rank: "same"`.

  Subgraphs are built inside-out and then added to their parent with
  `add_subgraph/2` or `add_cluster/2`; every function returns the
  receiving struct, so they chain with pipes. `attributes` holds `:graph`
  (the subgraph's own attributes) and `:node` (defaults for its nodes).
  Edges live only at the root of a graph, so a subgraph has none.
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

  @doc "Returns an empty subgraph with the given id."
  @spec new(Builder.id()) :: t()
  def new(id), do: %__MODULE__{id: Builder.id(id)}

  @doc """
  Adds a node to this subgraph. Re-adding an id merges attributes into the
  existing node and keeps its position.
  """
  @spec add_node(t(), Builder.id(), Builder.attrs()) :: t()
  def add_node(%__MODULE__{} = subgraph, id, attrs \\ []) do
    %{subgraph | nodes: Builder.put_node(subgraph.nodes, id, attrs)}
  end

  @doc "Nests a subgraph inside this subgraph."
  @spec add_subgraph(t(), Subgraph.t()) :: t()
  def add_subgraph(%__MODULE__{} = parent, %Subgraph{} = child) do
    %{parent | subgraphs: parent.subgraphs ++ [child]}
  end

  @doc "Nests a cluster inside this subgraph."
  @spec add_cluster(t(), Cluster.t()) :: t()
  def add_cluster(%__MODULE__{} = subgraph, %Cluster{} = cluster) do
    %{subgraph | clusters: subgraph.clusters ++ [cluster]}
  end

  @doc """
  Merges attributes into this subgraph's own attributes (`:graph`) or into
  the defaults for its nodes (`:node`).
  """
  @spec set_attributes(t(), :graph | :node, Builder.attrs()) :: t()
  def set_attributes(%__MODULE__{} = subgraph, target, attrs) when target in [:graph, :node] do
    %{subgraph | attributes: Map.update!(subgraph.attributes, target, &Builder.merge(&1, attrs))}
  end
end
