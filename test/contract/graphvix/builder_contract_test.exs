defmodule Graphvix.BuilderContractTest do
  use Covenant.Case, component: "graphvix.builder", async: true
  use ExUnitProperties

  alias Graphvix.{Cluster, Subgraph}

  defp ids(list), do: Enum.map(list, & &1.id)

  defp own_ets_tables do
    me = self()
    Enum.filter(:ets.all(), &(:ets.info(&1, :owner) == me))
  end

  # -- I1 -----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I1"
  test "new graph has documented defaults" do
    g = Graphvix.new()

    assert g.digraph == true
    assert g.strict == false
    assert g.nodes == []
    assert g.edges == []
    assert g.subgraphs == []
    assert g.clusters == []
    assert g.attributes == %{graph: %{}, node: %{}, edge: %{}}
  end

  @tag obligation: "graphvix.builder.I1"
  test "options override digraph and strict" do
    g = Graphvix.new(digraph: false, strict: true)

    assert g.digraph == false
    assert g.strict == true
  end

  # -- I2 -----------------------------------------------------------------------

  defp op_gen do
    id = member_of(["a", "b", "c", :a, :d, 1])

    attrs =
      list_of(tuple({member_of([:color, :shape, "color"]), string(:alphanumeric)}), max_length: 3)

    one_of([
      tuple({constant(:node), id, attrs}),
      tuple({constant(:edge), id, id, attrs}),
      tuple({constant(:attrs), member_of([:graph, :node, :edge]), attrs}),
      tuple({constant(:cluster), id, id}),
      tuple({constant(:subgraph), id, id})
    ])
  end

  defp apply_op(g, {:node, id, attrs}), do: Graphvix.add_node(g, id, attrs)
  defp apply_op(g, {:edge, a, b, attrs}), do: Graphvix.add_edge(g, a, b, attrs)
  defp apply_op(g, {:attrs, kind, attrs}), do: Graphvix.set_attributes(g, kind, attrs)

  defp apply_op(g, {:cluster, cid, nid}),
    do: Graphvix.add_cluster(g, cid |> Cluster.new() |> Cluster.add_node(nid))

  defp apply_op(g, {:subgraph, sid, nid}),
    do: Graphvix.add_subgraph(g, sid |> Subgraph.new() |> Subgraph.add_node(nid))

  @tag obligation: "graphvix.builder.I2"
  property "construction never changes its input" do
    tables_before = own_ets_tables()

    check all(ops <- list_of(op_gen(), max_length: 12)) do
      Enum.reduce(ops, Graphvix.new(), fn op, g ->
        snapshot = :erlang.term_to_binary(g)
        next = apply_op(g, op)

        assert :erlang.term_to_binary(g) == snapshot
        assert apply_op(g, op) == next
        next
      end)
    end

    assert own_ets_tables() == tables_before
  end

  @tag obligation: "graphvix.builder.I2"
  test "cluster builders never change their input" do
    c = Cluster.new("x")
    c2 = Cluster.add_node(c, "a")

    assert c.nodes == []
    assert ids(c2.nodes) == ["a"]
  end

  # -- I3 -----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I3"
  test "atom string and integer ids name the same node" do
    g =
      Graphvix.new()
      |> Graphvix.add_node(:a)
      |> Graphvix.add_node("a")
      |> Graphvix.add_node(1)
      |> Graphvix.add_node("1")

    assert ids(g.nodes) == ["a", "1"]
  end

  @tag obligation: "graphvix.builder.I3"
  test "subgraph and cluster ids are stored as strings" do
    assert Cluster.new(:x).id == "x"
    assert Subgraph.new(7).id == "7"

    assert ids(
             Cluster.new("x")
             |> Cluster.add_node(:a)
             |> Cluster.add_node("a")
             |> Map.get(:nodes)
           ) == ["a"]
  end

  # -- I4 -----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I4"
  test "re-adding a node merges and keeps first position" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", color: "red", style: "filled")
      |> Graphvix.add_node("b")
      |> Graphvix.add_node("a", shape: "box", color: "blue")

    assert ids(g.nodes) == ["a", "b"]
    [a, _b] = g.nodes
    assert a.attributes == %{"color" => "blue", "shape" => "box", "style" => "filled"}
  end

  @tag obligation: "graphvix.builder.I4"
  test "re-adding a node inside a cluster merges within the cluster" do
    c =
      Cluster.new("x")
      |> Cluster.add_node("a", color: "red")
      |> Cluster.add_node("b")
      |> Cluster.add_node("a", shape: "box")

    assert ids(c.nodes) == ["a", "b"]
    assert hd(c.nodes).attributes == %{"color" => "red", "shape" => "box"}
  end

  # -- I5 -----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I5"
  property "lists keep definition order" do
    check all(
            names <-
              uniq_list_of(string(:alphanumeric, min_length: 1), min_length: 1, max_length: 10)
          ) do
      g = Enum.reduce(names, Graphvix.new(), &Graphvix.add_node(&2, &1))
      g = Enum.reduce(names, g, &Graphvix.add_cluster(&2, Cluster.new(&1)))
      g = Enum.reduce(names, g, &Graphvix.add_subgraph(&2, Subgraph.new(&1)))
      g = Enum.reduce(names, g, &Graphvix.add_edge(&2, &1, "z"))

      assert ids(g.nodes) == names
      assert ids(g.clusters) == names
      assert ids(g.subgraphs) == names
      assert Enum.map(g.edges, & &1.from) == names
    end
  end

  # -- I6 -----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I6"
  test "edges normalize endpoints and allow repeats and undeclared nodes" do
    g =
      Graphvix.new()
      |> Graphvix.add_edge(:a, {"b", "p1"})
      |> Graphvix.add_edge("a", {:b, :p1, :ne})
      |> Graphvix.add_edge("a", {"b", nil, :sw})
      |> Graphvix.add_edge("a", {"b", "p1"})

    assert Enum.map(g.edges, &{&1.from, &1.to}) == [
             {"a", {"b", "p1"}},
             {"a", {"b", "p1", :ne}},
             {"a", {"b", nil, :sw}},
             {"a", {"b", "p1"}}
           ]

    assert g.nodes == []
    refute Map.has_key?(hd(g.edges), :label)
  end

  @tag obligation: "graphvix.builder.I6"
  test "an edge label is an ordinary attribute" do
    g = Graphvix.add_edge(Graphvix.new(), "a", "b", label: "x")

    assert hd(g.edges).attributes == %{"label" => "x"}
  end

  # -- I7 -----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I7"
  test "atom and string keys name the same attribute across keyword lists and maps" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", color: "red")
      |> Graphvix.add_node("a", %{"color" => "blue"})
      |> Graphvix.set_attributes(:node, shape: "box")
      |> Graphvix.set_attributes(:node, %{"shape" => "oval", fontsize: 10})

    assert hd(g.nodes).attributes == %{"color" => "blue"}
    assert g.attributes.node == %{"shape" => "oval", "fontsize" => 10}
  end

  @tag obligation: "graphvix.builder.I7"
  test "set_attributes targets graph node and edge maps" do
    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:graph, rankdir: "LR")
      |> Graphvix.set_attributes(:edge, color: "gray")

    assert g.attributes == %{graph: %{"rankdir" => "LR"}, node: %{}, edge: %{"color" => "gray"}}
  end

  # -- I8 -----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I8"
  test "clusters and subgraphs nest and return their own type" do
    inner = Cluster.new("inner") |> Cluster.add_node("b")

    sub =
      Subgraph.new("s")
      |> Subgraph.add_cluster(inner)
      |> Subgraph.set_attributes(:graph, rank: "same")

    outer =
      Cluster.new("outer")
      |> Cluster.add_subgraph(sub)
      |> Cluster.set_attributes(:node, color: "red")

    assert outer.__struct__ == Cluster
    assert sub.__struct__ == Subgraph
    assert Cluster.new("e").attributes == %{graph: %{}, node: %{}}
    assert outer.attributes == %{graph: %{}, node: %{"color" => "red"}}
    assert [%{id: "s"} = s] = outer.subgraphs
    assert s.attributes.graph == %{"rank" => "same"}
    assert [%{id: "inner"} = i] = s.clusters
    assert ids(i.nodes) == ["b"]
  end

  @tag obligation: "graphvix.builder.I8"
  test "clusters nest in clusters and subgraphs in subgraphs" do
    c = Cluster.new("o") |> Cluster.add_cluster(Cluster.new("i") |> Cluster.add_node("a"))
    s = Subgraph.new("o") |> Subgraph.add_subgraph(Subgraph.new("i") |> Subgraph.add_node("a"))

    assert ids(c.clusters) == ["i"]
    assert ids(s.subgraphs) == ["i"]
    assert ids(hd(c.clusters).nodes) == ["a"]
  end

  @tag obligation: "graphvix.builder.I8"
  test "clusters and subgraphs take both graph and node attributes" do
    c =
      Cluster.new("c")
      |> Cluster.set_attributes(:graph, label: "C")
      |> Cluster.set_attributes(:node, shape: "box")

    s =
      Subgraph.new("s")
      |> Subgraph.set_attributes(:graph, rank: "same")
      |> Subgraph.set_attributes(:node, color: "red")

    assert c.attributes == %{graph: %{"label" => "C"}, node: %{"shape" => "box"}}
    assert s.attributes == %{graph: %{"rank" => "same"}, node: %{"color" => "red"}}
  end

  @tag obligation: "graphvix.builder.I8"
  test "set_attributes on a cluster or subgraph rejects :edge" do
    assert_raise FunctionClauseError, fn ->
      Cluster.set_attributes(Cluster.new("x"), :edge, color: "red")
    end

    assert_raise FunctionClauseError, fn ->
      Subgraph.set_attributes(Subgraph.new("x"), :edge, color: "red")
    end
  end

  # -- I9 -----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I9"
  test "re-adding a cluster or subgraph id appends" do
    g =
      Graphvix.new()
      |> Graphvix.add_cluster(Cluster.new("x") |> Cluster.add_node("a"))
      |> Graphvix.add_cluster(Cluster.new("x") |> Cluster.add_node("b"))
      |> Graphvix.add_subgraph(Subgraph.new("s"))
      |> Graphvix.add_subgraph(Subgraph.new("s"))

    assert ids(g.clusters) == ["x", "x"]
    assert Enum.map(g.clusters, &ids(&1.nodes)) == [["a"], ["b"]]
    assert ids(g.subgraphs) == ["s", "s"]
  end

  # -- I10 ----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I10"
  test "a node in several containers is kept in each" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", color: "green")
      |> Graphvix.add_cluster(Cluster.new("x") |> Cluster.add_node("a", color: "red"))
      |> Graphvix.add_cluster(Cluster.new("y") |> Cluster.add_node("a", color: "blue"))

    assert [%{id: "a", attributes: %{"color" => "green"}}] = g.nodes

    assert [[%{attributes: %{"color" => "red"}}], [%{attributes: %{"color" => "blue"}}]] =
             Enum.map(g.clusters, & &1.nodes)
  end

  # -- I11 ----------------------------------------------------------------------

  @tag obligation: "graphvix.builder.I11"
  test "subgraphs and clusters cannot hold edges" do
    for mod <- [Cluster, Subgraph] do
      Code.ensure_loaded!(mod)
      refute function_exported?(mod, :add_edge, 3)
      refute function_exported?(mod, :add_edge, 4)
      refute Map.has_key?(mod.new("x"), :edges)
    end

    assert Graphvix.new() |> Graphvix.add_edge("a", "b") |> Map.get(:edges) |> length() == 1
  end
end
