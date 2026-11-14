defmodule Graphvix.Warnings do
  @moduledoc false
  # Graphvix.warnings/1. See contracts/graphvix/warnings.intent.md.
  #
  # The graph is flattened into its statements in render order
  # (graphvix.render.I2, I3). Each check returns {position, kind_index,
  # warning} triples; sorting them gives the order warnings.I1 requires.

  alias Graphvix.{Attributes, Cluster, Graph, HTMLRecord, Record, Render, Subgraph}

  # The order of the kinds when several warnings concern one statement.
  @kinds [
    :unknown_attribute,
    :unsupported_attribute,
    :multiple_clusters,
    :nested_clusters,
    :duplicate_name,
    :unknown_port,
    :record_shape,
    :unknown_html_attribute,
    :conflicting_attribute,
    :record_label_misplaced,
    :invalid_compass_point
  ]

  @spec warnings(Graph.t()) :: [tuple()]
  def warnings(%Graph{} = graph) do
    statements =
      graph
      |> statements()
      |> Enum.with_index(fn statement, index -> Map.put(statement, :at, index) end)

    [
      &attribute_checks/1,
      &placement_checks/1,
      &duplicate_names/1,
      &node_checks/1,
      &edge_checks/1,
      &conflicts/1
    ]
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
        blocks: ctx.blocks ++ [%{kind: kind, id: id}]
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
        do: warn(at, warning)
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
  # -- placement (I4-I7) -------------------------------------------------------

  defp placement_checks(statements) do
    statements
    |> Enum.filter(&(&1.type == :node))
    |> Enum.group_by(& &1.node.id)
    |> Enum.flat_map(fn {id, [first | _] = occurrences} ->
      occurrences
      |> Enum.map(&{occurrence_cluster(&1.ctx), &1})
      |> Enum.reject(&(elem(&1, 0) == :skip))
      |> placement_warnings(id)
      |> Enum.map(&warn(first.at, &1))
    end)
  end

  # An occurrence's cluster as a list of block ids from the root ([] = root),
  # tagged :rank when a rank subgraph on its path decides it.
  defp occurrence_cluster(%{blocks: blocks, newrank: newrank}) do
    if not newrank and Enum.any?(blocks, &(&1.kind == :rank)) do
      {:rank,
       blocks |> Enum.take_while(&(&1.kind != :rank)) |> innermost_cluster() |> Kernel.||([])}
    else
      case innermost_cluster(blocks) do
        nil -> :skip
        cluster -> {:cluster, cluster}
      end
    end
  end

  defp innermost_cluster(blocks) do
    case blocks
         |> Enum.with_index()
         |> Enum.filter(fn {block, _} -> block.kind == :cluster end) do
      [] -> nil
      found -> blocks |> Enum.take(elem(List.last(found), 1) + 1) |> Enum.map(& &1.id)
    end
  end

  defp placement_warnings([], _id), do: []

  defp placement_warnings(occurrences, id) do
    {placement, setter} = place(occurrences)
    path = fn {_, occurrence} -> occurrence.ctx.names end
    cluster = fn {{_, c}, _} -> c end

    ignored = Enum.reject(occurrences, &List.starts_with?(placement, cluster.(&1)))

    nested =
      Enum.filter(
        occurrences,
        &(cluster.(&1) != placement and List.starts_with?(placement, cluster.(&1)))
      )

    multiple =
      if ignored == [],
        do: [],
        else: [{:multiple_clusters, id, kept: path.(setter), ignored: Enum.map(ignored, path)}]

    nest =
      if nested == [],
        do: [],
        else: [{:nested_clusters, id, placed: path.(setter), also: Enum.map(nested, path)}]

    multiple ++ nest
  end

  # warnings.I4's walk. Returns {placement, the occurrence that set it}.
  defp place(occurrences) do
    Enum.reduce_while(occurrences, {nil, nil, nil}, fn
      {{:rank, []}, _} = occurrence, _state ->
        {:halt, {[], occurrence, nil}}

      {{kind, c}, _} = occurrence, {nil, _, _} ->
        {:cont, {c, occurrence, kind == :rank}}

      {{kind, c}, _} = occurrence, {placement, setter, pinned} ->
        cond do
          kind == :rank and List.starts_with?(placement, c) -> {:cont, {c, occurrence, true}}
          not pinned and descendant?(c, placement) -> {:cont, {c, occurrence, kind == :rank}}
          true -> {:cont, {placement, setter, pinned}}
        end
    end)
    |> then(fn {placement, setter, _pinned} -> {placement, setter} end)
  end

  defp descendant?(c, placement), do: c != placement and List.starts_with?(c, placement)
  # -- duplicate names (I8) ----------------------------------------------------

  defp duplicate_names(statements) do
    statements
    |> Enum.filter(&(&1.type == :block))
    |> Enum.group_by(& &1.name)
    |> Enum.filter(fn {_name, blocks} -> length(blocks) > 1 end)
    |> Enum.map(fn {name, [first | _] = blocks} ->
      warn(first.at, {:duplicate_name, name, Enum.map(blocks, & &1.path)})
    end)
  end

  # -- node labels (I10, I11) --------------------------------------------------

  defp node_checks(statements) do
    for %{node: node, at: at} <- statements,
        warning <- record_shape(node) ++ html_attributes(node),
        do: warn(at, warning)
  end

  defp record_shape(%{id: id, attributes: %{"label" => %Record{}, "shape" => shape}})
       when shape not in [nil, "record", "Mrecord", :record, :Mrecord],
       do: [{:record_shape, id, shape}]

  defp record_shape(_node), do: []

  defp html_attributes(%{id: id, attributes: %{"label" => %HTMLRecord{} = label}}) do
    for {element, attrs} <- HTMLRecord.elements(label),
        {key, _value} <- attrs,
        key = key |> to_string() |> String.replace("_", "-"),
        key not in HTMLRecord.allowed_attributes(element),
        do: {:unknown_html_attribute, id, element, key}
  end

  defp html_attributes(_node), do: []

  # -- edge endpoints (I9, I14) ------------------------------------------------

  defp edge_checks(statements) do
    ports =
      for %{node: %{id: id, attributes: %{"label" => %module{} = label}}} <-
            statements,
          module in [Record, HTMLRecord],
          port <- module.ports(label),
          reduce: %{},
          do: (acc -> Map.update(acc, id, MapSet.new([port]), &MapSet.put(&1, port)))

    for %{edge: edge, at: at} <- statements,
        warning <- endpoint_warnings(edge, ports),
        do: warn(at, warning)
  end

  defp endpoint_warnings(%{from: from, to: to}, ports) do
    endpoints = [from, to]

    unknown_ports =
      for endpoint <- endpoints,
          {id, port} <- port_of(endpoint),
          not MapSet.member?(Map.get(ports, id, MapSet.new()), port),
          do: {:unknown_port, {from, to}, id, port}

    bad_compass =
      for {id, _port, compass} <- endpoints,
          compass not in Render.compass_points(),
          do: {:invalid_compass_point, {from, to}, id, compass}

    unknown_ports ++ bad_compass
  end

  defp port_of({_id, nil, _compass}), do: []
  defp port_of({id, port, _compass}), do: [{id, port}]
  defp port_of({id, port}), do: [{id, port}]
  defp port_of(_id), do: []

  # -- conflicting values (I12) ------------------------------------------------

  defp conflicts(statements) do
    statements
    |> Enum.filter(&(&1.type == :node))
    |> Enum.group_by(& &1.node.id)
    |> Enum.flat_map(fn {id, [first | _] = occurrences} ->
      occurrences
      |> Enum.flat_map(&Map.keys(&1.node.attributes))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.flat_map(&conflict(id, &1, occurrences))
      |> Enum.map(&warn(first.at, &1))
    end)
  end

  defp conflict(id, key, occurrences) do
    values =
      for %{node: %{attributes: %{^key => value}}, ctx: ctx} <- occurrences,
          value != nil,
          do: {ctx.names, value}

    if values |> Enum.map(&elem(&1, 1)) |> Enum.uniq() |> length() > 1 do
      {others, [winner]} = Enum.split(values, -1)
      [{:conflicting_attribute, id, key, winner: winner, others: others}]
    else
      []
    end
  end

  defp warn(at, warning), do: {at, Enum.find_index(@kinds, &(&1 == elem(warning, 0))), warning}
end
