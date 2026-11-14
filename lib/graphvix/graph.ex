defmodule Graphvix.Graph do
  @moduledoc """
  A graph: whether it is directed and strict, its nodes, edges, subgraphs and
  clusters, and its attributes.

  `attributes` holds three maps: `:graph` for the graph's own attributes, and
  `:node` and `:edge` for the defaults applied to every node and edge.

  Build graphs with the functions in `Graphvix`.
  """

  defstruct digraph: true,
            strict: false,
            nodes: [],
            edges: [],
            subgraphs: [],
            clusters: [],
            attributes: %{graph: %{}, node: %{}, edge: %{}}

  @type t :: %__MODULE__{
          digraph: boolean(),
          strict: boolean(),
          nodes: [Graphvix.Node.t()],
          edges: [Graphvix.Edge.t()],
          subgraphs: [Graphvix.Subgraph.t()],
          clusters: [Graphvix.Cluster.t()],
          attributes: %{graph: map(), node: map(), edge: map()}
        }
end
