# Graphvix

Graphviz in Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

1. Add `graphvix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:graphvix, "~> 0.1.0"}]
end
```

2. Ensure `graphvix` is started before your application:

```elixir
def application do
  [applications: [:graphvix]]
end
```

# Usage

1. Start up a new process containing your graph

    ```elixir
    iex> graph = Graphvix.new
    ```

1. Add a single node

    ```elixir
    iex> Graphvix.add_node(graph, label: "Start")
    ```

1. Add an edge between two existing nodes

    ```elixir
    iex> node1 = Graphvix.add_node(graph, label: "Start")
    iex> node2 = Graphvix.add_node(graph, label: "End")
    iex> edge = Graphvix.add_edge(graph, node1, node2, color: "blue")
    ```

1. Update settings to nodes and edges

    ```elixir
    iex> Graphvix.update(graph, node1.id, color: "red")
    iex> Graphvix.update(graph, edge.id, label: "My connector")
    ```

1. Show the internal structure of the graph

    ```elixir
    iex> Graphvix.get(graph)
    %{
       nodes: %{ ... }
       edges: %{ ... }
    }
    ```
1. Convert the graph to DOT format

    ```elixir
    iex> Graphvix.write(graph)
    'digraph G {
      node_1 [label="Start",color="red"];
      node_2 [label="End"];

      node_1 -> node_2 [color="blue",label="My connector"];
    }'
    ```
1. Save the graph to a .dot file, with an optional filename

    ```elixir
    iex> Graphvix.save(graph) #=> creates G.dot
    iex> Graphvix.save(graph, "my_graph") #=> creates my_graph.dot
    ```

1. Compile the graph to a PDF or PNG

    ```elixir
    iex> Graphvix.compile(graph) #=> creates G.dot and G.pdf
    iex> Graphvix.compile(graph, :png) #=> creates G.dot and G.png
    ```

1. Compile and open the graph as a PDF/PNG from IEx

    ```elixir
    iex> Graphvix.graph(graph) #=> creates G.dot and G.pdf; opens G.pdf
    ```
