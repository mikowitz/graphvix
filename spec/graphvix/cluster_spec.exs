defmodule Graphvix.ClusterSpec do
  use ESpec
  alias Graphvix.{Graph, Cluster, Node}

  describe ".new" do
    it "returns a map with a unique id" do
      Graph.restart
      {_n_id, n} = Node.new(label: "Start")
      expect Cluster.new([n]) |> to(be_tuple)
    end
  end

  describe ".add" do
    it "adds a node to the cluster" do
      Graph.restart
      {n_id, _n} = Node.new(label: "Start")
      {c_id, _c} = Cluster.new

      Cluster.add(c_id, [n_id])
      expect Cluster.find(c_id) |> Map.get(:node_ids) |> to(eq [n_id])
    end
  end

  describe ".remove" do
    it "removes a node from the cluster" do
      Graph.restart
      {n_id, _n} = Node.new(label: "Start")
      {n2_id, _n2} = Node.new(label: "End")
      {c_id, _c} = Cluster.new([n_id, n2_id])

      Cluster.remove(c_id, n_id)
      expect Cluster.find(c_id) |> Map.get(:node_ids) |> to(eq [n2_id])
    end
  end

  describe ".delete" do
    it "deletes the cluster with the provided id from the graph" do
      Graph.restart
      {c_id, _c} = Cluster.new

      Cluster.delete(c_id)
      expect Cluster.find(c_id) |> to(eq {:error, {:enotfound, :cluster}})
    end
  end

  describe ".find" do
    it "returns the cluster with the given id" do
      Graph.restart
      {c_id, c} = Cluster.new

      expect Cluster.find(c_id) |> to(eq c)
    end
  end
end
