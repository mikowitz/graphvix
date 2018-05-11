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
