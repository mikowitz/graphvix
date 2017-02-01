defmodule Graphvix.GraphSpec do
  use ESpec
  alias Graphvix.{Graph, Node, Edge, Cluster}

  before do
    Graph.clear
  end

  finally do
    File.rm("graphvix.store")
  end

  describe ".ls" do
    it "returns a list of graphs loaded in the state" do
      expect Graph.ls |> to(be_empty)

      Graph.new("first")

      expect Graph.ls |> to(eq ["first"])
    end
  end

  describe ".new" do
    it "creates a new graph in the state" do
      Graph.new("first")

      expect Graph.ls |> to(eq ["first"])
    end

    it "sets the current graph" do
      Graph.new("first")

      expect Graph.current_graph |> to(eq "first")
    end
  end

  describe ".switch" do
    it "switches to a different, possibly new, named graph" do
      Graph.new("first")

      Graph.switch("second")

      expect Graph.ls |> to(eq ["first", "second"])
      expect Graph.current_graph |> to(eq "second")
    end
  end

  describe ".update" do
    it "sets graph-wide settings" do
      Graph.new("first")
      Graph.update(size: "4, 4")
      expect Graph.write |> to(eq """
digraph G {
  size="4, 4";
}
""" |> String.strip)
    end
  end

  describe ".save" do
    it "saves to DOT format" do
      Graph.new("first")
      {n1_id, _n1} = Node.new(label: "Start")
      {n2_id, _n2} = Node.new(label: "End")
      Edge.new(n1_id, n2_id)
      Graph.save

      :timer.sleep(125)
      {:ok, file_content} = File.read("first.dot")

      expect file_content |> to(eq """
digraph G {
  node_#{n1_id} [label="Start"];
  node_#{n2_id} [label="End"];

  node_#{n1_id} -> node_#{n2_id};
}
""" |> String.strip)

      :timer.sleep(125)
      expect File.rm("first.dot") |> to(eq :ok)
    end
  end

  describe ".write" do
    it "returns a dot representation of the graph" do
      Graph.new("test")
      expect Graph.write |> to(eq "digraph G {\n\n}")
    end

    it "returns nodes and edges correctly" do
      Graph.new("test")
      {n1_id, _n1} = Node.new(label: "Start")
      {n2_id, _n2} = Node.new(label: "End")
      {n3_id, _n3} = Node.new(label: "Epilogue")
      _e1 = Edge.new(n1_id, n2_id)
      _e2 = Edge.new(n1_id, n3_id)

      {c_id, _c} = Cluster.new([n1_id, n2_id])

      expect Graph.write |> to(
      eq ~s/
digraph G {
  node_#{n1_id} [label="Start"];
  node_#{n2_id} [label="End"];
  node_#{n3_id} [label="Epilogue"];

  node_#{n1_id} -> node_#{n2_id};
  node_#{n1_id} -> node_#{n3_id};

  subgraph cluster_#{c_id} {
    node_#{n1_id} -> node_#{n2_id} [style=invis];
    { rank = "same"; node_#{n1_id}; node_#{n2_id}; }
  }
}/ |> String.strip)
    end
  end

  describe ".compile" do
    it "saves at a default file location and compiles to PDF" do
      Graph.new("first")

      Graph.compile

      :timer.sleep 125

      expect File.rm("first.dot") |> to(eq :ok)
      expect File.rm("first.pdf") |> to(eq :ok)
    end

    it "saves at a default file location and compiles to PNG if that option is passed in" do
      Graph.new("first")

      Graph.compile(:png)

      :timer.sleep 125

      expect File.rm("first.dot") |> to(eq :ok)
      expect File.rm("first.png") |> to(eq :ok)
      expect File.rm("first.pdf") |> to(eq {:error, :enoent})
    end
  end

  #describe "reloading state on restart" do
    #it "should return the existing state/current graph" do
      ## TODO: call/cast to non-existent handler to trigger the termination
      #Graph.new(:first)

      #Graph.switch(:second)

      #GenServer.cast(Graph, :bad_call)

      #:timer.sleep 10

      #{graph_name, _graph} = Graph.current_graph
      #expect graph_name |> to(eq :second)
    #end
  #end
end

