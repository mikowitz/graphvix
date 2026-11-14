defmodule Graphvix.Warnings do
  @moduledoc false
  # Graphvix.warnings/1. See contracts/graphvix/warnings.intent.md.
  #
  # The graph is flattened into its statements in render order
  # (graphvix.render.I2, I3). Each check returns {position, kind_rank,
  # warning} triples; sorting them gives the order warnings.I1 requires.

  alias Graphvix.{Attributes, Cluster, Graph, Record, Render, Subgraph}

  @rank %{
    unknown_attribute: 2,
    unsupported_attribute: 3,
    multiple_clusters: 4,
    nested_clusters: 5,
    duplicate_name: 8,
    unknown_port: 9,
    record_shape: 10,
    unknown_html_attribute: 11,
    conflicting_attribute: 12,
    record_label_misplaced: 13,
    invalid_compass_point: 14
  }

  @spec warnings(Graph.t()) :: [tuple()]
  def warnings(%Graph{} = graph) do
    statements =
      graph
      |> statements()
      |> Enum.with_index(fn statement, index -> Map.put(statement, :at, index) end)

    [&attribute_checks/1]
    |> Enum.flat_map(& &1.(statements))
    |> Enum.sort_by(fn {at, kind, _warning} -> {at, kind} end)
    |> Enum.map(&elem(&1, 2))
  end

  # -- statements in render order ---------------------------------------------

  defp statements(%Graph{} = graph) do
    root = %{names: [], blocks: [], newrank: graph.attributes.graph["newrank"] in [true, "true"]}

    block(graph, root, :graph) ++
      Enum.map(
        graph.edges,
        &%{type: :edge, edge: &1, target: {:edge, &1.from, &1.to}, attrs: &1.attributes}
      )
  end

  defp block(container, ctx, target) do
    attrs = container.attributes
    path = ctx.names

    [%{type: :attrs, letter: letter(container, target), target: target, attrs: attrs.graph}] ++
      [%{type: :default, letter: :N, target: {:node_default, path}, attrs: attrs.node}] ++
      edge_default(container, path) ++
      Enum.flat_map(Enum.with_index(container.subgraphs), &child(&1, ctx)) ++
      Enum.flat_map(Enum.with_index(container.clusters), &child(&1, ctx)) ++
      Enum.map(
        container.nodes,
        &%{type: :node, node: &1, ctx: ctx, target: {:node, &1.id}, attrs: &1.attributes}
      )
  end

  defp edge_default(%Graph{attributes: %{edge: attrs}}, path),
    do: [%{type: :default, letter: :E, target: {:edge_default, path}, attrs: attrs}]

  defp edge_default(_block, _path), do: []

  defp child({container, index}, ctx) do
    name = Render.name(container)
    kind = block_kind(container)
    id = {container.__struct__, index}

    ctx = %{
      ctx
      | names: ctx.names ++ [name],
        blocks: ctx.blocks ++ [%{name: name, kind: kind, id: id}]
    }

    target =
      if match?(%Cluster{}, container), do: {:cluster, ctx.names}, else: {:subgraph, ctx.names}

    [%{type: :block, name: name, path: ctx.names} | block(container, ctx, target)]
  end

  # :cluster for clusters and subgraphs Graphviz treats as clusters
  # (warnings.I7), :rank for subgraphs that set rank, :plain otherwise.
  defp block_kind(%Cluster{}), do: :cluster

  defp block_kind(%Subgraph{id: id, attributes: %{graph: graph}}) do
    cond do
      id =~ ~r/^cluster/i or graph["cluster"] in [true, "true"] -> :cluster
      graph["rank"] not in [nil, ""] -> :rank
      true -> :plain
    end
  end

  defp letter(_graph, :graph), do: :G
  defp letter(%Cluster{}, _target), do: :C
  defp letter(subgraph, _target), do: if(block_kind(subgraph) == :cluster, do: :C, else: :S)

  # -- attribute checks (I2, I3, I13) -----------------------------------------

  defp attribute_checks(statements) do
    for %{attrs: attrs, target: target, at: at} = statement <- statements,
        letter = statement_letter(statement),
        {key, value} <- Enum.sort(attrs),
        value != nil,
        warning <- attribute_warnings(key, value, letter, target),
        do: {at, @rank[elem(warning, 0)], warning}
  end

  defp statement_letter(%{type: :node}), do: :N
  defp statement_letter(%{type: :edge}), do: :E
  defp statement_letter(%{letter: letter}), do: letter

  defp attribute_warnings(key, value, letter, target) do
    known =
      case Attributes.lookup(key) do
        :error ->
          [{:unknown_attribute, target, key}]

        {:ok, letters} ->
          if letter in letters, do: [], else: [{:unsupported_attribute, target, key}]
      end

    known ++ misplaced(key, value, target)
  end

  # I13: a Record only works as a node's own label.
  defp misplaced("label", %Record{}, {:node, _id}), do: []
  defp misplaced("label", %Record{}, target), do: [{:record_label_misplaced, target}]
  defp misplaced(_key, _value, _target), do: []
end
