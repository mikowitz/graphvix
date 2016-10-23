defmodule Graphvix.ClusterSpec do
  use ESpec
  alias Graphvix.{Graph, Cluster, Node}

  describe ".new" do
    it "returns a map with a unique id" do
      Graph.restart
      n = Node.new(label: "Start")
      expect Cluster.new([n]) |> to(be_map)
    end
  end

  describe ".add" do
    it "adds a node to the cluster" do
      Graph.restart
      n = Node.new(label: "Start")
      c = Cluster.new

      Cluster.add(c.id, [n.id])
      expect Cluster.find(c.id) |> Map.get(:node_ids) |> to(eq [n.id])
    end
  end

  describe ".remove" do
    it "removes a node from the cluster" do
      Graph.restart
      n = Node.new(label: "Start")
      n2 = Node.new(label: "End")
      c = Cluster.new([n, n2])

      Cluster.remove(c.id, n)
      expect Cluster.find(c.id) |> Map.get(:node_ids) |> to(eq [n2.id])
    end
  end

  describe ".delete" do
    it "deletes the cluster with the provided id from the graph" do
      Graph.restart
      c = Cluster.new

      Cluster.delete(c.id)
      expect Cluster.find(c.id) |> to(be_nil)
    end
  end

  describe ".find" do
    it "returns the cluster with the given id" do
      Graph.restart
      c = Cluster.new

      expect Cluster.find(c.id) |> to(eq c)
    end
  end
end

