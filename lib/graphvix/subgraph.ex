defmodule Graphvix.Subgraph do
  @moduledoc """
  [Internal] Models a subgraph or cluster for inclusion in a graph.

  The functions included in this module are for internal use only. See

  * `Graphvix.Graph.add_subgraph/3`
  * `Graphvix.Graph.add_cluster/3`

  for the public interface for creating and including subgraphs and clusters.
  """

  import Graphvix.DotHelpers

  defstruct [
    id: nil,
    vertex_ids: [],
    global_properties: [node: [], edge: []],
    subgraph_properties: [],
    is_cluster: false,
    subgraphs: []
  ]

  @doc false
  def new(id, vertex_ids, is_cluster \\ false, properties \\ [], subgraphs \\ []) do
    node_properties = Keyword.get(properties, :node, [])
    edge_properties = Keyword.get(properties, :edge, [])
    subgraph_properties = properties |> Keyword.delete(:node) |> Keyword.delete(:edge)
    %Graphvix.Subgraph{
      id: id_prefix(is_cluster) <> "#{id}",
      is_cluster: is_cluster,
      vertex_ids: vertex_ids,
      global_properties: [
        node: node_properties,
        edge: edge_properties
      ],
      subgraph_properties: subgraph_properties,
      subgraphs: []
    }
  end

  @doc false
  def to_dot(subgraph, graph, levels \\ 1) 
  def to_dot(subgraph, graph, levels) do
    [vtab, _, _] = Graphvix.Graph.digraph_tables(graph)
    vertices_from_graph = :ets.tab2list(vtab)
    [
      "subgraph #{subgraph.id} {",
      global_properties_to_dot(subgraph),
      subgraph_properties_to_dot(subgraph),
      subgraph_vertices_to_dot(subgraph.vertex_ids, vertices_from_graph),
      subgraph_edges_to_dot(subgraph, graph),
      Enum.reduce(subgraph.subgraphs, "" , fn sg, acc ->
        acc <> to_dot(sg, graph, levels + 1)
      end),
      "}"
    ] |> List.flatten
    |> compact()
    |> Enum.map(fn val -> indent(val,levels) end)
    |> Enum.join("\n\n")
  end

  @doc false
  def subgraph_edges_to_dot(subgraph, graph) do
    subgraph
    |> edges_with_both_vertices_in_subgraph(graph)
    |> sort_elements_by_id()
    |> elements_to_dot(fn {_, [:"$v" | v1], [:"$v" | v2], attributes} ->
      "v#{v1} -> v#{v2} #{attributes_to_dot(attributes)}" |> String.trim |> indent
    end)
  end

  @doc false
  def both_vertices_in_subgraph?(vertex_ids, vid1, vid2) do
    vid1 in vertex_ids && vid2 in vertex_ids
  end

  ## Private

  defp subgraph_vertices_to_dot(subgraph_vertex_ids, vertices_from_graph) do
    subgraph_vertex_ids
    |> vertices_in_this_subgraph(vertices_from_graph)
    |> sort_elements_by_id()
    |> elements_to_dot(fn {[_ | id] , attributes} ->
      [
        "v#{id}",
        attributes_to_dot(attributes)
      ] |> compact |> Enum.join(" ") |> indent
    end)
  end

  defp vertices_in_this_subgraph(subgraph_vertex_ids, vertices_from_graph) do
    vertices_from_graph
    |> Enum.filter(fn {vid, _attributes} -> vid in subgraph_vertex_ids end)
  end

  defp subgraph_properties_to_dot(%{subgraph_properties: properties}) do
    properties
    |> Enum.map(fn {key, value} ->
      indent(attribute_to_dot(key, value))
    end)
    |> compact()
    |> return_joined_list_or_nil()
  end

  defp edges_with_both_vertices_in_subgraph(%{vertex_ids: vertex_ids}, graph) do
    [_, etab, _] = Graphvix.Graph.digraph_tables(graph)
    edges = :ets.tab2list(etab)
    Enum.filter(edges, fn {_, vid1, vid2, _} ->
      both_vertices_in_subgraph?(vertex_ids, vid1, vid2)
    end)
  end

  defp id_prefix(_is_cluster = true), do: "cluster"
  defp id_prefix(_is_cluster = false), do: "subgraph"
end
