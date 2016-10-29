defmodule Graphvix.NodeSpec do
  use ESpec
  alias Graphvix.{Graph, Node, Edge, Cluster}

  describe ".new" do
    it "returns a tuple of {`id`, `node_map`}" do
      Graph.restart
      expect Node.new(label: "Start", color: "red") |> to(be_tuple)
    end

    it "returns a node with only a label by passing a string" do
      Graph.restart

      {_id, %{attrs: attrs}} = Node.new("a")
      expect Keyword.get(attrs, :label) |> to(eq "a")
    end

    it "returns a node with only a label by passing a symbol" do
      Graph.restart

      {_id, %{attrs: attrs}} = Node.new(:a)
      expect Keyword.get(attrs, :label) |> to(eq "a")
    end
  end

  describe ".update" do
    it "updates the correct node" do
      Graph.restart
      {n_id, _} = Node.new(label: "Start", color: "red")
      Node.update(n_id, color: "blue")

      expect Node.find(n_id) |> Map.get(:attrs) |> Keyword.get(:color) |> to(eq "blue")
    end
  end

  describe ".delete" do
    it "removes the node and all associated edges" do
      Graph.restart
      {n_id, _n} = Node.new
      {n2_id, _n2} = Node.new
      {e_id, _e} = Edge.new(n_id, n2_id)

      Node.delete(n2_id)

      expect Node.find(n_id) |> to(be_map)
      expect Node.find(n2_id) |> to(be_nil)
      expect Edge.find(e_id) |> to(be_nil)
    end

    it "removes the node from any clusters that contain it" do
      Graph.restart
      {n_id, _n} = Node.new
      {n2_id, _n2} = Node.new
      {c_id, _c} = Cluster.new([n_id, n2_id])

      Node.delete(n2_id)

      expect Node.find(n_id) |> to(be_map)
      expect Node.find(n2_id) |> to(be_nil)
      expect Cluster.find(c_id) |>  Map.get(:node_ids) |> to(eq [n_id])
    end
  end

  describe ".find" do
    it "finds the correct node" do
      Graph.restart
      {n_id, n} = Node.new(label: "Start", color: "red")
      expect Node.find(n_id) |> to(eq n)
    end
  end
end
