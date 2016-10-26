defmodule Graphvix.EdgeSpec do
  use ESpec
  alias Graphvix.{Graph, Edge, Node}

  describe ".new" do
    it "returns an edge with a unique id" do
      Graph.restart

      {_n1_id, n1} = Node.new(label: "Start")
      {_n2_id, n2} = Node.new(label: "End")
      {_n3_id, n3} = Node.new(label: "Epilogue")

      {e1_id, _e1} = Edge.new(n1, n2)
      {e2_id, _e2} = Edge.new(n1, n3)

      expect e1_id |> to_not(eq e2_id)
    end

    it "can create an edge from node ids" do
      Graph.restart
      {n1_id, _n1}= Node.new(label: "Start")
      {n2_id, _n2} = Node.new(label: "End")

      expect Edge.new(n1_id, n2_id) |> to(be_tuple)
    end
  end

  describe ".update" do
    it "updates the correct edge" do
      Graph.restart

      {n1_id, _n1} = Node.new(label: "Start")
      {n2_id, _n2} = Node.new(label: "End")
      {e_id, _e} = Edge.new(n1_id, n2_id)

      Edge.update(e_id, color: "blue")

      expect Edge.find(e_id) |> Map.get(:attrs) |> Keyword.get(:color) |> to(eq "blue")
    end
  end

  describe ".delete" do
    it "deletes an edge from the graph" do
      {_n1_id, n1} = Node.new(label: "Start")
      {_n2_id, n2} = Node.new(label: "End")

      {e_id, _e} = Edge.new(n1, n2)
      Edge.delete(e_id)

      expect Edge.find(e_id) |> to(be_nil)
    end
  end

  describe ".find" do
    it "finds the correct edge" do
      Graph.restart

      {_n1_id, n1} = Node.new(label: "Start")
      {_n2_id, n2} = Node.new(label: "End")

      {e_id, e} = Edge.new(n1, n2)

      expect Edge.find(e_id) |> to(eq e)
    end
  end
end

