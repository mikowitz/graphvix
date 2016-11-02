defmodule Graphvix.Callbacks do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      @empty_graph %{nodes: %{}, edges: %{}, clusters: %{}, attrs: []}

      # load
      def handle_cast({:load, new_graph}, _graph) do
        {:noreply, new_graph}
      end
      # reset
      def handle_cast(:reset, _graph) do
        {:noreply, @empty_graph}
      end
      # save as txt
      def handle_cast({:save, filename, :txt}, graph) do
        File.write(filename <> ".txt", inspect(graph))
        {:noreply, graph}
      end
      # save as dot
      def handle_cast({:save, filename, :dot}, graph) do
        File.write(filename <> ".dot", Graphvix.Writer.write(graph))
        {:noreply, graph}
      end
      # update element
      def handle_cast({:update, id, attrs}, graph) do
        new_graph = case kind_of_element(graph, id) do
          :node -> update_attrs_for_element_in_graph(graph, id, Map.get(graph.nodes, id), :nodes, attrs)
          :edge -> update_attrs_for_element_in_graph(graph, id, Map.get(graph.edges, id), :edges, attrs)
          _ -> graph
        end
        {:noreply, new_graph}
      end
      # update graph
      def handle_cast({:update, attrs}, graph) do
        new_graph = %{ graph | attrs: merge_without_nils(graph.attrs, attrs) }
        {:noreply, new_graph}
      end


      # find
      def handle_call({:find, id, type}, _from, graph) do
        res = find_element(graph, id, type)
        res = case find_element(graph, id, type) do
          nil -> {:error, {:enotfound, type}}
          element -> element
        end
        {:reply, res, graph}
      end
      # delete
      def handle_call({:delete, id, type}, _from, graph) do
        {res, new_graph} = case kind_of_element(graph, id) do
          ^type -> {:ok, remove(type, id, graph)}
          _ -> {{:error, {:enotfound, type}}, graph}
        end
        {:reply, res, new_graph}
      end
      # get
      def handle_call(:get, _from, graph) do
        {:reply, graph, graph}
      end
      # add node
      def handle_call({:add_node, attrs}, _from, graph) do
        id = get_id
        new_node = %{ attrs: attrs }
        new_nodes = Map.put(graph.nodes, id, new_node)
        {:reply, {id, new_node}, %{ graph | nodes: new_nodes }}
      end
      # add edge
      def handle_call({:add_edge, start_id, end_id, attrs}, _from, graph) do
        id = get_id
        new_edge = %{ start_node: start_id, end_node: end_id, attrs: attrs }
        new_edges = Map.put(graph.edges, id, new_edge)
        {:reply, {id, new_edge}, %{ graph | edges: new_edges }}
      end
      # add cluster
      def handle_call({:add_cluster, node_ids}, _from, graph) do
        id = get_id
        new_cluster = %{ node_ids: node_ids }
        new_clusters = Map.put(graph.clusters, id, new_cluster)
        {:reply, {id, new_cluster}, %{ graph | clusters: new_clusters }}
      end
      # add to cluster
      def handle_call({:add_to_cluster, cluster_id, node_ids}, _from, graph) do
        cluster = Map.get(graph.clusters, cluster_id)
        new_node_ids = (cluster.node_ids ++ node_ids) |> Enum.uniq
        new_cluster = %{ cluster | node_ids: new_node_ids }
        new_clusters = %{ graph.clusters | cluster_id => new_cluster }
        {:reply, new_cluster, %{ graph | clusters: new_clusters }}
      end
      # remove from cluster
      def handle_call({:remove_from_cluster, cluster_id, node_ids}, _from, graph) do
        cluster = Map.get(graph.clusters, cluster_id)
        new_node_ids = (cluster.node_ids -- node_ids) |> Enum.uniq
        new_cluster = %{ cluster | node_ids: new_node_ids }
        new_clusters = %{ graph.clusters | cluster_id => new_cluster }
        {:reply, new_cluster, %{ graph | clusters: new_clusters }}
      end

      ## PRIVATE

      defp update_attrs_for_element_in_graph(graph, id, element, key, attrs) do
        new_attrs = merge_without_nils(element.attrs, attrs)
        new_element = %{ element | attrs: new_attrs }
        %{ graph | key => %{ Map.get(graph, key) | id => new_element } }
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
        end) |> Enum.into(Map.new)
        %{ graph | edges: new_edges }
      end

      def remove_node_from_clusters(graph, node_id) do
        new_clusters = Enum.map(graph.clusters, fn {id, cluster} ->
          {id, %{ cluster | node_ids: cluster.node_ids -- [node_id] }}
        end) |> Enum.into(Map.new)
        %{ graph | clusters: new_clusters }
      end

      defp find_element(graph, id) do
        Map.get(graph.nodes, id) || Map.get(graph.edges, id) || Map.get(graph.clusters, id)
      end
      defp find_element(graph, id, type) do
        with type_plural <- :"#{type}s" do
          graph |> Map.get(type_plural) |> Map.get(id)
        end
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

      defp remove(:node, id, graph) do
        graph
        |> remove_edges_attached_to_node(id)
        |> remove_node_from_clusters(id)
        |> update_graph_with_element_removed(:nodes, id)
      end
      defp remove(:edge, id, graph) do
        update_graph_with_element_removed(graph, :edges, id)
      end
      defp remove(:cluster, id, graph) do
        update_graph_with_element_removed(graph, :clusters, id)
      end

      defp get_id do
        Graphvix.IdAgent.next
      end
    end
  end
end
