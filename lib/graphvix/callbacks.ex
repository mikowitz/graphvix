defmodule Graphvix.Callbacks do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      def handle_cast({:update, id, attrs}, graph) do
        new_graph = case kind_of_element(graph, id) do
          :node -> update_attrs_for_element_in_graph(graph, Map.get(graph.nodes, id), :nodes, attrs)
          :edge -> update_attrs_for_element_in_graph(graph, Map.get(graph.edges, id), :edges, attrs)
          _ -> graph
        end
        {:noreply, new_graph}
      end

      def handle_cast({:remove, id}, graph) do
        new_graph = case kind_of_element(graph, id) do
          nil -> graph
          :cluster -> update_graph_with_element_removed(graph, :clusters, id)
          :edge -> update_graph_with_element_removed(graph, :edges, id)
          :node ->
            graph
            |> remove_edges_attached_to_node(id)
            |> update_graph_with_element_removed(:nodes, id)
        end
        {:noreply, new_graph}
      end

      def handle_call(:get, _from, graph) do
        {:reply, graph, graph}
      end

      def handle_call({:add_node, attrs}, _from, graph) do
        id = get_id
        new_node = %{id: id, attrs: attrs}
        new_nodes = Map.put(graph.nodes, id, new_node)
        {:reply, new_node, %{ graph | nodes: new_nodes }}
      end

      def handle_call({:add_edge, start_id, end_id, attrs}, _from, graph) do
        id = get_id
        new_edge = %{ id: id, start_node: start_id, end_node: end_id, attrs: attrs }
        new_edges = Map.put(graph.edges, id, new_edge)
        {:reply, new_edge, %{ graph | edges: new_edges }}
      end

      def handle_call({:add_cluster, node_ids}, _from, graph) do
        id = get_id
        new_cluster = %{ id: id, node_ids: node_ids }
        new_clusters = Map.put(graph.clusters, id, new_cluster)
        {:reply, new_cluster, %{ graph | clusters: new_clusters }}
      end

      def handle_call({:add_to_cluster, cluster_id, node_ids}, _from, graph) do
        cluster = Map.get(graph.clusters, cluster_id)
        new_node_ids = (cluster.node_ids ++ node_ids) |> Enum.uniq
        new_cluster = %{ cluster | node_ids: new_node_ids }
        new_clusters = %{ graph.clusters | cluster.id => new_cluster }
        {:reply, new_cluster, %{ graph | clusters: new_clusters }}
      end

      def handle_call({:remove_from_cluster, cluster_id, node_ids}, _from, graph) do
        cluster = Map.get(graph.clusters, cluster_id)
        new_node_ids = (cluster.node_ids -- node_ids) |> Enum.uniq
        new_cluster = %{ cluster | node_ids: new_node_ids }
        new_clusters = %{ graph.clusters | cluster.id => new_cluster }
        {:reply, new_cluster, %{ graph | clusters: new_clusters }}
      end

      def handle_call({:find, id}, _from, graph) do
        {:reply, find_element(graph, id), graph}
      end

      defp update_attrs_for_element_in_graph(graph, element, key, attrs) do
        new_attrs = merge_without_nils(element.attrs, attrs)
        new_element = %{ element | attrs: new_attrs }
        %{ graph | key => %{ Map.get(graph, key) | new_element.id => new_element } }
      end

      defp merge_without_nils(original, changes) do
        Keyword.merge(original, changes)
        |> Enum.reject(fn {_, v} -> is_nil(v) end)
      end

      defp update_graph_with_element_removed(graph, key, id) do
        with_removed = remove_from_map(Map.get(graph, key), id)
        %{ graph | key => with_removed }
      end

      defp remove_edges_attached_to_node(graph, node_id) do
        new_edges = Enum.reject(graph.edges, fn {_, %{start_node: s_id, end_node: e_id}} ->
          s_id == node_id || e_id == node_id
        end)
        %{ graph | edges: new_edges }
      end

      defp find_element(graph, id) do
        Map.get(graph.nodes, id) || Map.get(graph.edges, id) || Map.get(graph.clusters, id)
      end

      defp kind_of_element(graph, id) do
        graph |> find_element(id) |> kind_of
      end

      defp kind_of(nil), do: nil
      defp kind_of(%{node_ids: _}), do: :cluster
      defp kind_of(%{start_node: _}), do: :edge
      defp kind_of(_), do: :node

      defp remove_from_map(map, id) do
        {_, results} = Map.pop(map, id)
        results
      end

      defp get_id do
        Graphvix.IdAgent.next
      end
    end
  end
end
