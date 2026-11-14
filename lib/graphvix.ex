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

  alias Graphvix.{Builder, Cluster, Edge, Graph, Subgraph}

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
  Adds an edge between two endpoints.

  An endpoint is a node id, `{id, port}`, `{id, port, compass}` or
  `{id, nil, compass}`. Endpoints need not name nodes that were added;
  Graphviz creates them. Every call adds a separate edge, including repeats.
  """
  @spec add_edge(Graph.t(), term(), term(), Builder.attrs()) :: Graph.t()
  def add_edge(%Graph{} = graph, from, to, attrs \\ []) do
    %{graph | edges: graph.edges ++ [Edge.new(from, to, attrs)]}
  end

  @doc "Adds a subgraph, built with `Graphvix.Subgraph`, to the root of the graph."
  @spec add_subgraph(Graph.t(), Subgraph.t()) :: Graph.t()
  def add_subgraph(%Graph{} = graph, %Subgraph{} = subgraph) do
    %{graph | subgraphs: graph.subgraphs ++ [subgraph]}
  end

  @doc "Adds a cluster, built with `Graphvix.Cluster`, to the root of the graph."
  @spec add_cluster(Graph.t(), Cluster.t()) :: Graph.t()
  def add_cluster(%Graph{} = graph, %Cluster{} = cluster) do
    %{graph | clusters: graph.clusters ++ [cluster]}
  end

  @doc """
  Renders the graph as DOT text.

  Statements are emitted in a fixed order inside every block: attributes,
  `node`/`edge` defaults, subgraphs, clusters, the block's own nodes, then
  (at the root) edges; each kind in definition order. Ids, names, ports and
  values are quoted, and clusters are named `cluster_<id>`.
  """
  @spec to_dot(Graph.t()) :: String.t()
  defdelegate to_dot(graph), to: Graphvix.Render

  @doc """
  Writes the graph's DOT text to `basename <> ".dot"`.

  Returns `:ok`, or `{:error, reason}` when the file cannot be written.
  """
  @spec write(Graph.t(), Path.t()) :: :ok | {:error, File.posix()}
  defdelegate write(graph, basename), to: Graphvix.Render

  @doc """
  Writes `basename <> ".dot"` and runs Graphviz's `dot` on it to produce
  `basename <> "." <> format`.

  Returns `{:ok, output_path}`, or `{:error, reason}` when the file cannot be
  written, `dot` is not on `PATH` (`:dot_not_found`), or `dot` fails
  (`{:dot_failed, exit_status, message}`). Never raises.
  """
  @spec compile(Graph.t(), Path.t(), atom()) :: {:ok, Path.t()} | {:error, term()}
  def compile(graph, basename, format \\ :png),
    do: Graphvix.Render.compile(graph, basename, format)

  @doc """
  Returns the problems Graphviz would silently tolerate in this graph.

  Each warning is a tagged tuple, such as `{:unknown_attribute, target, key}`
  or `{:multiple_clusters, node_id, kept: path, ignored: [path]}`; see
  `contracts/graphvix/warnings.intent.md` for every kind. The list is in the
  order Graphviz reads the statements involved. `to_dot/1`, `write/2` and
  `compile/3` log each warning; this function never logs.
  """
  @spec warnings(Graph.t()) :: [tuple()]
  defdelegate warnings(graph), to: Graphvix.Warnings

  @doc """
  Merges attributes into the graph's own attributes (`:graph`) or into the
  defaults for every node (`:node`) or edge (`:edge`).
  """
  @spec set_attributes(Graph.t(), :graph | :node | :edge, Builder.attrs()) :: Graph.t()
  def set_attributes(%Graph{} = graph, target, attrs) when target in [:graph, :node, :edge] do
    %{graph | attributes: Map.update!(graph.attributes, target, &Builder.merge(&1, attrs))}
  end
end
