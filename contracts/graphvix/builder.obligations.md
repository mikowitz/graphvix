---
modules:
  - Graphvix
  - Graphvix.Graph
  - Graphvix.Node
  - Graphvix.Edge
  - Graphvix.Subgraph
  - Graphvix.Cluster
  - Graphvix.Builder
---

# graphvix.builder

## Purpose

Builds graphs as immutable data. `Graphvix` is the public entry point:
`new/1`, `add_node/3`, `add_edge/4`, `add_subgraph/2`, `add_cluster/2` and
`set_attributes/3` each return a `%Graphvix.Graph{}`, so construction chains
with pipes. `Graphvix.Subgraph` and `Graphvix.Cluster` are built inside-out
with their own `new/1`, `add_node/3`, `add_subgraph/2`, `add_cluster/2` and
`set_attributes/3`, each returning the receiving struct, then added to their
parent. Rendering (`graphvix.render`) and warnings (`graphvix.warnings`) read
these structs; `Graphvix.to_dot/1`, `write/2`, `compile/3` and `warnings/1`
are defined on `Graphvix` but owned by those components.

Struct fields:

- `Graphvix.Graph`: `digraph` (boolean), `strict` (boolean), `nodes`, `edges`,
  `subgraphs`, `clusters` (lists), `attributes`
  (`%{graph: %{}, node: %{}, edge: %{}}`).
- `Graphvix.Node`: `id`, `attributes`.
- `Graphvix.Edge`: `from`, `to`, `attributes`.
- `Graphvix.Subgraph`, `Graphvix.Cluster`: `id`, `nodes`, `subgraphs`,
  `clusters`, `attributes` (`%{graph: %{}, node: %{}}`).

`attrs` arguments are keyword lists or maps.

### graphvix.builder.I1 — new/1 has documented defaults
- **scope:** `Graphvix.new/1`
- **must:** return a graph with `digraph: true`, `strict: false`, empty `nodes`, `edges`, `subgraphs` and `clusters`, and `attributes: %{graph: %{}, node: %{}, edge: %{}}`; the `digraph:` and `strict:` options override the defaults
- **why:** directed, non-strict graphs are the common case and the 1.x default
- **kind:** functional
- **status:** active

### graphvix.builder.I2 — Construction never changes its input
- **scope:** every construction function on `Graphvix`, `Graphvix.Subgraph` and `Graphvix.Cluster`
- **must:** return a new value and leave the value passed in equal to what it was before the call; no state is kept in ETS, `:digraph` or a process
- **why:** 1.x held graphs in mutable `:digraph` tables; 2.0 graphs are plain values that can be piped, compared and reused
- **kind:** non-functional
- **record:** immutable-graph
- **status:** active

### graphvix.builder.I3 — Ids are normalized to strings
- **scope:** `Graphvix.add_node/3`, `Graphvix.add_edge/4`, `Subgraph.new/1`, `Cluster.new/1`, `Subgraph.add_node/3`, `Cluster.add_node/3`
- **must:** accept node, subgraph and cluster ids given as strings, atoms or numbers and store them as strings, so `:a`, `"a"` name the same node and `1`, `"1"` name the same node
- **why:** callers mix atoms and strings; DOT ids are text, and two spellings of one id must not make two nodes
- **kind:** functional
- **status:** active

### graphvix.builder.I4 — Re-adding a node in the same container merges
- **scope:** `Graphvix.add_node/3`, `Subgraph.add_node/3`, `Cluster.add_node/3`
- **must:** when the id is already in that container's `nodes`, keep one entry at its first position and merge the attributes, later values winning on a clash; re-adding is how a node is updated
- **why:** mirrors how Graphviz reads `a [color=red]; a [shape=box]`, so the struct means what the output means
- **kind:** functional
- **record:** same-container-merge
- **status:** active

### graphvix.builder.I5 — Lists keep definition order
- **scope:** `nodes`, `edges`, `subgraphs` and `clusters` of every graph, subgraph and cluster
- **must:** hold entries in the order they were first added
- **why:** Graphviz reads statements in order and "first cluster wins" depends on it; rendering emits each list in this order
- **kind:** ordering
- **status:** active

### graphvix.builder.I6 — Edges store normalized endpoints and allow repeats
- **scope:** `Graphvix.add_edge/4`, `Graphvix.Edge`
- **must:** accept endpoints `id`, `{id, port}`, `{id, port, compass}` and `{id, nil, compass}`, storing ids and ports as strings and compass points as given; store every call as a separate edge, including repeats; accept endpoints naming nodes never added, without adding them to `nodes`; an edge has no `label` field (label is an attribute)
- **why:** repeated edges are a DOT multigraph and undeclared endpoints are created implicitly by Graphviz; a label is just another attribute
- **kind:** functional
- **status:** active

### graphvix.builder.I7 — Attribute keys are strings and set_attributes merges
- **scope:** every `attrs` argument; `Graphvix.set_attributes/3` with `:graph`, `:node` or `:edge`
- **must:** accept keys as atoms or strings, from keyword lists or maps, and store them as strings so `color:` and `"color"` name one attribute; `set_attributes` merges into the chosen map with later values winning
- **why:** atom and string keys must merge, and atoms must never be created from user strings
- **kind:** functional
- **record:** string-attribute-keys
- **status:** active

### graphvix.builder.I8 — Subgraphs and clusters nest and return their own type
- **scope:** `Graphvix.Subgraph`, `Graphvix.Cluster`
- **must:** `new(id)` returns an empty struct with that id and `attributes: %{graph: %{}, node: %{}}`; `add_node/3`, `add_subgraph/2`, `add_cluster/2` and `set_attributes/3` return the receiving struct's type and nest to any depth, applying I3, I4, I5 and I7 within the struct; `set_attributes/3` accepts `:graph` and `:node` only and raises `FunctionClauseError` for `:edge`
- **why:** nested structures are built inside-out; an edge default inside a subgraph would apply to nothing because edges live only at the root, and passing `:edge` is a programming error, not a questionable attribute
- **kind:** functional
- **record:** edges-root-only
- **status:** active

### graphvix.builder.I9 — Re-adding a subgraph or cluster id appends
- **scope:** `add_subgraph/2` and `add_cluster/2` on `Graphvix`, `Subgraph` and `Cluster`
- **must:** add a second entry when the id is already present; subgraphs and clusters are never merged
- **why:** merging nested trees has no obvious rule; a duplicate name is reported by `graphvix.warnings` instead
- **kind:** functional
- **status:** active

### graphvix.builder.I10 — Occurrences across containers are all kept
- **scope:** every container that holds nodes
- **must:** keep every occurrence of a node id in each container exactly as built; nothing is merged or dropped across containers
- **why:** cluster placement conflicts are reported by `graphvix.warnings`, which needs every occurrence; silently resolving them is an anti-goal
- **kind:** functional
- **record:** keep-cross-container-occurrences
- **status:** active

### graphvix.builder.I11 — Subgraphs and clusters cannot hold edges
- **scope:** `Graphvix.Subgraph`, `Graphvix.Cluster`
- **must:** export no `add_edge` function and have no `edges` field; edges are added only with `Graphvix.add_edge/4`
- **why:** an edge statement inside a cluster pulls both endpoints into it, a silent way for a node to change clusters
- **kind:** functional
- **record:** edges-root-only
- **status:** active
