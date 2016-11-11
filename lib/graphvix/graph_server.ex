defmodule Graphvix.GraphServer do
  use GenServer

  def start_link(state_pid) do
    GenServer.start_link(__MODULE__, {state_pid, nil}, name: __MODULE__)
  end

  ## API

  def ls do
    GenServer.call(__MODULE__, :ls)
  end

  def new(name) do
    GenServer.cast(__MODULE__, {:new, name})
  end

  def switch(name) do
    GenServer.cast(__MODULE__, {:switch, name})
  end

  def current_graph do
    GenServer.call(__MODULE__, :current_graph)
  end

  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  ## CALLBACKS

  def init({state_pid, _}) do
    new_state = {state_pid, Graphvix.State.current_graph(state_pid)}
    {:ok, new_state}
  end

  def handle_call(:current_graph, _from, state={_, graph}) do
    {:reply, graph, state}
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
    {:noreply, {state_pid, nil}}
  end
  def handle_cast({:switch, name}, {state_pid, {current_name, current_graph}}) do
    Graphvix.State.save(state_pid, current_name, current_graph)
    new_graph = Graphvix.State.load(state_pid, name)
    {:noreply, {state_pid, new_graph}}
  end

  def terminate(_reason, {state_pid, {current_name, current_graph}}) do
    Graphvix.State.save(state_pid, current_name, current_graph)
  end

  defp get_id do
    Graphvix.IdAgent.next
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

  defp update_attrs_for_element_in_graph(graph, id, element, key, attrs) do
    new_attrs = merge_without_nils(element.attrs, attrs)
    new_element = %{ element | attrs: new_attrs }
    %{ graph | key => %{ Map.get(graph, key) | id => new_element } }
  end

  defp merge_without_nils(original, changes) do
    original
    |> Keyword.merge(changes)
    |> reject_nils
  end

  defp reject_nils(coll) do
    Enum.reject(coll, fn {_, v} -> is_nil(v) end)
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

  defp update_graph_with_element_removed(graph, key, id) do
    with with_removed <- remove_from_map!(Map.get(graph, key), id) do
      %{ graph | key => with_removed }
    end
  end

  defp remove_edges_attached_to_node(graph, node_id) do
    new_edges = graph.edges
                |> Enum.reject(&edge_connects_to_node?(&1, node_id))
                |> Enum.into(Map.new)
    %{ graph | edges: new_edges }
  end

  defp edge_connects_to_node?({_, %{ start_node: s_id, end_node: e_id }}, n_id) do
    s_id == n_id || e_id == n_id
  end

  def remove_node_from_clusters(graph, node_id) do
    new_clusters = Enum.map(graph.clusters, fn {id, cluster} ->
      {id, %{ cluster | node_ids: cluster.node_ids -- [node_id] }}
    end) |> Enum.into(Map.new)
   %{ graph | clusters: new_clusters }
  end

  defp remove_from_map!(map, id) do
    with {_, results} <- Map.pop(map, id) do
      results
    end
  end
end

