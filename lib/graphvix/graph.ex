defmodule Graphvix.Graph do
  defstruct edges: [],
            nodes: [],
            digraph: true,
            strict: false,
            subgraphs: [],
            clusters: [],
            attributes: %{graph: %{}, node: %{}, edge: %{}}
end
