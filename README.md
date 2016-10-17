# Graphvix

Graphviz in Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

1. Add `graphvix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:graphvix, "~> 0.2.0"}]
end
```

2. Ensure `graphvix` is started before your application:

```elixir
def application do
  [applications: [:graphvix]]
end
```

# Usage

1. Alias the included modules for ease of use

    ```elixir
    iex> alias Graphvix.{Graph, Node, Edge, Cluster}
    ```

1. Start up the graph state process. Currently only one graph can be active
    at a time. See `Graph.save` and `Graph.load` below for information about
    working with multiple graphs.

    ```elixir
    iex> Graph.start
    ```

1. Add a single node

    ```elixir
    iex> Node.new(label: "Start")
    ```

1. Add an edge between two existing nodes

    ```elixir
    iex> node1 = Node.new(label: "Start")
    iex> node2 = Node.new(label: "End")
    iex> edge = Edge.new(node1, node2, color: "blue")
    ```

1. Update settings to nodes and edges

    ```elixir
    iex> Node.update(node1.id, color: "red")
    iex> Edge.update(edge.id, label: "My connector")
    ```

1. Show the internal structure of the graph

    ```elixir
    iex> Graph.get
    %{
       nodes: %{ ... },
       edges: %{ ... },
       clusters: %{ ... }
    }
    ```
1. Convert the graph to DOT format

    ```elixir
    iex> Graph.write(graph)
    'digraph G {
      node_1 [label="Start",color="red"];
      node_2 [label="End"];

      node_1 -> node_2 [color="blue",label="My connector"];
    }'
    ```
1. Save the graph to a .dot file, with an optional filename

    ```elixir
    iex> Graph.save(:dot) #=> creates G.dot
    iex> Graph.save(:dot, "my_graph") #=> creates my_graph.dot
    ```

1. Or save the Elixir form of the graph to a .txt file

    ```elixir
    iex> Graph.save(:txt) #=> creates G.txt
    iex> Graph.save(:txt, "my_graph") #=> creates my_graph.txt
    ```

1. Compile the graph to a PDF or PNG

    ```elixir
    iex> Graph.compile #=> creates G.dot and G.pdf
    iex> Graph.compile(:png) #=> creates G.dot and G.png
    iex> Graph.compile("my_graph", :png) #=> creates my_graph.dot and my_graph.png
    ```

1. Compile and open the graph as a PDF/PNG from IEx

    ```elixir
    iex> Graph.graph #=> creates G.dot and G.pdf; opens G.pdf
    iex> Graph.graph("my_graph") #=> creates my_graph.dot and my_graph.pdf; opens my_graph.pdf
    iex> Graph.graph("G2", :png) #=> creates G2.dot and G2.png; opens G2.png
    ```

1. Reload a graph that had been saved as a .txt file. This updates the
  state of the graph process.

    ```elixir
    iex> Graph.load("my_graph.txt")
    ```

1. Reset the state of the graph process to an empty graph.

    ```elixir
    iex> Graph.restart
    ```

