defmodule Graphvix.Graph do
  import Graphvix.DotHelpers

  alias Graphvix.Record

  defstruct [
    digraph: nil,
    global_properties: [node: [], edge: []],
    subgraphs: []
  ]

  def new do
    digraph = :digraph.new()
    [_, _, ntab] = digraph_tables(digraph)
    true = :ets.insert(ntab, {:"$sid", 0})
    %__MODULE__{
      digraph: digraph
    }
  end

  def digraph_tables(%__MODULE__{digraph: graph}), do: digraph_tables(graph)
  def digraph_tables({:digraph, vtab, etab, ntab, _}) do
    [vtab, etab, ntab]
  end

  def add_record(graph, record) do
    label = Record.to_label(record)
    attributes = Keyword.put(record.properties, :shape, "record")
    add_vertex(graph, label, attributes)
  end

  def add_vertex(graph, label, attributes \\ []) do
    next_id = get_and_increment_vertex_id(graph)
    attributes = Keyword.put(attributes, :label, label)
    vertex_id = [:"$v" | next_id]
    vid = :digraph.add_vertex(graph.digraph, vertex_id, attributes)
    {graph, vid}
  end

  def add_edge(graph, out_from, in_to, attributes \\ [])
  def add_edge(graph, {id = [:"$v" | _], port}, in_to, attributes) do
    add_edge(graph, id, in_to, Keyword.put(attributes, :outport, port))
  end
  def add_edge(graph, out_from, {id = [:"$v" | _], port}, attributes) do
    add_edge(graph, out_from, id, Keyword.put(attributes, :inport, port))
  end
  def add_edge(graph, out_from, in_to, attributes) do
    eid = :digraph.add_edge(graph.digraph, out_from, in_to, attributes)
    {graph, eid}
  end

  def add_subgraph(graph, vertex_ids, properties \\ []) do
    _add_subgraph(graph, vertex_ids, properties, false)
  end

  def add_cluster(graph, vertex_ids, properties \\ []) do
    _add_subgraph(graph, vertex_ids, properties, true)
  end


  def _add_subgraph(graph, vertex_ids, properties, is_cluster) do
    next_id = get_and_increment_subgraph_id(graph)
    subgraph = Graphvix.Subgraph.new(next_id, vertex_ids, is_cluster, properties)
    new_graph = %{ graph | subgraphs: graph.subgraphs ++ [subgraph]}
    {new_graph, subgraph.id}
  end

  def to_dot(graph) do
    [
      "digraph G {",
      global_properties_to_dot(graph),
      subgraphs_to_dot(graph),
      vertices_to_dot(graph),
      edges_to_dot(graph),
      "}"
    ] |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")

  end

  def write(graph, filename) do
    File.write(filename, to_dot(graph))
  end

  def show(graph, filename) do
    :ok = write(graph, filename <> ".dot")
    {_, 0} = System.cmd("dot", [
      "-T", "png", filename <> ".dot",
      "-o", filename <> ".png"
    ])
    {_, 0} = System.cmd("open", [filename <> ".png"])
  end

  def set_properties(graph, attr_for, attrs \\ []) do
    Enum.reduce(attrs, graph, fn {k, v}, g ->
      set_property(g, attr_for, [{k, v}])
    end)
  end

  def set_property(graph, attr_for, [{key, value}]) do
    properties = Keyword.get(graph.global_properties, attr_for)
    new_props = Keyword.put(properties, key, value)
    new_properties = Keyword.put(graph.global_properties, attr_for, new_props)
    %{ graph | global_properties: new_properties }
  end

  defp subgraphs_to_dot(graph) do
    case graph.subgraphs do
      [] -> nil
      subgraphs ->
        subgraphs
        |> Enum.map(&Graphvix.Subgraph.to_dot(&1, graph))
        |> Enum.join("\n\n")
    end
  end

  defp vertices_to_dot(graph) do
    [vtab, _, _] = digraph_tables(graph)
    elements_to_dot(vtab, fn {vid = [_ | id], attributes} ->
      case in_a_subgraph?(vid, graph) do
        true -> nil
        false ->
          [
            "v#{id}",
            attributes_to_dot(attributes)
          ] |> compact() |> Enum.join(" ") |> indent()
      end
    end)
  end

  defp edge_side_with_port(v_id, nil), do: "v#{v_id}"
  defp edge_side_with_port(v_id, port), do: "v#{v_id}:#{port}"

  defp edges_to_dot(graph) do
    [_, etab, _] = digraph_tables(graph)
    elements_to_dot(etab, fn edge = {_, [:"$v" | v1], [:"$v" | v2], attributes} ->
      case edge in edges_contained_in_subgraphs(graph) do
        true -> nil
        false ->
          v_out = edge_side_with_port(v1, Keyword.get(attributes, :outport))
          v_in = edge_side_with_port(v2, Keyword.get(attributes, :inport))
          attributes = attributes |> Keyword.delete(:outport) |> Keyword.delete(:inport)
          ["#{v_out} -> #{v_in}",
           attributes_to_dot(attributes)
          ] |> compact() |> Enum.join(" ") |> indent()
      end
    end)
  end

  def get_and_increment_vertex_id(graph) do
    [_, _, ntab] = digraph_tables(graph)
    [{:"$vid", next_id}] = :ets.lookup(ntab, :"$vid")
    true = :ets.delete(ntab, :"$vid")
    true = :ets.insert(ntab, {:"$vid", next_id + 1})
    next_id
  end

  def get_and_increment_subgraph_id(graph) do
    [_, _, ntab] = digraph_tables(graph)
    [{:"$sid", next_id}] = :ets.lookup(ntab, :"$sid")
    true = :ets.delete(ntab, :"$sid")
    true = :ets.insert(ntab, {:"$sid", next_id + 1})
    next_id
  end

  def in_a_subgraph?(vertex_id, graph) do
    vertex_id in vertex_ids_in_subgraphs(graph)
  end

  defp vertex_ids_in_subgraphs(%__MODULE__{subgraphs: subgraphs}) do
    Enum.reduce(subgraphs, [], fn c, acc ->
      acc ++ c.vertex_ids
    end)
  end

  def edges_contained_in_subgraphs(graph = %__MODULE__{subgraphs: subgraphs}) do
    [_, etab, _] = digraph_tables(graph)
    edges = :ets.tab2list(etab)
    Enum.filter(edges, fn {_, vid1, vid2, _} ->
      Enum.any?(subgraphs, fn subgraph ->
        Graphvix.Subgraph.both_vertices_in_subgraph?(subgraph.vertex_ids, vid1, vid2)
      end)
    end)
  end
end
