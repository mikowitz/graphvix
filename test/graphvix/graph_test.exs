defmodule Graphvix.GraphTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Graphvix.Graph

  property "generating a graph with a vertex" do
    check all label <- string(:ascii, min_length: 3)
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

  property "adding a subgraph" do
    check all label <- string(:ascii, min_length: 3)
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
    check all label <- string(:ascii, min_length: 3)
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
    check all color <- string(:ascii, min_length: 3),
      color2 <- string(:ascii, min_length: 3),
      e_label <- string(:printable, min_length: 5)
    do
      graph = Graph.new()
      graph = Graph.set_property(graph, :node, color: color)
      graph = Graph.set_properties(graph, :edge, color: color2, label: e_label)

      assert Graph.to_dot(graph) == """
      digraph G {

        node [color="#{color}"]
        edge [label="#{e_label}",color="#{color2}"]

      }
      """ |> String.trim
    end
  end

  property "adding an edge" do
    check all label1 <- string(:ascii, min_length: 3),
      label2 <- string(:ascii, min_length: 3)
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
    check all label1 <- string(:ascii, min_length: 3),
      label2 <- string(:ascii, min_length: 3)
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
    check all label1 <- string(:ascii, min_length: 3),
      label2 <- string(:ascii, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, _e1} = Graph.add_edge(graph, v1, v2, color: "blue")
      {graph, _cid} = Graph.add_subgraph(graph, [v1], subgraph: [style: "filled", color: "blue"], node: [shape: "Msquare"])

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
    check all label1 <- string(:ascii, min_length: 3),
      label2 <- string(:ascii, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, _e1} = Graph.add_edge(graph, v1, v2, color: "blue")
      {graph, _cid} = Graph.add_cluster(graph, [v1], subgraph: [style: "filled", color: "blue"], node: [shape: "Msquare"])

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
    check all label1 <- string(:ascii, min_length: 3),
      label2 <- string(:ascii, min_length: 3),
      label3 <- string(:ascii, min_length: 3),
      label4 <- string(:ascii, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, v3} = Graph.add_vertex(graph, label3)
      {graph, v4} = Graph.add_vertex(graph, label4)
      {graph, _e} = Graph.add_edge(graph, v1, v2, color: "blue")
      {graph, _e} = Graph.add_edge(graph, v2, v3)
      {graph, _e} = Graph.add_edge(graph, v3, v4)
      {graph, _cid} = Graph.add_cluster(graph, [v1], subgraph: [style: "filled", color: "blue"], node: [shape: "Msquare"])
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

  test ".write/2" do
    g = Graph.new()

    :ok = Graph.write(g, "g.dot")

    {:ok, content} = File.read("g.dot")

    :ok = File.rm("g.dot")

    assert content == """
    digraph G {

    }
    """ |> String.trim
  end
end
