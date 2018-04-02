defmodule Graphvix.Graph do
  def new do
    :digraph.new()
  end

  def digraph_tables({:digraph, vtab, etab, ntab, _}) do
    [vtab, etab, ntab]
  end

  def add_vertex(graph, label, attributes \\ []) do
    next_id = get_and_increment_vertex_id(graph)
    attributes = Keyword.put(attributes, :label, label)
    vertex_id = [:"$v" | next_id]
    vid = :digraph.add_vertex(graph, vertex_id, attributes)
    {graph, vid}
  end

  def add_edge(graph, out_from, in_to, attributes \\ []) do
    eid = :digraph.add_edge(graph, out_from, in_to, attributes)
    {graph, eid}
  end

  def to_dot(graph) do
    [
      "digraph G {",
      nodes_to_dot(graph),
      edges_to_dot(graph),
      "}"
    ] |> Enum.reject(&is_nil/1) |> Enum.join("\n\n")
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

  defp elements_to_dot(table, formatting_func) do
    case :ets.tab2list(table) do
      [] -> nil
      elements ->
        elements
        |> Enum.sort_by(fn entry ->
          [[_ | id] | _] = Tuple.to_list(entry)
          id
        end)
        |> Enum.map(&formatting_func.(&1))
        |> Enum.join("\n")
    end
  end

  defp nodes_to_dot(graph) do
    [vtab, _, _] = digraph_tables(graph)
    elements_to_dot(vtab, fn {[_ | id], attributes} ->
      "  v#{id} #{attributes_to_dot(attributes)}"
    end)
  end

  defp edges_to_dot(graph) do
    [_, etab, _] = digraph_tables(graph)
    elements_to_dot(etab, fn {_, [:"$v" | v1], [:"$v" | v2], attributes} ->
      "  v#{v1} -> v#{v2} #{attributes_to_dot(attributes)}"
    end)
  end

  defp attributes_to_dot([]), do: nil
  defp attributes_to_dot(attributes) do
    [
      "[",
      Enum.map(attributes, fn {key, value} ->
        ~s(#{key}="#{value}")
      end) |> Enum.join(","),
      "]"
    ] |> Enum.join("")
  end

  def get_and_increment_vertex_id(graph) do
    [_, _, ntab] = digraph_tables(graph)
    [{:"$vid", next_id}] = :ets.lookup(ntab, :"$vid")
    true = :ets.delete(ntab, :"$vid")
    true = :ets.insert(ntab, {:"$vid", next_id + 1})
    next_id
  end
end
