defmodule Graphvix.EdgeSpec do
  use ESpec
  alias Graphvix.{Graph, Edge, Node}

  describe ".new" do
    it "returns an edge with a unique id" do
      Graph.restart
      n1 = Node.new(label: "Start")
      n2 = Node.new(label: "End")
      n3 = Node.new(label: "Epilogue")

      e1 = Edge.new(n1, n2)
      e2 = Edge.new(n1, n3)

      expect e1.id |> to_not(eq e2.id)
    end

    it "can create an edge from node ids" do
      Graph.restart
      node1 = Node.new(label: "Start")
      node2 = Node.new(label: "End")

      expect Edge.new(node1.id, node2.id) |> to(be_map)
    end

    it "can create an edge from nodes" do
      Graph.restart
      node1 = Node.new(label: "Start")
      node2 = Node.new(label: "End")

      expect Edge.new(node1, node2) |> to(be_map)
    end
  end

  describe ".update" do
    before do
      Graph.restart
    end

    it "updates the correct edge" do
      node1 = Node.new(label: "Start")
      node2 = Node.new(label: "End")

      edge = Edge.new(node1.id, node2.id)
      Edge.update(edge.id, color: "blue")

      expect Graph.find(edge.id) |> Map.get(:attrs) |> Keyword.get(:color) |> to(eq "blue")
    end

    it "can take an edge instead of an id as an argument" do
      node1 = Node.new(label: "Start")
      node2 = Node.new(label: "End")

      edge = Edge.new(node1.id, node2.id)
      Edge.update(edge, color: "blue")

      expect Graph.find(edge.id) |> Map.get(:attrs) |> Keyword.get(:color) |> to(eq "blue")
    end
  end

  describe ".delete" do
    it "deletes an edge from the graph" do
      node1 = Node.new(label: "Start")
      node2 = Node.new(label: "End")

      edge = Edge.new(node1.id, node2.id)
      Edge.delete(edge.id)

      expect Graph.find(edge.id) |> to(be_nil)
    end
  end

  describe ".find" do
    it "finds the correct edge" do
      node1 = Node.new(label: "Start")
      node2 = Node.new(label: "End")
      edge = Edge.new(node1.id, node2.id)

      expect Edge.find(edge.id) |> to(eq edge)
    end
  end
end

