defmodule Graphvix.GraphSpec do
  use ESpec
  alias Graphvix.Graph

  before do
    Graph.clear
  end

  finally do
    File.rm("graphvix.store")
  end

  describe ".ls" do
    it "returns a list of graphs loaded in the state" do
      expect Graph.ls |> to(be_empty)

      Graph.new(:first)

      expect Graph.ls |> to(eq [:first])
    end
  end

  describe ".new" do
    it "creates a new graph in the state" do
      Graph.new(:first)

      expect Graph.ls |> to(eq [:first])
    end

    it "sets the current graph" do
      Graph.new(:first)

      {graph_name, _graph} = Graph.current_graph
      expect graph_name |> to(eq :first)
    end
  end

  describe ".switch" do
    it "switches to a different, possibly new, named graph" do
      Graph.new(:first)

      Graph.switch(:second)

      expect Graph.ls |> to(eq [:first, :second])
      {graph_name, _graph} = Graph.current_graph
      expect graph_name |> to(eq :second)
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

