defmodule Graphvix.GraphTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Graphvix.Graph

  # property "passing an atom generates a named graph" do
  #   check all name <- atom(:alphanumeric) do
  #     graph = Graph.new(name)
  #     assert graph.name == to_string(name)
  #   end
  # end

  # property "passing a string generates a node with a label" do
  #  check all name <- string(:ascii, min_length: 1) do
  #     graph = Graph.new(name)
  #     assert graph.name == name
  #   end
  # end

  # property "generating an empty dot graph" do
  #   check all name <- string(:ascii, min_length: 3) do
  #     graph = Graph.new(name)
  #     assert Graph.to_dot(graph) == """
  #     digraph "#{name}" {

  #     }
  #     """ |> String.trim
  #   end
  # end

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

  property "adding an edge" do
    check all label1 <- string(:ascii, min_length: 3),
      label2 <- string(:ascii, min_length: 3)
    do
      graph = Graph.new()
      {graph, v1} = Graph.add_vertex(graph, label1)
      {graph, v2} = Graph.add_vertex(graph, label2)
      {graph, _e1} = Graph.add_edge(graph, v1, v2)
      {_, _, etab, _, _} = graph
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
