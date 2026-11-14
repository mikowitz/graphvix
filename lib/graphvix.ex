defmodule Graphvix do
  @moduledoc """
  An Elixir interface to [Graphviz](https://graphviz.org/).

  Graphvix 2.0 models a graph as plain, immutable data. Every construction
  function returns a new graph, so graphs are built with pipes:

      Graphvix.new()
      |> Graphvix.set_attributes(:graph, rankdir: "LR")
      |> Graphvix.add_node("a", color: "red")
      |> Graphvix.add_node("b")

  Node ids may be strings, atoms or numbers; they are stored as strings, so
  `:a` and `"a"` name the same node. Attributes are keyword lists or maps, and
  their keys are stored as strings.
  """

  alias Graphvix.{Builder, Graph}

  @doc """
  Returns a new, empty graph.

  Options: `digraph:` (default `true`) and `strict:` (default `false`).
  """
  @spec new(keyword()) :: Graph.t()
  def new(opts \\ []) do
    %Graph{
      digraph: Keyword.get(opts, :digraph, true),
      strict: Keyword.get(opts, :strict, false)
    }
  end

  @doc """
  Adds a node to the root of the graph.

  Adding an id that is already at the root merges the attributes into the
  existing node, later values winning, and keeps its position.
  """
  @spec add_node(Graph.t(), Builder.id(), Builder.attrs()) :: Graph.t()
  def add_node(%Graph{} = graph, id, attrs \\ []) do
    %{graph | nodes: Builder.put_node(graph.nodes, id, attrs)}
  end

  @doc """
  Merges attributes into the graph's own attributes (`:graph`) or into the
  defaults for every node (`:node`) or edge (`:edge`).
  """
  @spec set_attributes(Graph.t(), :graph | :node | :edge, Builder.attrs()) :: Graph.t()
  def set_attributes(%Graph{} = graph, target, attrs) when target in [:graph, :node, :edge] do
    %{graph | attributes: Map.update!(graph.attributes, target, &Builder.merge(&1, attrs))}
  end
end
