defmodule Graphvix.GraphTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Graphvix.{Graph, HTMLRecord, Record}
  doctest Graph, except: [
    new: 1, digraph_tables: 1, to_dot: 1, write: 2, compile: 3, show: 2,
    set_global_properties: 3
  ]
  import HTMLRecord, only: [tr: 1, td: 1, td: 2]

  property "generating a graph with a vertex" do
    check all label <- string(:alphanumeric, min_length: 3)
    do
      graph = Graph.new()
      {graph, _vid} = Graph.add_vertex(graph, label, color: "blue")
      assert Graph.to_dot(graph) == """
      digraph G {

        v0 [label="#{label}",color="blue"]

      }
      """ |> String.trim
    end
  end

  property "generating a graph with a record node" do
    check all labels <- list_of(string(:alphanumeric, min_length: 3), min_length: 2, max_length: 5),
      label <- string(:alphanumeric, min_length: 3),
      color <- string(:alphanumeric, min_length: 3)
    do
      record = Record.new(labels, color: "blue")
      graph = Graph.new
      {graph, v0} = Graph.add_record(graph, record)
      {graph, v1} = Graph.add_vertex(graph, label, color: color)
      {graph, _eid} = Graph.add_edge(graph, v0, v1)
      assert Graph.to_dot(graph) == """
      digraph G {

        v0 [label="#{Enum.join(labels, " | ")}",shape="record",color="blue"]
        v1 [label="#{label}",color="#{color}"]

        v0 -> v1

      }
      """ |> String.trim
    end
  end

  property "generating a graph with edges to record ports" do
    check all [l1, l2, p1, l3] <- list_of(string(:alphanumeric, min_length: 3), length: 4)
    do
      graph = Graph.new
      record = Record.new([l1, {p1, l2}])
      {graph, v0} = Graph.add_record(graph, record)
      {graph, v1} = Graph.add_vertex(graph, l3)
      {graph, _eid} = Graph.add_edge(graph, {v0, p1}, v1)
      assert Graph.to_dot(graph) == """
      digraph G {

        v0 [label="#{l1} | <#{p1}> #{l2}",shape="record"]
        v1 [label="#{l3}"]

        v0:#{p1} -> v1

      }
      """ |> String.trim
    end
  end

  property "generating a graph with edges to HTML record ports" do
    check all [l1, l2, p1, l3] <- list_of(string(:alphanumeric, min_length: 3), length: 4)
    do
      graph = Graph.new
      record = HTMLRecord.new([
        tr([
          td(l1),
          td(l2, port: p1)
        ])
      ])
      {graph, v0} = Graph.add_html_record(graph, record)
      {graph, v1} = Graph.add_vertex(graph, l3)
      {graph, _eid} = Graph.add_edge(graph, {v0, p1}, v1)
      assert Graph.to_dot(graph) == """
      digraph G {

        v0 [label=<<table>
          <tr>
            <td>#{l1}</td>
            <td port="#{p1}">#{l2}</td>
          </tr>
        </table>>,shape="plaintext"]
        v1 [label="#{l3}"]

        v0:#{p1} -> v1

      }
      """ |> String.trim
    end
  end

  property "adding a subgraph" do
    check all label <- string(:alphanumeric, min_length: 3)
    do
      graph = Graph.new()
      {graph, vid} = Graph.add_vertex(graph, label, color: "blue")
      {graph, _cid} = Graph.add_subgraph(graph, [vid])

      [subgraph] = graph.subgraphs
      assert subgraph.id == "subgraph0"
      assert subgraph.vertex_ids == [vid]
    end

  end

  property "adding a cluster" do
    check all label <- string(:alphanumeric, min_length: 3)
    do
      graph = Graph.new()
      {graph, vid} = Graph.add_vertex(graph, label, color: "blue")
      {graph, _cid} = Graph.add_cluster(graph, [vid])

      [cluster] = graph.subgraphs
      assert cluster.id == "cluster0"
      assert cluster.vertex_ids == [vid]
    end
  end

  property "generating graphs with global properties" do
    check all color <- string(:alphanumeric, min_length: 3),
      color2 <- string(:alphanumeric, min_length: 3),
      e_label <- string(:printable, min_length: 5)
    do
      graph = Graph.new()
      graph = Graph.set_global_properties(graph, :node, color: color)
      graph = Graph.set_global_properties(graph, :edge, color: color2, label: e_label)

      assert Graph.to_dot(graph) == """
      digraph G {

        node [color="#{color}"]
        edge [label="#{e_label}",color="#{color2}"]

      }
      """ |> String.trim
    end
  end

  property "adding an edge" do
    check all label1 <- string(:alphanumeric, min_length: 3),
      label2 <- string(:alphanumeric, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, _e1} = Graph.add_edge(graph, v1, v2)
      {_, _, etab, _, _} = graph.digraph
      assert length(:ets.tab2list(etab)) == 1
    end
  end

  property "dot format for a graph with edges" do
    check all label1 <- string(:alphanumeric, min_length: 3),
      label2 <- string(:alphanumeric, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, _e1} = Graph.add_edge(graph, v1, v2, color: "blue")

      assert Graph.to_dot(graph) == """
      digraph G {

        v0 [label="#{label1}"]
        v1 [label="#{label2}"]

        v0 -> v1 [color="blue"]

      }
      """ |> String.trim
    end
  end

  property "dot format for a graph with a subgraph" do
    check all label1 <- string(:alphanumeric, min_length: 3),
      label2 <- string(:alphanumeric, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, _e1} = Graph.add_edge(graph, v1, v2, color: "blue")
      {graph, _cid} = Graph.add_subgraph(graph, [v1], style: "filled", color: "blue", node: [shape: "Msquare"])

      assert Graph.to_dot(graph) == """
      digraph G {

        subgraph subgraph0 {

          node [shape="Msquare"]

          style="filled"
          color="blue"

          v0 [label="#{label1}"]

        }

        v1 [label="#{label2}"]

        v0 -> v1 [color="blue"]

      }
      """ |> String.trim
    end
  end

  property "dot format for a graph with a cluster" do
    check all label1 <- string(:alphanumeric, min_length: 3),
      label2 <- string(:alphanumeric, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, _e1} = Graph.add_edge(graph, v1, v2, color: "blue")
      {graph, _cid} = Graph.add_cluster(graph, [v1], style: "filled", color: "blue", node: [shape: "Msquare"])

      assert Graph.to_dot(graph) == """
      digraph G {

        subgraph cluster0 {

          node [shape="Msquare"]

          style="filled"
          color="blue"

          v0 [label="#{label1}"]

        }

        v1 [label="#{label2}"]

        v0 -> v1 [color="blue"]

      }
      """ |> String.trim
    end
  end

  property "dot format for a graph with clusters and subgraphs" do
    check all label1 <- string(:alphanumeric, min_length: 3),
      label2 <- string(:alphanumeric, min_length: 3),
      label3 <- string(:alphanumeric, min_length: 3),
      label4 <- string(:alphanumeric, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, v3} = Graph.add_vertex(graph, label3)
      {graph, v4} = Graph.add_vertex(graph, label4)
      {graph, _e} = Graph.add_edge(graph, v1, v2, color: "blue")
      {graph, _e} = Graph.add_edge(graph, v2, v3)
      {graph, _e} = Graph.add_edge(graph, v3, v4)
      {graph, _cid} = Graph.add_cluster(graph, [v1], style: "filled", color: "blue", node: [shape: "Msquare"])
      {graph, _cid} = Graph.add_subgraph(graph, [v2, v3], node: [shape: "square"], edge: [color: "green"])

      assert Graph.to_dot(graph) == """
      digraph G {

        subgraph cluster0 {

          node [shape="Msquare"]

          style="filled"
          color="blue"

          v0 [label="#{label1}"]

        }

        subgraph subgraph1 {

          node [shape="square"]
          edge [color="green"]

          v1 [label="#{label2}"]
          v2 [label="#{label3}"]

          v1 -> v2

        }

        v3 [label="#{label4}"]

        v0 -> v1 [color="blue"]
        v2 -> v3

      }
      """ |> String.trim
    end
  end

  test "quote escaping" do
    label = ~s({"foo": "bar"})

    graph = Graph.new()
    {graph, _vid} = Graph.add_vertex(graph, label, color: "bl\"ue")
    assert Graph.to_dot(graph) == """
    digraph G {

      v0 [label="{\\"foo\\": \\"bar\\"}",color="bl\\\"ue"]

    }
    """ |> String.trim
  end

  test ".write/2" do
    g = Graph.new()

    :ok = Graph.write(g, "g")

    {:ok, content} = File.read("g.dot")

    :ok = File.rm("g.dot")

    assert content == """
    digraph G {

    }
    """ |> String.trim
  end

  test ".compile/2" do
    g = Graph.new()

    :ok = Graph.compile(g, "g")

    {:ok, content} = File.read("g.dot")

    :ok = File.rm("g.dot")
    :ok = File.rm("g.png")

    assert content == """
    digraph G {

    }
    """ |> String.trim

  end

  test ".compile/3" do
    g = Graph.new()

    :ok = Graph.compile(g, "g", :pdf)

    {:ok, content} = File.read("g.dot")

    :ok = File.rm("g.dot")
    :ok = File.rm("g.pdf")

    assert content == """
    digraph G {

    }
    """ |> String.trim
  end
end
