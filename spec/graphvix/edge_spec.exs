defmodule Graphvix.EdgeSpec do
  use ESpec
  alias Graphvix.{Edge, Node}

  before do
    Graphvix.GraphServer.new(:test)
  end

  finally do
    Graphvix.GraphServer.clear
  end


  describe ".new" do
    it "can create an edge from node ids" do
      {n1_id, _n1}= Node.new(label: "Start")
      {n2_id, _n2} = Node.new(label: "End")

      expect Edge.new(n1_id, n2_id) |> to(be_tuple)
    end

    it "can create basic labeled nodes as part of the creation process" do
      {_id, %{start_node: sn_id, end_node: en_id}} = Edge.new(:a, "hello")
      expect Node.find(sn_id) |> to(eq %{ attrs: [label: "a"] })
      expect Node.find(en_id) |> to(eq %{ attrs: [label: "hello"] })
    end

    it "can create multiple edges from a single origin node at once" do
      {n1_id, _n}= Node.new(label: "Start")
      {n2_id, _n} = Node.new(label: "End")
      {n3_id, _n} = Node.new(label: "Epilogue")

      new_edges = Edge.new(n1_id, [n2_id, n3_id, "Epilogue"])
      expect new_edges |> to(have_count 3)
    end
  end

  describe ".chain" do
    it "adds a chain of connected nodes" do
      {n_id, _n} = Node.new
      {n2_id, _n2} = Node.new
      {n3_id, _n3} = Node.new

      [{_id, %{start_node: sn1, end_node: en1}}, {_id2, %{start_node: sn2, end_node: en2}}] = Edge.chain([n_id, n2_id, n3_id])
      expect sn1 |> to(eq n_id)
      expect en1 |> to(eq n2_id)
      expect sn2 |> to(eq n2_id)
      expect en2 |> to(eq n3_id)
    end
  end

  describe ".update" do
    it "updates the correct edge" do
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

      expect Edge.find(e_id) |> to(eq {:error, {:enotfound, :edge}})
    end
  end

  describe ".find" do
    it "finds the correct edge" do
      {_n1_id, n1} = Node.new(label: "Start")
      {_n2_id, n2} = Node.new(label: "End")

      {e_id, e} = Edge.new(n1, n2)

      expect Edge.find(e_id) |> to(eq e)
    end
  end
end
