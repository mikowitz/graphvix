defmodule Graphvix.NodeSpec do
  use ESpec
  alias Graphvix.{Graph, Node, Edge, Cluster}

  describe ".new" do
    it "returns a map with a unique id" do
      Graph.restart
      expect Node.new(label: "Start", color: "red") |> to(be_map)
    end
  end

  describe ".update" do
    it "updates the correct node" do
      Graph.restart
      n = Node.new(label: "Start", color: "red")
      Node.update(n.id, color: "blue")

      expect Graph.find(n.id) |> Map.get(:attrs) |> Keyword.get(:color) |> to(eq "blue")
    end

    it "can take the node instead of id as the argument" do
      Graph.restart
      n = Node.new(label: "Start", color: "red")
      Node.update(n, color: "blue")

      expect Graph.find(n.id) |> Map.get(:attrs) |> Keyword.get(:color) |> to(eq "blue")
    end
  end

  describe ".delete" do
    it "removes the node and all associated edges" do
      Graph.restart
      n = Node.new
      n2 = Node.new
      e = Edge.new(n.id, n2.id)

      Node.delete(n2.id)

      expect Node.find(n.id) |> to(be_map)
      expect Node.find(n2.id) |> to(be_nil)
      expect Edge.find(e.id) |> to(be_nil)
    end

    it "removes the node from any clusters that contain it" do
      Graph.restart
      n = Node.new
      n2 = Node.new
      c = Cluster.new([n.id, n2.id])

      Node.delete(n2.id)

      expect Node.find(n.id) |> to(be_map)
      expect Node.find(n2.id) |> to(be_nil)
      expect Cluster.find(c.id) |>  Map.get(:node_ids) |> to(eq [n.id])
    end

    it "removes based on the node rather than the node id" do
      Graph.restart
      n = Node.new
      n2 = Node.new
      e = Edge.new(n.id, n2.id)

      Node.delete(n2)

      expect Node.find(n.id) |> to(be_map)
      expect Node.find(n2.id) |> to(be_nil)
      expect Edge.find(e.id) |> to(be_nil)
    end
  end

  describe ".find" do
    it "finds the correct node" do
      Graph.restart
      n = Node.new(label: "Start", color: "red")
      expect Node.find(n.id) |> to(eq n)
    end
  end
end
