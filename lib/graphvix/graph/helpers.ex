defmodule Graphvix.Graph.Helpers do
  @moduledoc false

  def get_id do
    Graphvix.IdAgent.next
  end

  def clear_ids do
    Graphvix.IdAgent.clear
  end

  def find_element(graph, id) do
    Map.get(graph.nodes, id) || Map.get(graph.edges, id) || Map.get(graph.clusters, id)
  end
  def find_element(graph, id, type) do
    with type_plural <- :"#{type}s" do
      graph |> Map.get(type_plural) |> Map.get(id)
    end
  end

  def kind_of_element(graph, id) do
    graph |> find_element(id) |> kind_of
  end

  def kind_of(nil), do: nil
  def kind_of(%{node_ids: _}), do: :cluster
  def kind_of(%{start_node: _}), do: :edge
  def kind_of(_), do: :node

  def update_attrs_for_element_in_graph(graph, id, element, key, attrs) do
    new_attrs = merge_without_nils(element.attrs, attrs)
    new_element = %{ element | attrs: new_attrs }
    %{ graph | key => %{ Map.get(graph, key) | id => new_element } }
  end

  def merge_without_nils(original, changes) do
    original
    |> Keyword.merge(changes)
    |> reject_nils
  end

  def reject_nils(coll) do
    Enum.reject(coll, fn {_, v} -> is_nil(v) end)
  end

  def remove(:node, id, graph) do
    graph
    |> remove_edges_attached_to_node(id)
    |> remove_node_from_clusters(id)
    |> update_graph_with_element_removed(:nodes, id)
  end
  def remove(:edge, id, graph) do
    update_graph_with_element_removed(graph, :edges, id)
  end
  def remove(:cluster, id, graph) do
    update_graph_with_element_removed(graph, :clusters, id)
  end

  def update_graph_with_element_removed(graph, key, id) do
    with with_removed <- remove_from_map!(Map.get(graph, key), id) do
      %{ graph | key => with_removed }
    end
  end

  def remove_edges_attached_to_node(graph, node_id) do
    new_edges = graph.edges
                |> Enum.reject(&edge_connects_to_node?(&1, node_id))
                |> Enum.into(Map.new)
    %{ graph | edges: new_edges }
  end

  def edge_connects_to_node?({_, %{ start_node: s_id, end_node: e_id }}, n_id) do
    s_id == n_id || e_id == n_id
  end

  def remove_node_from_clusters(graph, node_id) do
    new_clusters = Enum.map(graph.clusters, fn {id, cluster} ->
      {id, %{ cluster | node_ids: cluster.node_ids -- [node_id] }}
    end) |> Enum.into(Map.new)
   %{ graph | clusters: new_clusters }
  end

  def remove_from_map!(map, id) do
    with {_, results} <- Map.pop(map, id) do
      results
    end
  end

  def handle_info(:save_state, state={state_pid, {name, graph}}) do
    Graphvix.State.save(state_pid, name, graph)
    schedule_save
    {:noreply, state}
  end

  def schedule_save do
    Process.send_after(self(), :save_state, 60_000)
  end
end
