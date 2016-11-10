defmodule Graphvix.StateSpec do
  use ESpec
  alias Graphvix.{GraphServer, State}

  before do
    GraphServer.clear
  end

  finally do
    File.rm("graphvix.store")
  end

  describe ".save" do
    it "writes to the specified place in the filesystem" do
      State.save

      :timer.sleep 250

      expect File.rm("graphvix.store") |> to(eq :ok)
      expect File.rm("/tmp/graphvix.store") |> to(eq {:error, :enoent})
    end
  end

  describe ".load" do
    it "should load the saved state of the graphs" do
      GraphServer.new(:test)

      :timer.sleep 50
      State.save
      State.clear(State)
      :timer.sleep 250

      State.load

      expect State.ls |> to(eq [:test])
    end
  end
end
