defmodule Graphvix.GraphServerSpec do
  use ESpec
  alias Graphvix.GraphServer

  describe ".graphs" do
    it "returns a list of graphs loaded in the state" do
      expect GraphServer.graphs |> to(be_empty)
    end
  end
end
