defmodule Graphvix.RenderContractTest do
  use Covenant.Case, component: "graphvix.render", async: true
  use ExUnitProperties

  import ExUnit.CaptureLog
  import Graphvix.HTMLRecord, only: [tr: 1, td: 1, td: 2]

  alias Graphvix.{Cluster, HTMLRecord, Record, Subgraph}

  # -- helpers ------------------------------------------------------------------

  defp tmp_base do
    Path.join(System.tmp_dir!(), "graphvix-render-#{System.unique_integer([:positive])}")
  end

  # Runs `dot -T<format>` on DOT text; returns {output, exit_status}.
  defp run_dot(text, format) do
    path = tmp_base() <> ".dot"
    File.write!(path, text)

    try do
      System.cmd("dot", ["-T#{format}", path], stderr_to_stdout: true)
    after
      File.rm(path)
    end
  end

  defp dot_json!(text) do
    {out, 0} = run_dot(text, "json")
    JSON.decode!(out)
  end

  defp quiet_to_dot(graph) do
    {dot, _log} = with_log(fn -> Graphvix.to_dot(graph) end)
    dot
  end

  defp worked_example do
    Graphvix.new(strict: true)
    |> Graphvix.set_attributes(:graph, rankdir: "LR")
    |> Graphvix.set_attributes(:node, shape: "box")
    |> Graphvix.set_attributes(:edge, color: "gray")
    |> Graphvix.add_subgraph(
      Subgraph.new("s1")
      |> Subgraph.set_attributes(:graph, rank: "same")
      |> Subgraph.add_node("c")
      |> Subgraph.add_node("d")
    )
    |> Graphvix.add_cluster(
      Cluster.new("outer")
      |> Cluster.set_attributes(:graph, label: "Outer")
      |> Cluster.set_attributes(:node, color: "red")
      |> Cluster.add_cluster(Cluster.new("inner") |> Cluster.add_node("b"))
      |> Cluster.add_node("a", label: "Start")
    )
    |> Graphvix.add_node("a", style: "filled")
    |> Graphvix.add_node("r", label: HTMLRecord.new([tr([td("x", port: "p1")])]))
    |> Graphvix.add_edge("a", "b")
    |> Graphvix.add_edge({"r", "p1", :ne}, "c", label: ~s(say "hi"))
  end

  @worked_example_dot """
  strict digraph G {
    rankdir="LR";
    node [shape="box"];
    edge [color="gray"];
    subgraph "s1" {
      rank="same";
      "c";
      "d";
    }
    subgraph "cluster_outer" {
      label="Outer";
      node [color="red"];
      subgraph "cluster_inner" {
        "b";
      }
      "a" [label="Start"];
    }
    "a" [style="filled"];
    "r" [label=<<table><tr><td port="p1">x</td></tr></table>>, shape="plaintext"];
    "a" -> "b";
    "r":"p1":ne -> "c" [label="say \\"hi\\""];
  }
  """

  # -- I1 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I1"
  test "header reflects digraph and strict" do
    assert quiet_to_dot(Graphvix.new()) == "digraph G {\n}\n"
    assert quiet_to_dot(Graphvix.new(digraph: false)) == "graph G {\n}\n"
    assert quiet_to_dot(Graphvix.new(strict: true)) == "strict digraph G {\n}\n"
    assert quiet_to_dot(Graphvix.new(digraph: false, strict: true)) == "strict graph G {\n}\n"
  end

  # -- worked example (I1-I9) ---------------------------------------------------

  @tag obligation: [
         "graphvix.render.I1",
         "graphvix.render.I2",
         "graphvix.render.I4",
         "graphvix.render.I5",
         "graphvix.render.I7",
         "graphvix.render.I8",
         "graphvix.render.I9",
         "graphvix.render.I10"
       ]
  test "pinned worked example renders exactly" do
    assert quiet_to_dot(worked_example()) == @worked_example_dot
  end

  @tag :graphviz
  @tag obligation: "graphvix.render.I16"
  test "pinned worked example is valid dot" do
    assert {_, 0} = run_dot(@worked_example_dot, "canon")
  end

  # -- I2 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I2"
  test "containers come before a block's own nodes and edges come last" do
    g =
      Graphvix.new()
      |> Graphvix.add_edge("a", "b")
      |> Graphvix.add_node("a")
      |> Graphvix.add_cluster(Cluster.new("x") |> Cluster.add_node("b"))
      |> Graphvix.add_subgraph(Subgraph.new("s") |> Subgraph.add_node("c"))

    assert quiet_to_dot(g) == """
           digraph G {
             subgraph "s" {
               "c";
             }
             subgraph "cluster_x" {
               "b";
             }
             "a";
             "a" -> "b";
           }
           """
  end

  @tag :graphviz
  @tag obligation: "graphvix.render.I2"
  test "cluster node defaults reach root-declared nodes" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a")
      |> Graphvix.add_cluster(
        Cluster.new("x")
        |> Cluster.set_attributes(:node, color: "red")
        |> Cluster.add_node("a")
      )

    json = dot_json!(quiet_to_dot(g))
    node = Enum.find(json["objects"], &(&1["name"] == "a"))

    assert node["color"] == "red"
  end

  # -- I3 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I3"
  property "definition order survives merges and nesting" do
    check all(names <- uniq_list_of(string(?a..?z, length: 4), min_length: 2, max_length: 8)) do
      [first | _] = names
      inner = Enum.reduce(names, Cluster.new("inner"), &Cluster.add_node(&2, &1))

      g =
        Enum.reduce(names, Graphvix.new(), &Graphvix.add_node(&2, &1))
        |> Graphvix.add_node(first, color: "red")
        |> Graphvix.add_cluster(Cluster.new("outer") |> Cluster.add_cluster(inner))

      lines = String.split(quiet_to_dot(g), "\n")

      root_nodes =
        for line <- lines,
            String.starts_with?(line, ~s(  ")),
            do: line |> String.trim() |> String.split(~s(")) |> Enum.at(1)

      inner_nodes =
        for line <- lines,
            String.starts_with?(line, ~s(      ")),
            do: line |> String.trim() |> String.split(~s(")) |> Enum.at(1)

      assert root_nodes == names
      assert inner_nodes == names
      assert Enum.count(lines, &(&1 =~ ~s(  "#{first}" [color="red"];))) == 1
    end
  end

  # -- I4 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I4"
  test "empty graph and empty cluster" do
    assert quiet_to_dot(Graphvix.new()) == "digraph G {\n}\n"

    g = Graphvix.add_cluster(Graphvix.new(), Cluster.new("x"))
    assert quiet_to_dot(g) == "digraph G {\n  subgraph \"cluster_x\" {\n  }\n}\n"
  end

  @tag obligation: "graphvix.render.I4"
  test "deep nesting indents two spaces per level" do
    deep =
      Enum.reduce(49..1//-1, Cluster.new("50") |> Cluster.add_node("leaf"), fn n, inner ->
        n |> Cluster.new() |> Cluster.add_cluster(inner)
      end)

    dot = quiet_to_dot(Graphvix.add_cluster(Graphvix.new(), deep))

    refute dot =~ "\t"
    assert dot =~ "\n" <> String.duplicate("  ", 51) <> ~s("leaf";\n)

    for n <- 1..50 do
      assert dot =~ "\n" <> String.duplicate("  ", n) <> ~s(subgraph "cluster_#{n}" {\n)
    end
  end

  @tag obligation: "graphvix.render.I4"
  test "every statement ends in a semicolon and there are no blank lines" do
    dot = quiet_to_dot(worked_example())
    lines = dot |> String.trim_trailing("\n") |> String.split("\n")

    refute "" in lines
    assert String.ends_with?(dot, "}\n")
    refute String.ends_with?(dot, "}\n\n")

    for line <- lines, not String.ends_with?(line, "{"), String.trim(line) != "}" do
      assert String.ends_with?(line, ";"), "statement without semicolon: #{inspect(line)}"
    end
  end

  # -- I5 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I5"
  test "attribute keys are sorted and empty lists omitted" do
    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:graph, splines: "ortho", label: "G", bgcolor: "white")
      |> Graphvix.add_node("a", style: "filled", color: "red", label: "A")
      |> Graphvix.add_node("b")
      |> Graphvix.add_edge("a", "b", weight: 2, color: "blue")

    assert quiet_to_dot(g) == """
           digraph G {
             bgcolor="white";
             label="G";
             splines="ortho";
             "a" [color="red", label="A", style="filled"];
             "b";
             "a" -> "b" [color="blue", weight="2"];
           }
           """
  end

  # -- I6 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I6"
  test "quotes are escaped and backslashes preserved" do
    g =
      Graphvix.new()
      |> Graphvix.add_node(~s(say "hi"), label: "line\\nbreak")
      |> Graphvix.add_node("b", label: ~S(already \" escaped))

    assert quiet_to_dot(g) == """
           digraph G {
             "say \\"hi\\"" [label="line\\nbreak"];
             "b" [label="already \\" escaped"];
           }
           """
  end

  @tag obligation: "graphvix.render.I6"
  test "trailing backslash cannot escape the closing quote" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", label: "foo\\")
      |> Graphvix.add_node("b", label: "bar\\\\")

    dot = quiet_to_dot(g)

    # foo\ (odd run of one) gains a backslash; bar\\ (even run of two) is left alone
    assert dot =~ "  \"a\" [label=\"foo\\\\\"];\n"
    assert dot =~ "  \"b\" [label=\"bar\\\\\"];\n"
  end

  @tag :graphviz
  @tag obligation: ["graphvix.render.I6", "graphvix.render.I16"]
  test "hostile ids and labels still parse in dot" do
    ids = [
      ~s(say "hi"),
      "node",
      "edge",
      "graph",
      "strict",
      "subgraph",
      "line\nbreak",
      "back\\slash\\",
      ~S(q\"x)
    ]

    g =
      Enum.reduce(ids, Graphvix.new(), fn id, g ->
        Graphvix.add_node(g, id, label: id <> ~S( \ "))
      end)
      |> Graphvix.add_edge("node", {"edge", "p\"1", :n})

    assert {out, 0} = run_dot(quiet_to_dot(g), "json")

    names = for obj <- JSON.decode!(out)["objects"], do: obj["name"]

    for id <- [~s(say "hi"), "node", "edge", "graph", "strict", "subgraph", "line\nbreak"] do
      assert id in names
    end
  end

  # -- I7 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I7"
  test "clusters are always prefixed and subgraphs are not" do
    g =
      Graphvix.new()
      |> Graphvix.add_subgraph(Subgraph.new("cluster_s"))
      |> Graphvix.add_cluster(Cluster.new("cluster_foo"))
      |> Graphvix.add_cluster(Cluster.new("bar"))

    dot = quiet_to_dot(g)

    assert dot =~ ~s(  subgraph "cluster_s" {\n)
    assert dot =~ ~s(  subgraph "cluster_cluster_foo" {\n)
    assert dot =~ ~s(  subgraph "cluster_bar" {\n)
  end

  # -- I8 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I8"
  test "edge operator follows the graph kind" do
    assert quiet_to_dot(Graphvix.new() |> Graphvix.add_edge("a", "b")) =~ ~s(  "a" -> "b";\n)

    assert quiet_to_dot(Graphvix.new(digraph: false) |> Graphvix.add_edge("a", "b")) =~
             ~s(  "a" -- "b";\n)
  end

  @tag obligation: "graphvix.render.I8"
  test "endpoint forms render as ports and compass points" do
    g =
      Graphvix.new()
      |> Graphvix.add_edge({"a", "p1"}, "b")
      |> Graphvix.add_edge({"a", "p1", :ne}, {"b", nil, :sw})
      |> Graphvix.add_edge({"a", "p1", :bogus}, {"b", nil, :up})

    dot = quiet_to_dot(g)

    assert dot =~ ~s(  "a":"p1" -> "b";\n)
    assert dot =~ ~s(  "a":"p1":ne -> "b":sw;\n)
    assert dot =~ ~s(  "a":"p1" -> "b";\n  "a":"p1":ne -> "b":sw;\n  "a":"p1" -> "b";\n)
  end

  @tag obligation: "graphvix.render.I8"
  test "every valid compass point renders" do
    for compass <- [:n, :ne, :e, :se, :s, :sw, :w, :nw, :c, :_] do
      g = Graphvix.add_edge(Graphvix.new(), {"a", nil, compass}, "b")
      assert quiet_to_dot(g) =~ ~s(  "a":#{compass} -> "b";\n)
    end
  end

  @tag :graphviz
  @tag obligation: "graphvix.render.I8"
  test "port and compass endpoints are accepted by dot" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", label: Record.new([{"p1", "x"}, "y"]))
      |> Graphvix.add_edge({"a", "p1", :ne}, {"b", nil, :sw})

    assert {_, 0} = run_dot(quiet_to_dot(g), "canon")
  end

  # -- I9 -----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I9"
  test "record labels are quoted and html labels are bracketed on any element" do
    html = HTMLRecord.new([tr([td("x")])])

    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:graph, label: html)
      |> Graphvix.add_cluster(Cluster.new("c") |> Cluster.set_attributes(:graph, label: html))
      |> Graphvix.add_node("a", label: Record.new(["x", {"p", ~s(say "y")}]))
      |> Graphvix.add_edge("a", "b", label: html)

    dot = quiet_to_dot(g)

    assert dot =~ ~s(  label=<<table><tr><td>x</td></tr></table>>;\n)
    assert dot =~ ~s(    label=<<table><tr><td>x</td></tr></table>>;\n)
    assert dot =~ ~s(  "a" [label="x | <p> say \\"y\\"", shape="record"];\n)
    assert dot =~ ~s(  "a" -> "b" [label=<<table><tr><td>x</td></tr></table>>];\n)
  end

  # -- I10 ----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I10"
  test "record labels set the shape unless the node sets one" do
    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:node, label: Record.new(["d"]))
      |> Graphvix.add_node("a", label: Record.new(["x"]))
      |> Graphvix.add_node("b", label: HTMLRecord.new([tr([td("y")])]))
      |> Graphvix.add_node("c", label: Record.new(["z"]), shape: "Mrecord")
      |> Graphvix.add_node("d", label: HTMLRecord.new([tr([td("w")])]), shape: "box")

    dot = quiet_to_dot(g)

    assert dot =~ ~s(  node [label="d"];\n)
    assert dot =~ ~s(  "a" [label="x", shape="record"];\n)
    assert dot =~ ~s(  "b" [label=<<table><tr><td>y</td></tr></table>>, shape="plaintext"];\n)
    assert dot =~ ~s(  "c" [label="z", shape="Mrecord"];\n)
    assert dot =~ ~s(  "d" [label=<<table><tr><td>w</td></tr></table>>, shape="box"];\n)
  end

  # -- I11 ----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I11"
  test "numbers atoms and booleans render as quoted text" do
    g =
      Graphvix.add_node(Graphvix.new(), "a",
        fontsize: 10,
        penwidth: 1.5,
        shape: :box,
        fixedsize: true
      )

    assert quiet_to_dot(g) =~
             ~s(  "a" [fixedsize="true", fontsize="10", penwidth="1.5", shape="box"];\n)
  end

  @tag obligation: "graphvix.render.I11"
  test "nil attribute values are omitted" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", color: nil, shape: "box")
      |> Graphvix.add_node("b", label: nil)

    assert quiet_to_dot(g) == """
           digraph G {
             "a" [shape="box"];
             "b";
           }
           """
  end

  # -- I12 ----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I12"
  test "lhead and ltail are emitted as given" do
    g =
      Graphvix.new()
      |> Graphvix.set_attributes(:graph, compound: true)
      |> Graphvix.add_cluster(Cluster.new("x") |> Cluster.add_node("a"))
      |> Graphvix.add_edge("a", "b", lhead: "x", ltail: "cluster_x")

    assert quiet_to_dot(g) =~ ~s(  "a" -> "b" [lhead="x", ltail="cluster_x"];\n)
  end

  @tag :graphviz
  @tag obligation: "graphvix.render.I16"
  property "any built graph is valid dot" do
    text =
      string([?a, ?b, ?\s, ?", ?\\, ?\n, ?{, ?}, ?;, ?-, ?>, ?<, ?[, ?], ?é],
        min_length: 1,
        max_length: 8
      )

    attrs = list_of(tuple({member_of([:label, :color, :xlabel, :tooltip]), text}), max_length: 2)

    record =
      map(
        list_of(one_of([text, tuple({text, text})]), min_length: 1, max_length: 3),
        &Record.new/1
      )

    check all(
            root <- list_of(tuple({text, attrs}), max_length: 4),
            clustered <- list_of(tuple({text, text, attrs}), max_length: 4),
            records <- list_of(tuple({text, record}), max_length: 2),
            edges <- list_of(tuple({text, text, attrs}), max_length: 4),
            digraph <- boolean(),
            max_runs: 50
          ) do
      g = Graphvix.new(digraph: digraph)
      g = Enum.reduce(root, g, fn {id, a}, g -> Graphvix.add_node(g, id, a) end)

      g =
        Enum.reduce(clustered, g, fn {cid, id, a}, g ->
          inner = Cluster.new(cid <> "-inner") |> Cluster.add_node(id, a)

          Graphvix.add_cluster(
            g,
            Cluster.new(cid) |> Cluster.add_cluster(inner) |> Cluster.add_node(id)
          )
        end)

      g = Enum.reduce(records, g, fn {id, r}, g -> Graphvix.add_node(g, id, label: r) end)
      g = Enum.reduce(edges, g, fn {a, b, at}, g -> Graphvix.add_edge(g, a, b, at) end)

      dot = quiet_to_dot(g)
      assert {_, 0} = run_dot(dot, "canon"), dot
    end
  end

  # -- I13 ----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I13"
  test "each warning is logged once per to_dot call and output is still returned" do
    g =
      Graphvix.new()
      |> Graphvix.add_node("a", colour: "red")
      |> Graphvix.add_node("b", colr: "blue")

    assert length(Graphvix.warnings(g)) == 2

    {dot, log} = with_log([level: :warning], fn -> Graphvix.to_dot(g) end)

    assert dot =~ ~s("a" [colour="red"];)
    assert length(Regex.scan(~r/\[warning\]/, log)) == 2
    assert log =~ "colour"
    assert log =~ "colr"
  end

  @tag obligation: "graphvix.render.I13"
  test "a graph without warnings logs nothing" do
    g = Graphvix.add_node(Graphvix.new(), "a", color: "red")

    assert Graphvix.warnings(g) == []
    assert capture_log(fn -> Graphvix.to_dot(g) end) == ""
  end

  @tag obligation: "graphvix.render.I13"
  test "write logs each warning once" do
    base = tmp_base()
    g = Graphvix.add_node(Graphvix.new(), "a", colour: "red")

    log = capture_log([level: :warning], fn -> assert :ok = Graphvix.write(g, base) end)
    File.rm(base <> ".dot")

    assert length(Regex.scan(~r/\[warning\]/, log)) == 1
  end

  # -- I14 ----------------------------------------------------------------------

  @tag obligation: "graphvix.render.I14"
  test "write writes basename.dot with the to_dot text" do
    base = tmp_base()
    g = worked_example()

    assert :ok = Graphvix.write(g, base)
    assert File.read!(base <> ".dot") == quiet_to_dot(g)
    File.rm(base <> ".dot")
  end

  @tag obligation: "graphvix.render.I14"
  test "write returns an error when the file cannot be written" do
    base = Path.join([tmp_base(), "missing-dir", "graph"])

    assert {:error, _reason} = Graphvix.write(Graphvix.new(), base)
  end
end

defmodule Graphvix.RenderCompileContractTest do
  use Covenant.Case, component: "graphvix.render", async: false

  defp tmp_base do
    Path.join(System.tmp_dir!(), "graphvix-compile-#{System.unique_integer([:positive])}")
  end

  defp cleanup(base) do
    for ext <- [".dot", ".png", ".svg"], do: File.rm(base <> ext)
  end

  @tag :graphviz
  @tag obligation: "graphvix.render.I15"
  test "compile writes the dot file and the compiled output" do
    base = tmp_base()
    g = Graphvix.new() |> Graphvix.add_edge("a", "b")

    assert {:ok, path} = Graphvix.compile(g, base)
    assert path == base <> ".png"
    assert File.exists?(base <> ".dot")
    assert File.exists?(base <> ".png")

    assert {:ok, svg} = Graphvix.compile(g, base, :svg)
    assert svg == base <> ".svg"
    assert File.read!(svg) =~ "<svg"
    cleanup(base)
  end

  @tag obligation: "graphvix.render.I15"
  test "compile without dot on PATH returns an error" do
    base = tmp_base()
    empty = base <> "-empty-path"
    File.mkdir_p!(empty)
    old_path = System.get_env("PATH")

    try do
      System.put_env("PATH", empty)
      assert {:error, _reason} = Graphvix.compile(Graphvix.new(), base)
    after
      System.put_env("PATH", old_path)
      File.rm_rf(empty)
      cleanup(base)
    end
  end

  @tag :graphviz
  @tag obligation: "graphvix.render.I15"
  test "compile returns an error when dot fails" do
    base = tmp_base()

    assert {:error, _reason} = Graphvix.compile(Graphvix.new(), base, :not_a_format)
    cleanup(base)
  end
end
