defmodule GraphvixTest do
  use ExUnit.Case
  doctest Graphvix
  alias Graphvix.{Graph, Node, Edge, Cluster}

  setup do
    config = Application.get_all_env(:graphvix)
    {:ok, %{
      data_path: Keyword.get(config, :data_path)
      }}
  end

  test "basic usage", context do
    png_path = Path.join([context.data_path, "first_graph.png"])
    File.rm(png_path)

    Graph.new(:first_graph)
    Graph.switch(:second_graph)
    Graph.switch(:first_graph)

    {n_id, node} = Node.new(label: "Start", color: "blue")
    {n2_id, node2} = Node.new(label: "End", color: "red")
    {e_id, edge} = Edge.new(n_id, n2_id, color: "green")
    {c_id, cluster} = Cluster.new([n_id, n2_id])

    Node.update(n_id, shape: "triangle")
    Node.update(n2_id, color: nil)

    {n3_id, node3} = Node.new(label: "Something else")
    Cluster.add(c_id, n3_id)
    Cluster.remove(c_id, n_id)

    Graph.save()

    Graph.compile()
    Graph.compile(:png)

    # gross, but we need it b/c some callbacks are async
    :timer.sleep(500)

    assert File.exists?(png_path)

  end

end
