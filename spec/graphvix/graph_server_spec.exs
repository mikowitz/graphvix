defmodule Graphvix.GraphServerSpec do
  use ESpec
  alias Graphvix.GraphServer

  before do
    GraphServer.clear
  end

  describe ".graphs" do
    it "returns a list of graphs loaded in the state" do
      expect GraphServer.graphs |> to(be_empty)

      GraphServer.new(:first)

      expect GraphServer.graphs |> to(eq [:first])
    end
  end

  describe ".new" do
    it "creates a new graph in the state" do
      GraphServer.new(:first)

      expect GraphServer.graphs |> to(eq [:first])
    end

    it "sets the current graph" do
    end
  end
end

