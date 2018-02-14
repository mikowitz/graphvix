defmodule Graphvix.Callbacks do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      alias Graphvix.Writer
      import Graphvix.Graph.Helpers

      ## CALLBACKS

      def init({state_pid, _}) do
        new_state = {state_pid, Graphvix.State.current_graph(state_pid)}
        schedule_save()
        {:ok, new_state}
      end

      def handle_call(:current_graph, _from, state={_, {name, _}}) do
        {:reply, name, state}
      end
      def handle_call(:ls, _from, state={state_pid, _}) do
        graph_names = Graphvix.State.ls(state_pid)
        {:reply, graph_names, state}
      end
      def handle_call({:add_node, attrs}, _from, state={state_pid, graph}) do
        case graph do
          nil ->
            {:reply, {:error, :enograph}, state}
          {name, graph} ->
            id = get_id
            new_node = %{ attrs: attrs }
            new_nodes = Map.put(graph.nodes, id, new_node)
            new_graph = %{ graph | nodes: new_nodes }
            {:reply, {id, new_node}, {state_pid, {name, new_graph}}}
        end
      end
      def handle_call({:add_edge, start_id, end_id, attrs}, _from, {state_pid, {name, graph}}) do
        id = get_id
        new_edge = %{ start_node: start_id, end_node: end_id, attrs: attrs }
        new_edges = Map.put(graph.edges, id, new_edge)
        new_graph = %{ graph | edges: new_edges }
        {:reply, {id, new_edge}, {state_pid, {name, new_graph}}}
      end
      def handle_call({:add_cluster, node_ids}, _from, {state_pid, {name, graph}}) do
        id = get_id
        new_cluster = %{ node_ids: node_ids }
        new_clusters = Map.put(graph.clusters, id, new_cluster)
        new_graph = %{ graph | clusters: new_clusters }
        {:reply, {id, new_cluster}, {state_pid, {name, new_graph}}}
      end
      def handle_call({:add_to_cluster, cluster_id, node_ids}, _from, {state_pid, {name, graph}}) do
        cluster = Map.get(graph.clusters, cluster_id)
        new_node_ids = (cluster.node_ids ++ node_ids) |> Enum.uniq
        new_cluster = %{ cluster | node_ids: new_node_ids }
        new_clusters = %{ graph.clusters | cluster_id => new_cluster }
        {:reply, new_cluster, {state_pid, {name, %{ graph | clusters: new_clusters }}}}
      end
      def handle_call({:remove_from_cluster, cluster_id, node_ids}, _from, {state_pid, {name, graph}}) do
        cluster = Map.get(graph.clusters, cluster_id)
        new_node_ids = (cluster.node_ids -- node_ids) |> Enum.uniq
        new_cluster = %{ cluster | node_ids: new_node_ids }
        new_clusters = %{ graph.clusters | cluster_id => new_cluster }
        {:reply, new_cluster, {state_pid, {name, %{ graph | clusters: new_clusters }}}}
      end
      def handle_call({:find, id, type}, _from, state={_, {_name, graph}}) do
        res = case find_element(graph, id, type) do
          nil -> {:error, {:enotfound, type}}
          element -> element
        end
        {:reply, res, state}
      end
      def handle_call({:delete, id, type}, _from, {state_pid, {name, graph}}) do
        {res, new_graph} = case kind_of_element(graph, id) do
          ^type -> {:ok, remove(type, id, graph)}
          _ -> {{:error, {:enotfound, type}}, graph}
        end
        {:reply, res, {state_pid, {name, new_graph}}}
      end
      def handle_call(:get, _from, {_, {_, graph}} = state) do
        {:reply, graph, state}
      end
      def handle_call(:write, _from, {_, {_, graph}} = state) do
        {:reply, Writer.write(graph), state}
      end

      def handle_cast({:update, type, id, attrs}, {state_pid, {name, graph}}) do
        new_graph = case find_element(graph, id, type) do
          nil -> graph
          _ ->
            case kind_of_element(graph, id) do
              :node -> update_attrs_for_element_in_graph(graph, id, Map.get(graph.nodes, id), :nodes, attrs)
              :edge -> update_attrs_for_element_in_graph(graph, id, Map.get(graph.edges, id), :edges, attrs)
              _ -> graph
            end
        end
        {:noreply, {state_pid, {name, new_graph}}}
      end
      def handle_cast({:new, name}, {state_pid, _}) do
        new_graph = Graphvix.State.new_graph(state_pid, name)
        {:noreply, {state_pid, new_graph}}
      end
      def handle_cast(:clear, {state_pid, _}) do
        Graphvix.State.clear(state_pid)
        clear_ids()
        {:noreply, {state_pid, nil}}
      end
      def handle_cast({:switch, name}, {state_pid, {current_name, current_graph}}) do
        Graphvix.State.save(state_pid, current_name, current_graph)
        new_graph = Graphvix.State.load(state_pid, name)
        {:noreply, {state_pid, new_graph}}
      end
      def handle_cast({:update, attrs}, {state_pid, {name, graph}}) do
        new_graph = %{ graph | attrs: merge_without_nils(graph.attrs, attrs) }
        {:noreply, {state_pid, {name, new_graph}}}
      end
      def handle_cast(:save, {_, {name, graph}} = state) do
        graph
        |> Writer.write
        |> Writer.save(to_string(name))
        {:noreply, state}
      end
      def handle_cast({:compile, filetype}, {_, {name, graph}} = state) do
        graph
        |> Writer.write
        |> Writer.save(to_string(name))
        |> Writer.compile(filetype)
        {:noreply, state}
      end
      def handle_cast({:graph, filetype}, {_, {name, graph}} = state) do
        graph
        |> Writer.write
        |> Writer.save(to_string(name))
        |> Writer.compile(filetype)
        |> Writer.open
        {:noreply, state}
      end

      def terminate(_reason, {state_pid, {current_name, current_graph}}) do
        Graphvix.State.save(state_pid, current_name, current_graph)
      end
    end
  end
end
