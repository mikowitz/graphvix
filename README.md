# Graphvix

Graphviz in Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

1. Add `graphvix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:graphvix, "~> 0.4.0"}]
end
```

# Usage

See [the wiki](https://github.com/mikowitz/graphvix/wiki/Examples) for examples.

1. Alias the included modules for ease of use

    ```elixir
     alias Graphvix.{Graph, Node, Edge, Cluster}
    ```

1. Create a new graph.

    ```elixir
    Graph.new(:first_graph)
    ```

1. Add a single node

    ```elixir
     Node.new(label: "Start")
    ```

1. Add an edge between two existing nodes

    ```elixir
     {node1_id, _node} = Node.new(label: "Start")
     {node2_id, _node} = Node.new(label: "End")
     {edge_id, _edge} = Edge.new(node1_id, node2_id, color: "blue")
    ```

1. Add a cluster containing one or more nodes

    ```elixir
     {cluster_id, _cluster} = Cluster.new([node1_id, node2_id])
    ```

1. Update settings to nodes and edges

    ```elixir
     Node.update(node1_id, color: "red")
     Edge.update(edge_id, label: "My connector")
    ```

1. Show the internal structure of the graph

    ```elixir
     Graph.get
    %{
       nodes: %{ ... },
       edges: %{ ... },
       clusters: %{ ... },
       attrs: [ ... ]
    }
    ```
1. Convert the graph to DOT format

    ```elixir
     Graph.write
    """
    digraph G {
      node_1 [label="Start",color="red"];
      node_2 [label="End"];

      node_1 -> node_2 [color="blue",label="My connector"];
    }
    """
    ```
1. Save the graph to a .dot file, with an optional filename

    ```elixir
     Graph.save #=> creates "first_graph.dot"
    ```

1. Compile the graph to a PDF or PNG

    ```elixir
     Graph.compile #=> creates first_graph.dot and first_graph.pdf
     Graph.compile(:png) #=> creates first_graph.dot and first_graph.png
    ```

1. Compile and open the graph as a PDF/PNG from IEx

    ```elixir
     Graph.graph #=> creates first_graph.dot and first_graph.pdf; opens first_graph.pdf
     Graph.graph(:png) #=> creates first_graph.dot and first_graph.png; opens first_graph.png
    ```

1. Load a previously created graph.

    ```elixir
     Graph.switch(:old_graph)
    ```
