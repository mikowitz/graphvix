#defmodule Graphvix.GraphSpec do
  #use ESpec

  #alias Graphvix.{Graph, Node, Edge, Cluster}

  #describe ".update" do
    #it "sets graph-wide settings" do
      #Graph.restart
      #Graph.update(size: "4, 4")
      #expect Graph.write |> to(eq """
#digraph G {
  #size="4, 4";
#}
#""" |> String.strip)
    #end
  #end

  #describe ".save" do
    #it "saves a raw Elixir representation of the graph to a txt file" do
      #Graph.start
      #Graph.save(:txt)

      #:timer.sleep(125)
      #expect File.rm("G.txt") |> to(eq :ok)
    #end

    #it "can take an optional filename argument" do
      #Graph.start
      #Graph.save(:txt, "my_graph")

      #:timer.sleep(125)
      #expect File.rm("G.txt") |> to(eq {:error, :enoent})
      #expect File.rm("my_graph.txt") |> to(eq :ok)
    #end

    #it "saves to DOT format" do
      #Graph.restart
      #{n1_id, _n1} = Node.new(label: "Start")
      #{n2_id, _n2} = Node.new(label: "End")
      #Edge.new(n1_id, n2_id)
      #Graph.save(:dot)

      #:timer.sleep(125)
      #{:ok, file_content} = File.read("G.dot")
      #expect file_content |> to(eq """
#digraph G {
  #node_#{n1_id} [label="Start"];
  #node_#{n2_id} [label="End"];

  #node_#{n1_id} -> node_#{n2_id};
#}
#""" |> String.strip)

      #:timer.sleep(125)
      #expect File.rm("G.dot") |> to(eq :ok)
    #end
  #end

  #describe ".load" do
    #it "sets the current graph to the state loaded from a file" do
      #File.write("test.txt", "%{nodes: %{1 => %{id: 1, attrs: [label: \"Hello\"]}}, edges: %{}, clusters: %{}}")

      #Graph.start
      #Graph.load("test.txt")

      #expect Node.find(1) |> Map.get(:attrs) |> Keyword.get(:label) |> to(eq "Hello")
      #expect File.rm("test.txt") |> to(eq :ok)
    #end
  #end

  #describe ".write" do
    #it "returns a dot representation of the graph" do
      #Graph.restart
      #expect Graph.write |> to(eq "digraph G {\n\n}")
    #end

    #it "returns nodes and edges correctly" do
      #Graph.restart
      #{n1_id, _n1} = Node.new(label: "Start")
      #{n2_id, _n2} = Node.new(label: "End")
      #{n3_id, _n3} = Node.new(label: "Epilogue")
      #_e1 = Edge.new(n1_id, n2_id)
      #_e2 = Edge.new(n1_id, n3_id)

      #{c_id, _c} = Cluster.new([n1_id, n2_id])

      #expect Graph.write |> to(
      #eq ~s/
#digraph G {
  #node_#{n1_id} [label="Start"];
  #node_#{n2_id} [label="End"];
  #node_#{n3_id} [label="Epilogue"];

  #node_#{n1_id} -> node_#{n2_id};
  #node_#{n1_id} -> node_#{n3_id};

  #subgraph cluster_#{c_id} {
    #node_#{n1_id} -> node_#{n2_id} [style=invis];
    #{ rank = "same"; node_#{n1_id}; node_#{n2_id}; }
  #}
#}/ |> String.strip)
    #end
  #end

  #describe ".compile" do
    #it "saves at a default file location and compiles to PDF" do
      #Graph.restart

      #Graph.compile

      #expect File.rm("G.dot") |> to(eq :ok)
      #expect File.rm("G.pdf") |> to(eq :ok)
    #end

    #it "saves at a default file location and compiles to PNG if that option is passed in" do
      #Graph.restart

      #Graph.compile("my_graph", :png)

      #:timer.sleep 125

      #expect File.rm("my_graph.dot") |> to(eq :ok)
      #expect File.rm("my_graph.png") |> to(eq :ok)
      #expect File.rm("my_graph.pdf") |> to(eq {:error, :enoent})
    #end

    #it "allows default filename and format as the first parameter" do
      #Graph.restart

      #Graph.compile(:png)

      #:timer.sleep 125

      #expect File.rm("G.dot") |> to(eq :ok)
      #expect File.rm("G.png") |> to(eq :ok)
      #expect File.rm("G.pdf") |> to(eq {:error, :enoent})
    #end
  #end
#end
