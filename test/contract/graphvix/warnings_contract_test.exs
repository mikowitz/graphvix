defmodule Graphvix.WarningsContractTest do
  use Covenant.Case, component: "graphvix.warnings", async: true
  use ExUnitProperties

  import ExUnit.CaptureLog
  import Graphvix.HTMLRecord, only: [tr: 1, td: 1, td: 2, font: 2]

  alias Graphvix.{Cluster, HTMLRecord, Record, Subgraph}

  # -- helpers ------------------------------------------------------------------

  defp cluster(id, nodes) when is_list(nodes) do
    Enum.reduce(nodes, Cluster.new(id), fn
      {n, attrs}, c -> Cluster.add_node(c, n, attrs)
      n, c -> Cluster.add_node(c, n)
    end)
  end

  defp worked_example do
    Graphvix.new()
    |> then(fn g -> Enum.reduce(~w(a b c d e f g), g, &Graphvix.add_node(&2, &1)) end)
    |> Graphvix.add_cluster(cluster("1", ["a", "b"]))
    |> Graphvix.add_cluster(
      cluster("2", ["c", "d"])
      |> Cluster.add_cluster(cluster("3", ["a", "e", "c"]))
    )
  end

  defp run_dot_json(text) do
    path = Path.join(System.tmp_dir!(), "graphvix-warn-#{System.unique_integer([:positive])}.dot")
    File.write!(path, text)

    try do
      {out, 0} = System.cmd("dot", ["-Tjson", path], stderr_to_stdout: false)
      JSON.decode!(out)
    after
      File.rm(path)
    end
  end

  # node name => name of the deepest cluster dot placed it in (nil = root)
  defp dot_placement(json) do
    objects = json["objects"]
    by_gvid = Map.new(objects, &{&1["_gvid"], &1})

    depth =
      Enum.reduce(objects, %{}, fn obj, acc ->
        Enum.reduce(obj["subgraphs"] || [], acc, fn child, acc ->
          Map.put(acc, child, Map.get(acc, obj["_gvid"], 0) + 1)
        end)
      end)

    clusters = Enum.filter(objects, &Map.has_key?(&1, "bb"))

    subgraph_count = json["_subgraph_cnt"] || 0

    for obj <- Enum.drop(objects, subgraph_count), into: %{} do
      containing = Enum.filter(clusters, &(obj["_gvid"] in (&1["nodes"] || [])))

      deepest =
        case containing do
          [] -> nil
          list -> list |> Enum.max_by(&Map.get(depth, &1["_gvid"], 0)) |> Map.get("name")
        end

      {by_gvid[obj["_gvid"]]["name"], deepest}
    end
  end

  # -- I1 -----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I1"
  test "warnings are deterministic and silent" do
    g = worked_example() |> Graphvix.add_node("z", colour: "red")

    log = capture_log(fn -> assert Graphvix.warnings(g) == Graphvix.warnings(g) end)

    assert log == ""
  end

  @tag obligation: "graphvix.warnings.I1"
  test "warnings follow render order then kind order" do
    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:graph, colr: "x")
      |> Graphvix.add_node("b", colour: "x")
      |> Graphvix.add_cluster(
        cluster("x", [{"a", [colr: "y", label: Record.new(["r"]), shape: "box"]}])
      )

    assert Graphvix.warnings(g) == [
             {:unknown_attribute, :graph, "colr"},
             {:unknown_attribute, {:node, "a"}, "colr"},
             {:record_shape, "a", "box"},
             {:unknown_attribute, {:node, "b"}, "colour"}
           ]
  end

  # -- I2 -----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I2"
  test "unknown attributes are reported for every target" do
    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:node, Color: "red")
      |> Graphvix.add_cluster(Cluster.new("x") |> Cluster.set_attributes(:graph, colour: "red"))
      |> Graphvix.add_node("a", colour: "red")
      |> Graphvix.add_edge("a", "b", colour: "red")

    assert Graphvix.warnings(g) == [
             {:unknown_attribute, {:node_default, []}, "Color"},
             {:unknown_attribute, {:cluster, ["cluster_x"]}, "colour"},
             {:unknown_attribute, {:node, "a"}, "colour"},
             {:unknown_attribute, {:edge, "a", "b"}, "colour"}
           ]
  end

  @tag obligation: "graphvix.warnings.I2"
  test "known attributes are not reported" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", color: "red")
      |> Graphvix.add_edge("a", "b", color: "blue")

    assert Graphvix.warnings(g) == []
  end

  # -- I3 -----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I3"
  test "root graph attributes use G" do
    assert Graphvix.warnings(Graphvix.set_attributes(Graphvix.new(), :graph, rank: "same")) ==
             [{:unsupported_attribute, :graph, "rank"}]

    assert Graphvix.warnings(Graphvix.set_attributes(Graphvix.new(), :graph, rankdir: "LR")) == []
  end

  @tag obligation: "graphvix.warnings.I3"
  test "subgraph graph attributes use S" do
    bad =
      Graphvix.add_subgraph(
        Graphvix.new(),
        Subgraph.new("s") |> Subgraph.set_attributes(:graph, rankdir: "LR")
      )

    good =
      Graphvix.add_subgraph(
        Graphvix.new(),
        Subgraph.new("s") |> Subgraph.set_attributes(:graph, rank: "same")
      )

    assert Graphvix.warnings(bad) == [{:unsupported_attribute, {:subgraph, ["s"]}, "rankdir"}]
    assert Graphvix.warnings(good) == []
  end

  @tag obligation: "graphvix.warnings.I3"
  test "cluster graph attributes use C" do
    bad =
      Graphvix.add_cluster(
        Graphvix.new(),
        Cluster.new("x") |> Cluster.set_attributes(:graph, rank: "same")
      )

    good =
      Graphvix.add_cluster(
        Graphvix.new(),
        Cluster.new("x") |> Cluster.set_attributes(:graph, bgcolor: "red")
      )

    assert Graphvix.warnings(bad) == [{:unsupported_attribute, {:cluster, ["cluster_x"]}, "rank"}]
    assert Graphvix.warnings(good) == []
  end

  @tag obligation: "graphvix.warnings.I3"
  test "node attributes and node defaults use N" do
    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:node, weight: 2)
      |> Graphvix.add_cluster(Cluster.new("x") |> Cluster.set_attributes(:node, weight: 3))
      |> Graphvix.add_node("a", weight: 1, shape: "box")

    assert Graphvix.warnings(g) == [
             {:unsupported_attribute, {:node_default, []}, "weight"},
             {:unsupported_attribute, {:node_default, ["cluster_x"]}, "weight"},
             {:unsupported_attribute, {:node, "a"}, "weight"}
           ]
  end

  @tag obligation: "graphvix.warnings.I3"
  test "edge attributes and edge defaults use E" do
    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:edge, shape: "box", weight: 2)
      |> Graphvix.add_edge("a", "b", shape: "box", lhead: "cluster_x")

    assert Graphvix.warnings(g) == [
             {:unsupported_attribute, {:edge_default, []}, "shape"},
             {:unsupported_attribute, {:edge, "a", "b"}, "shape"}
           ]
  end

  # -- I4, I5, I15 --------------------------------------------------------------

  @tag obligation: ["graphvix.warnings.I4", "graphvix.warnings.I5", "graphvix.warnings.I15"]
  test "worked example yields exactly the two documented warnings" do
    assert Graphvix.warnings(worked_example()) == [
             {:multiple_clusters, "a",
              kept: ["cluster_1"], ignored: [["cluster_2", "cluster_3"]]},
             {:nested_clusters, "c", placed: ["cluster_2", "cluster_3"], also: [["cluster_2"]]}
           ]
  end

  @tag :graphviz
  @tag obligation: ["graphvix.warnings.I4", "graphvix.warnings.I5", "graphvix.warnings.I16"]
  test "worked example placement matches dot" do
    {dot, _} = with_log(fn -> Graphvix.to_dot(worked_example()) end)

    assert dot_placement(run_dot_json(dot)) == %{
             "a" => "cluster_1",
             "b" => "cluster_1",
             "c" => "cluster_3",
             "d" => "cluster_2",
             "e" => "cluster_3",
             "f" => nil,
             "g" => nil
           }
  end

  @tag obligation: "graphvix.warnings.I4"
  test "first of several unrelated clusters is kept" do
    g =
      Graphvix.new()
      |> Graphvix.add_cluster(cluster("x", ["a"]))
      |> Graphvix.add_cluster(cluster("y", ["a"]))
      |> Graphvix.add_cluster(cluster("z", ["a"]))

    assert Graphvix.warnings(g) == [
             {:multiple_clusters, "a",
              kept: ["cluster_x"], ignored: [["cluster_y"], ["cluster_z"]]}
           ]
  end

  @tag obligation: "graphvix.warnings.I5"
  test "a later occurrence in a nested cluster moves the node deeper" do
    g =
      Graphvix.new()
      |> Graphvix.add_cluster(cluster("x", ["a"]))
      |> Graphvix.add_cluster(
        Cluster.new("y")
        |> Cluster.add_node("b")
        |> Cluster.add_subgraph(Subgraph.new("s") |> Subgraph.add_cluster(cluster("z", ["b"])))
      )

    assert Graphvix.warnings(g) == [
             {:nested_clusters, "b",
              placed: ["cluster_y", "s", "cluster_z"], also: [["cluster_y"]]}
           ]
  end

  # -- I6 -----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I6"
  test "root plus one cluster never warns" do
    g = Graphvix.new() |> Graphvix.add_node("a") |> Graphvix.add_cluster(cluster("x", ["a"]))

    assert Graphvix.warnings(g) == []
  end

  @tag obligation: "graphvix.warnings.I6"
  test "a node only in plain subgraphs never warns" do
    g =
      Graphvix.new()
      |> Graphvix.add_subgraph(Subgraph.new("s") |> Subgraph.add_node("a"))
      |> Graphvix.add_subgraph(Subgraph.new("t") |> Subgraph.add_node("a"))
      |> Graphvix.add_cluster(cluster("x", ["b"]))

    assert Graphvix.warnings(g) == []
  end

  @tag obligation: "graphvix.warnings.I6"
  test "edges to undeclared nodes neither warn nor anchor" do
    g =
      Graphvix.new()
      |> Graphvix.add_cluster(cluster("x", ["a"]))
      |> Graphvix.add_edge("a", "ghost")
      |> Graphvix.add_edge("ghost", "other")

    assert Graphvix.warnings(g) == []
  end

  # -- I7 -----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I7"
  test "subgraphs named like clusters count as clusters" do
    for id <- ["clusterfoo", "Cluster_z", "CLUSTER"] do
      g =
        Graphvix.new()
        |> Graphvix.add_subgraph(Subgraph.new(id) |> Subgraph.add_node("a"))
        |> Graphvix.add_cluster(cluster("x", ["a"]))

      assert Graphvix.warnings(g) == [
               {:multiple_clusters, "a", kept: [id], ignored: [["cluster_x"]]}
             ]
    end
  end

  @tag obligation: "graphvix.warnings.I7"
  test "subgraphs with cluster true count as clusters" do
    for value <- [true, "true"] do
      g =
        Graphvix.new()
        |> Graphvix.add_subgraph(
          Subgraph.new("s")
          |> Subgraph.set_attributes(:graph, cluster: value)
          |> Subgraph.add_node("a")
        )
        |> Graphvix.add_cluster(cluster("x", ["a"]))

      assert Graphvix.warnings(g) == [
               {:multiple_clusters, "a", kept: ["s"], ignored: [["cluster_x"]]}
             ]
    end
  end

  @tag :graphviz
  @tag obligation: ["graphvix.warnings.I7", "graphvix.warnings.I16"]
  test "cluster-like subgraph placement matches dot" do
    g =
      Graphvix.new()
      |> Graphvix.add_subgraph(Subgraph.new("Cluster_z") |> Subgraph.add_node("a"))
      |> Graphvix.add_subgraph(
        Subgraph.new("s")
        |> Subgraph.set_attributes(:graph, cluster: true)
        |> Subgraph.add_node("b")
      )
      |> Graphvix.add_cluster(cluster("x", ["a", "b", "c"]))

    {dot, _} = with_log(fn -> Graphvix.to_dot(g) end)

    assert dot_placement(run_dot_json(dot)) == %{
             "a" => "Cluster_z",
             "b" => "s",
             "c" => "cluster_x"
           }
  end

  # -- I8 -----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I8"
  test "duplicate emitted names are reported" do
    g =
      Graphvix.new()
      |> Graphvix.add_subgraph(Subgraph.new("cluster_x"))
      |> Graphvix.add_cluster(Cluster.new("x"))
      |> Graphvix.add_cluster(Cluster.new("y") |> Cluster.add_cluster(Cluster.new("x")))

    assert Graphvix.warnings(g) == [
             {:duplicate_name, "cluster_x",
              [["cluster_x"], ["cluster_x"], ["cluster_y", "cluster_x"]]}
           ]
  end

  @tag obligation: "graphvix.warnings.I8"
  test "a subgraph and a cluster with the same id do not clash" do
    g =
      Graphvix.new()
      |> Graphvix.add_subgraph(Subgraph.new("x"))
      |> Graphvix.add_cluster(Cluster.new("x"))

    assert Graphvix.warnings(g) == []
  end

  # -- I9 -----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I9"
  test "ports a node does not define are reported" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", label: Record.new([{"p1", "x"}]))
      |> Graphvix.add_node("h", label: HTMLRecord.new([tr([td("x", port: "hp")])]))
      |> Graphvix.add_node("plain")
      |> Graphvix.add_edge({"a", "p1"}, {"h", "hp"})
      |> Graphvix.add_edge({"a", "p2"}, {"plain", "q"})
      |> Graphvix.add_edge({"a", nil, :n}, {"ghost", "r", :s})

    assert Graphvix.warnings(g) == [
             {:unknown_port, {{"a", "p2"}, {"plain", "q"}}, "a", "p2"},
             {:unknown_port, {{"a", "p2"}, {"plain", "q"}}, "plain", "q"},
             {:unknown_port, {{"a", nil, :n}, {"ghost", "r", :s}}, "ghost", "r"}
           ]
  end

  @tag obligation: "graphvix.warnings.I9"
  test "a port defined in any occurrence of the node counts" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a")
      |> Graphvix.add_cluster(
        Cluster.new("x")
        |> Cluster.add_node("a", label: Record.new([{"p", "x"}]))
      )
      |> Graphvix.add_edge({"a", "p"}, "b")

    assert Graphvix.warnings(g) == []
  end

  # -- I10 ----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I10"
  test "record labels on non-record shapes are reported" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", label: Record.new(["x"]), shape: "box")
      |> Graphvix.add_node("b", label: Record.new(["x"]), shape: "Mrecord")
      |> Graphvix.add_node("c", label: Record.new(["x"]), shape: "record")
      |> Graphvix.add_node("d", label: Record.new(["x"]))
      |> Graphvix.add_node("e", label: HTMLRecord.new([tr([td("x")])]), shape: "box")

    assert Graphvix.warnings(g) == [{:record_shape, "a", "box"}]
  end

  # -- I11 ----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I11"
  test "unknown html attributes are reported including nested tables" do
    nested = HTMLRecord.new([tr([td("y")])], bogus: 1)

    label =
      HTMLRecord.new(
        [tr([td(font("x", point_size: 10, weight: "bold"), colour: "red"), td(nested)])],
        border: 0
      )

    g = Graphvix.add_node(Graphvix.new(), "a", label: label)

    assert Graphvix.warnings(g) == [
             {:unknown_html_attribute, "a", :td, "colour"},
             {:unknown_html_attribute, "a", :font, "weight"},
             {:unknown_html_attribute, "a", :table, "bogus"}
           ]
  end

  # -- I12 ----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I12"
  test "conflicting values across blocks name the value read last" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("b", color: "green", shape: "box")
      |> Graphvix.add_cluster(cluster("1", [{"b", [color: "blue", shape: "box"]}]))

    assert Graphvix.warnings(g) == [
             {:conflicting_attribute, "b", "color",
              winner: {[], "green"}, others: [{["cluster_1"], "blue"}]}
           ]
  end

  @tag :graphviz
  @tag obligation: ["graphvix.warnings.I12", "graphvix.warnings.I16"]
  test "the reported winner is the value dot uses" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("b", color: "green")
      |> Graphvix.add_cluster(cluster("1", [{"b", [color: "blue"]}]))

    [{:conflicting_attribute, "b", "color", winner: {_, winner}, others: _}] =
      Graphvix.warnings(g)

    {dot, _} = with_log(fn -> Graphvix.to_dot(g) end)
    node = Enum.find(run_dot_json(dot)["objects"], &(&1["name"] == "b"))

    assert node["color"] == winner
  end

  # -- I13 ----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I13"
  test "record labels outside node labels are reported" do
    r = Record.new(["x"])

    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:graph, label: r)
      |> Graphvix.set_attributes(:node, label: r)
      |> Graphvix.add_cluster(Cluster.new("c") |> Cluster.set_attributes(:graph, label: r))
      |> Graphvix.add_edge("a", "b", label: r)

    assert Graphvix.warnings(g) == [
             {:record_label_misplaced, :graph},
             {:record_label_misplaced, {:node_default, []}},
             {:record_label_misplaced, {:cluster, ["cluster_c"]}},
             {:record_label_misplaced, {:edge, "a", "b"}}
           ]
  end

  @tag obligation: "graphvix.warnings.I13"
  test "html labels outside node labels are fine" do
    h = HTMLRecord.new([tr([td("x")])])

    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:graph, label: h)
      |> Graphvix.add_edge("a", "b", label: h)

    assert Graphvix.warnings(g) == []
  end

  # -- I14 ----------------------------------------------------------------------

  @tag obligation: "graphvix.warnings.I14"
  test "invalid compass points are reported" do
    g =
      Graphvix.new()
      |> Graphvix.add_edge({"a", nil, :up}, {"b", nil, :ne})

    assert Graphvix.warnings(g) == [
             {:invalid_compass_point, {{"a", nil, :up}, {"b", nil, :ne}}, "a", :up}
           ]
  end

  # -- I16 ----------------------------------------------------------------------

  # A random tree: root nodes, plain subgraphs and clusters nested up to three
  # deep, with node ids drawn from a small pool so they repeat across blocks.
  defp node_ids, do: list_of(member_of(~w(a b c d e)), max_length: 3)

  defp block_gen(0), do: tuple({node_ids(), constant([])})

  defp block_gen(depth),
    do:
      tuple(
        {node_ids(),
         list_of(tuple({member_of([:cluster, :plain, :like]), block_gen(depth - 1)}),
           max_length: 2
         )}
      )

  defp build_children(children, prefix) do
    children
    |> Enum.with_index()
    |> Enum.map(fn {{kind, {nodes, grandchildren}}, i} ->
      id = "#{prefix}#{i}"

      {mod, id} =
        case kind do
          :cluster -> {Cluster, id}
          :plain -> {Subgraph, "p" <> id}
          :like -> {Subgraph, "clusterlike" <> id}
        end

      block = Enum.reduce(nodes, mod.new(id), &mod.add_node(&2, &1))

      Enum.reduce(build_children(grandchildren, id <> "_"), block, fn
        {Cluster, child}, acc -> mod.add_cluster(acc, child)
        {Subgraph, child}, acc -> mod.add_subgraph(acc, child)
      end)
      |> then(&{mod, &1})
    end)
  end

  # emitted names of the clusters enclosing each node occurrence, per node id
  defp cluster_occurrences(block, path \\ []) do
    own = for n <- block.nodes, do: {n.id, Enum.filter(path, &(&1 =~ ~r/^cluster/i))}

    nested =
      Enum.flat_map(block.subgraphs, &cluster_occurrences(&1, path ++ [&1.id])) ++
        Enum.flat_map(block.clusters, &cluster_occurrences(&1, path ++ ["cluster_" <> &1.id]))

    nested ++ own
  end

  @tag :graphviz
  @tag obligation: "graphvix.warnings.I16"
  property "placement agrees with dot -Tjson" do
    check all({root_nodes, children} <- block_gen(3), max_runs: 50) do
      g = Enum.reduce(root_nodes, Graphvix.new(), &Graphvix.add_node(&2, &1))

      g =
        Enum.reduce(build_children(children, "c"), g, fn
          {Cluster, c}, g -> Graphvix.add_cluster(g, c)
          {Subgraph, s}, g -> Graphvix.add_subgraph(g, s)
        end)

      warnings = Graphvix.warnings(g)
      occurrences = cluster_occurrences(g)

      expected =
        for {id, _} <- occurrences, into: %{} do
          warned =
            Enum.find_value(warnings, fn
              {:multiple_clusters, ^id, kept: path, ignored: _} -> path
              {:nested_clusters, ^id, placed: path, also: _} -> path
              _ -> nil
            end)

          chain =
            warned ||
              occurrences
              |> Enum.filter(&(elem(&1, 0) == id))
              |> Enum.map(&elem(&1, 1))
              |> Enum.max_by(&length/1)

          {id, chain |> Enum.filter(&(&1 =~ ~r/^cluster/i)) |> List.last()}
        end

      {dot, _} = with_log(fn -> Graphvix.to_dot(g) end)

      assert dot_placement(run_dot_json(dot)) == expected, dot
    end
  end
end
