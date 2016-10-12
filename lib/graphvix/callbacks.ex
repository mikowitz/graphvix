defmodule Graphvix.Callbacks do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      def handle_cast({:update, id, attrs}, graph) do
        new_graph = case Map.get(graph.nodes, id) do
          nil ->
            case Map.get(graph.edges, id) do
              nil -> graph
              edge -> update_attrs_for_element_in_graph(graph, edge, :edges, attrs)
            end
            node -> update_attrs_for_element_in_graph(graph, node, :nodes, attrs)
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

      def handle_call({:find, id}, _from, graph) do
        result = Map.get(graph.nodes, id) || Map.get(graph.edges, id)
        {:reply, result, graph}
      end

      def handle_call(:next, _from, id) do
        {:reply, id, id + 1}
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

      defp get_id do
        id_agent = case Agent.start(fn -> 1 end, name: :id_agent) do
          {:ok, agent} -> agent
          {:error, {:already_started, agent}} -> agent
        end
        Agent.get_and_update(id_agent, fn n -> {n, n+1} end)
      end
    end
  end
end
