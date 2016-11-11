defmodule Graphvix.GraphServerSpec do
  use ESpec
  alias Graphvix.GraphServer

  before do
    GraphServer.clear
  end

  finally do
    File.rm("graphvix.store")
  end

  describe ".ls" do
    it "returns a list of graphs loaded in the state" do
      expect GraphServer.ls |> to(be_empty)

      GraphServer.new(:first)

      expect GraphServer.ls |> to(eq [:first])
    end
  end

  describe ".new" do
    it "creates a new graph in the state" do
      GraphServer.new(:first)

      expect GraphServer.ls |> to(eq [:first])
    end

    it "sets the current graph" do
      GraphServer.new(:first)

      {graph_name, _graph} = GraphServer.current_graph
      expect graph_name |> to(eq :first)
    end
  end

  describe ".switch" do
    it "switches to a different, possibly new, named graph" do
      GraphServer.new(:first)

      GraphServer.switch(:second)

      expect GraphServer.ls |> to(eq [:first, :second])
      {graph_name, _graph} = GraphServer.current_graph
      expect graph_name |> to(eq :second)
    end
  end

  #describe "reloading state on restart" do
    #it "should return the existing state/current graph" do
      ## TODO: call/cast to non-existent handler to trigger the termination
      #GraphServer.new(:first)

      #GraphServer.switch(:second)

      #GenServer.cast(GraphServer, :bad_call)

      #:timer.sleep 10

      #{graph_name, _graph} = GraphServer.current_graph
      #expect graph_name |> to(eq :second)
    #end
  #end
end

