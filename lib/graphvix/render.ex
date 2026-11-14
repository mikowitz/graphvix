defmodule Graphvix.Render do
  @moduledoc false
  # DOT rendering for Graphvix.to_dot/1, write/2 and compile/3.
  # See contracts/graphvix/render.intent.md.

  alias Graphvix.{Cluster, Edge, Graph, HTMLRecord, Node, Record, Subgraph}

  @compass_points [:n, :ne, :e, :se, :s, :sw, :w, :nw, :c, :_]

  @doc false
  def compass_points, do: @compass_points

  @spec to_dot(Graph.t()) :: String.t()
  def to_dot(%Graph{} = graph) do
    header = if graph.strict, do: "strict ", else: ""
    kind = if graph.digraph, do: "digraph", else: "graph"
    op = if graph.digraph, do: "->", else: "--"

    lines =
      ["#{header}#{kind} G {"] ++
        block(graph, 1) ++ Enum.map(graph.edges, &indent(edge(&1, op), 1)) ++ ["}"]

    Enum.join(lines, "\n") <> "\n"
  end

  # Statement order (render.I2): graph attributes, node default, edge default
  # (root only), subgraphs, clusters, the block's own nodes. Edges are added
  # by to_dot/1 for the root.
  defp block(container, level) do
    attributes = container.attributes

    graph_attrs =
      for {key, value} <- sorted(attributes.graph), do: indent("#{key}=#{value};", level)

    defaults =
      for target <- [:node, :edge],
          map = Map.get(attributes, target, %{}),
          list = attr_list(map),
          list != "",
          do: indent("#{target}#{list};", level)

    graph_attrs ++
      defaults ++
      Enum.flat_map(container.subgraphs, &subblock(&1, level)) ++
      Enum.flat_map(container.clusters, &subblock(&1, level)) ++
      Enum.map(container.nodes, &indent(node_statement(&1), level))
  end

  defp subblock(container, level) do
    [indent("subgraph #{quote_string(name(container))} {", level)] ++
      block(container, level + 1) ++ [indent("}", level)]
  end

  @doc false
  @spec name(Subgraph.t() | Cluster.t()) :: String.t()
  def name(%Subgraph{id: id}), do: id
  def name(%Cluster{id: id}), do: "cluster_" <> id

  defp node_statement(%Node{id: id, attributes: attributes}) do
    quote_string(id) <> attr_list(auto_shape(attributes)) <> ";"
  end

  # render.I10: a node's own record label sets its shape unless it sets one.
  defp auto_shape(%{"shape" => _} = attributes), do: attributes

  defp auto_shape(%{"label" => %Record{}} = attributes),
    do: Map.put(attributes, "shape", "record")

  defp auto_shape(%{"label" => %HTMLRecord{}} = attributes),
    do: Map.put(attributes, "shape", "plaintext")

  defp auto_shape(attributes), do: attributes

  defp edge(%Edge{from: from, to: to, attributes: attributes}, op) do
    "#{endpoint(from)} #{op} #{endpoint(to)}#{attr_list(attributes)};"
  end

  defp endpoint({id, nil, compass}), do: quote_string(id) <> compass(compass)
  defp endpoint({id, port, compass}), do: endpoint({id, port}) <> compass(compass)
  defp endpoint({id, port}), do: quote_string(id) <> ":" <> quote_string(port)
  defp endpoint(id), do: quote_string(id)

  defp compass(compass) when compass in @compass_points, do: ":#{compass}"
  defp compass(_invalid), do: ""

  defp attr_list(attributes) do
    case sorted(attributes) do
      [] -> ""
      pairs -> " [" <> Enum.map_join(pairs, ", ", fn {key, value} -> "#{key}=#{value}" end) <> "]"
    end
  end

  # Sorted {key, rendered value} pairs, dropping nil values (render.I5, I11).
  defp sorted(attributes) do
    attributes
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {key, value} -> {key, value(value)} end)
  end

  defp value(%HTMLRecord{} = html), do: "<" <> HTMLRecord.to_label(html) <> ">"
  defp value(%Record{} = record), do: quote_string(Record.to_label(record))
  defp value(value), do: value |> to_string() |> quote_string()

  # render.I6: a quote gets a backslash unless an odd run already precedes
  # it; an odd trailing run gains one; other backslashes are kept.
  defp quote_string(text) do
    escaped =
      Regex.replace(~r/(\\*)"/, text, fn _, run ->
        if rem(byte_size(run), 2) == 0, do: run <> ~S(\"), else: run <> ~S(")
      end)

    escaped =
      case Regex.run(~r/\\+\z/, escaped) do
        [run] when rem(byte_size(run), 2) == 1 -> escaped <> "\\"
        _ -> escaped
      end

    ~s("#{escaped}")
  end

  defp indent(line, level), do: String.duplicate("  ", level) <> line
end
