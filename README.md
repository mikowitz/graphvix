# Graphvix

Graphviz in Elixir.

Graphvix 2.0 models a graph as plain, immutable data. Every construction
function returns a new graph, so graphs are built with pipes, compared with
`==`, and never held in a process or ETS table.

## Installation

```elixir
def deps do
  [{:graphvix, "~> 2.0"}]
end
```

Rendering to DOT needs nothing else. `Graphvix.compile/3` runs Graphviz's
`dot`, which must be on your `PATH`.

## Usage

```elixir
alias Graphvix.{Cluster, Subgraph}

graph =
  Graphvix.new()
  |> Graphvix.set_attributes(:graph, rankdir: "LR")
  |> Graphvix.set_attributes(:node, shape: "box")
  |> Graphvix.add_node("start", color: "green")
  |> Graphvix.add_cluster(
    Cluster.new("work")
    |> Cluster.set_attributes(:graph, label: "Work")
    |> Cluster.add_node("build")
    |> Cluster.add_node("test")
  )
  |> Graphvix.add_subgraph(Subgraph.new("ends") |> Subgraph.set_attributes(:graph, rank: "same"))
  |> Graphvix.add_edge("start", "build")
  |> Graphvix.add_edge("build", "test", label: "then")

Graphvix.to_dot(graph)        # the DOT text
Graphvix.write(graph, "flow")   # writes flow.dot
Graphvix.compile(graph, "flow") # writes flow.dot and flow.png
```

* **Graphs** — `Graphvix.new/1` takes `digraph:` (default `true`) and
  `strict:` (default `false`).
* **Nodes** — ids are strings, atoms or numbers, stored as strings. Adding an
  id again in the same graph, subgraph or cluster merges its attributes.
* **Edges** — `Graphvix.add_edge/4` connects ids, `{id, port}`,
  `{id, port, compass}` or `{id, nil, compass}`. Edges live at the root.
* **Subgraphs and clusters** — built inside-out with `Graphvix.Subgraph` and
  `Graphvix.Cluster` (`new/1`, `add_node/3`, `add_subgraph/2`,
  `add_cluster/2`, `set_attributes/3`) and nested to any depth. Clusters are
  emitted as `cluster_<id>`; refer to them that way in `lhead`/`ltail`.
* **Attributes** — keyword lists or maps. `set_attributes/3` targets
  `:graph`, `:node` or `:edge` (subgraphs and clusters: `:graph`, `:node`).

## Records

Use a `Graphvix.Record` or `Graphvix.HTMLRecord` as a node's `label`. The node
gets `shape: "record"` or `shape: "plaintext"` unless you set a shape.

```elixir
import Graphvix.Record, only: [row: 1, column: 1]
import Graphvix.HTMLRecord, only: [tr: 1, td: 1, td: 2]

record = Graphvix.Record.new(row(["a", column([{"p1", "b"}, "c"])]))
table = Graphvix.HTMLRecord.new([tr([td("x", port: "p2"), td("y")])], border: 0)

Graphvix.new()
|> Graphvix.add_node("r", label: record)
|> Graphvix.add_node("t", label: table)
|> Graphvix.add_edge({"r", "p1"}, {"t", "p2", :n})
```

Cell text is escaped for you. `HTMLRecord` is the only way to produce an
HTML-like label; every other string is quoted.

## Warnings

`Graphvix.warnings/1` lists what Graphviz would silently tolerate: unknown or
misapplied attributes, nodes that Graphviz moves between clusters (including
through `rank` subgraphs), duplicate cluster names, missing ports,
conflicting attribute values, and more. `to_dot/1`, `write/2` and
`compile/3` log each warning and still produce output.

## The Contract

`contracts/` holds the [Covenant](https://hex.pm/packages/covenant) Contract
that 2.0 was built from, and `test/contract/` its executable tests.
`mix covenant.check` verifies both. The Graphviz attribute table in
`Graphvix.Attributes` is regenerated with `mix graphvix.gen.attributes`.

## Upgrading from 1.x

* `Graphvix.Graph.*` functions are now on `Graphvix` and return the graph,
  not `{graph, id}`: you choose node ids yourself.
* "Vertex" is now "node"; `add_record/2` and `add_html_record/2` are gone
  (pass the record as `label:`); `Record.new/2` is now `Record.new/1`.
* Subgraphs and clusters are structs you build and add, not lists of ids.
* `show/2` is gone.
