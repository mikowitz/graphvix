---
modules:
  - Graphvix.Warnings
---

# graphvix.warnings

## Purpose

Finds the things Graphviz silently tolerates or silently resolves: unknown and
misapplied attributes, nodes claimed by more than one cluster, duplicate
names, missing ports, record labels in places they cannot work, and invalid
compass points. `Graphvix.warnings/1` is pure: it returns a list of tagged
tuples and never raises, logs or touches the file system. `graphvix.render`
logs the list when a graph is output. Warnings can only be computed once the
whole tree exists, because subgraphs and clusters are built inside-out.

| Rev | Date | Change | Driver |
| --- | --- | --- | --- |
| 1 | 2026-11-14 | First Contract for 2.0, written ahead of the implementation | Graphvix 2.0 rewrite, contract-first |

## Scope

Owns: `Graphvix.warnings/1` (defined on `Graphvix`, delegating to
`Graphvix.Warnings`); every warning kind and its tuple shape; the cluster
placement model; the order of the returned list.

Does not own: logging (`graphvix.render.I13`); the attribute table
(`graphvix.attribute_table`, read through `Graphvix.Attributes.lookup/1`);
record ports and HTML attribute lists (`graphvix.records`, read through
`ports/1` and `allowed_attributes/1`); validating attribute values; changing
the graph in any way.

## Environment facts

All verified with Graphviz `dot` 13.0.0 (20250608.1624) and checked by the
`:graphviz`-tagged tests, which run `dot -Tjson`:

- Among clusters that do not contain each other, a node is placed in the
  first one Graphviz reads it in; later ones silently lose it.
- A later occurrence in a cluster nested inside the node's current cluster
  moves it deeper; a later occurrence in an ancestor of the current cluster
  leaves it where it is.
- Occurrences at the root never anchor a node: a node declared at the root
  and later in a cluster is placed in the cluster.
- Unless the root graph sets `newrank="true"`, a subgraph that sets a
  non-empty `rank` pins its nodes to the innermost cluster enclosing that
  subgraph (the root if none), in whichever order the statements come: a node
  in a root-level `rank="same"` subgraph is removed from every cluster that
  also lists it, silently when the rank subgraph is read first. With
  `newrank="true"` rank subgraphs do not affect placement. Inside a cluster,
  the outermost `rank` subgraph on a node's path claims the node for its
  enclosing cluster: it beats an earlier claim by a cluster nested inside
  that one (pulling the node up), is not beaten by a later one, and loses to
  an earlier unrelated cluster. The full rule is I4; it matched `dot -Tjson`
  on 1500 random trees of clusters, cluster-like, plain and `rank` subgraphs
  (with and without `newrank`) nested three deep.
- `dot` 13.0.0 itself crashes (exit status 139) on some graphs where `rank`
  subgraphs and clusters share nodes (11 of those 1500 trees), e.g. a node
  claimed by `cluster_y` inside `cluster_x` and then listed in a `rank`
  subgraph directly inside `cluster_x`.
- A subgraph is a cluster when its name starts with `cluster` in any case
  (`Cluster_z`, `clusterX`) or when it sets `cluster="true"`.
- In `dot -Tjson` output, cluster objects carry a `bb` key and plain subgraph
  objects do not; a cluster's `nodes` lists the `_gvid` of every node placed
  in it or in any cluster nested in it. A node's placement is the deepest
  cluster whose `nodes` lists it.
- When one node has different explicit values for an attribute in different
  blocks, the value read last wins, with no message.
- `node [...]` and `edge [...]` defaults and a node's own attributes are all
  subject to the "used by" letters of the Graphviz attribute reference
  (G graph, S subgraph, C cluster, N node, E edge).

## Public surface

- `Graphvix.warnings(graph) :: [warning]`
- `Graphvix.Warnings.warnings(graph) :: [warning]` — the implementation
  `Graphvix.warnings/1` delegates to.
- Persisted format — the warning tuples, pinned literally:
  - `{:unknown_attribute, target, key}`
  - `{:unsupported_attribute, target, key}`
  - `{:multiple_clusters, node_id, kept: path, ignored: [path]}`
  - `{:nested_clusters, node_id, placed: path, also: [path]}`
  - `{:duplicate_name, name, [path]}`
  - `{:unknown_port, {from, to}, node_id, port}`
  - `{:record_shape, node_id, shape}`
  - `{:unknown_html_attribute, node_id, element, key}`
  - `{:conflicting_attribute, node_id, key, winner: {path, value}, others: [{path, value}]}`
  - `{:record_label_misplaced, target}`
  - `{:invalid_compass_point, {from, to}, node_id, value}`
- `target` is `:graph`, `{:subgraph, path}`, `{:cluster, path}`,
  `{:node, node_id}`, `{:edge, from, to}`, `{:node_default, path}` or
  `{:edge_default, path}`. `path` is the list of **emitted** names of the
  blocks enclosing a statement, outermost first, including plain subgraphs
  (`["cluster_outer", "s1"]`); `[]` is the root. A subgraph's or cluster's own
  path ends with its own emitted name. `key`, `node_id`, `port` and `name`
  are strings; `from` and `to` are endpoints as stored by `graphvix.builder`;
  `element` is `:table`, `:td` or `:font`; `value` is the value as stored.

#### Modules

`Graphvix.Warnings`. `Graphvix` is owned by `graphvix.builder`; its
`warnings/1` is a one-line delegate.

## Invariants

### graphvix.warnings.I1 — Pure, deterministic and ordered
- **scope:** `Graphvix.warnings/1`
- **must:** return the same list for equal graphs, without logging, I/O or raising; order the list by the render-order position (`graphvix.render.I2`, `I3`) of the first statement each warning concerns (for placement and conflict warnings, the node's first occurrence), breaking ties by the order the kinds appear in this intent (I2 before I3 before … I14), then within one statement by attribute key in sorted order, an edge's `from` before its `to`, and HTML attributes in the order the label renders them
- **why:** callers and tests need a stable list; logging belongs to rendering, and render order is the order Graphviz reads the statements in
- **kind:** non-functional
- **status:** active

### graphvix.warnings.I2 — Unknown attributes
- **scope:** every attribute key on the graph, subgraphs, clusters, nodes, edges and defaults
- **must:** report `{:unknown_attribute, target, key}` for a key that `Graphvix.Attributes.lookup/1` does not know (`colour`, `Color`)
- **why:** a misspelled attribute is silently ignored by Graphviz and is the most common mistake this check can catch
- **kind:** functional
- **status:** active

### graphvix.warnings.I3 — Attributes on elements that do not use them
- **scope:** every known attribute key
- **must:** report `{:unsupported_attribute, target, key}` when the key's "used by" letters do not include the target's letter: root graph attributes G, subgraph graph attributes S (C for a subgraph that I7 treats as a cluster; its target stays `{:subgraph, path}`), cluster graph attributes C, node attributes and `node [...]` defaults N, edge attributes and `edge [...]` defaults E
- **why:** Graphviz ignores an attribute on an element that does not use it, without saying so
- **kind:** functional
- **status:** active

### graphvix.warnings.I4 — A node in clusters that do not contain each other
- **scope:** every node id with occurrences in two or more clusters
- **must:** compute each node's placement by walking its occurrences in render order. An occurrence is a *rank occurrence* when the root graph does not set `newrank` to `true` or `"true"` and some subgraph on its path sets a non-empty `rank`; its cluster is the innermost cluster enclosing the **outermost** such subgraph (none if that subgraph is not inside a cluster). Any other occurrence's cluster is the innermost cluster on its path; occurrences with no cluster are skipped. Starting with no placement and not pinned: (1) a rank occurrence with no cluster makes the root the final placement and ends the walk; (2) with no placement yet, the occurrence's cluster becomes the placement, pinned if it is a rank occurrence; (3) a rank occurrence whose cluster is the placement or an ancestor of it makes that cluster the placement and pins it; (4) an occurrence whose cluster is a strict descendant of an unpinned placement makes that cluster the placement, pinned if it is a rank occurrence; (5) anything else changes nothing. The occurrence that last changed the placement *set* it. Report `{:multiple_clusters, node_id, kept: path, ignored: [path]}` when some occurrence's cluster is neither the placement nor an ancestor of it (an occurrence in a descendant of the placement included), where `kept` is the path of the occurrence that set the placement and `ignored` the paths of those occurrences, in render order. "Descendant" and "ancestor" are by position in the tree, so two clusters that share an emitted name are still different clusters
- **why:** Graphviz keeps the first cluster and silently drops the node from the others, and a `rank` subgraph silently takes its nodes out of clusters outside it
- **kind:** functional
- **record:** placement-model
- **status:** active

### graphvix.warnings.I5 — A node in a cluster and a cluster nested inside it
- **scope:** every node id with occurrences in two or more clusters on one chain of nesting
- **must:** report `{:nested_clusters, node_id, placed: path, also: [path]}` when some occurrence's cluster (as defined in I4) is a strict ancestor of the placement (computed per I4), where `placed` is the path of the occurrence that set the placement and `also` the paths of those ancestor occurrences, in render order; a node can get both this warning and I4's
- **why:** Graphviz places the node in the deepest cluster without a message; listing it in an outer cluster as well is usually a mistake
- **kind:** functional
- **record:** warn-nested-membership
- **status:** active

### graphvix.warnings.I6 — What never warns about placement
- **scope:** I4, I5
- **must:** never count root occurrences, occurrences in plain subgraphs that set no `rank`, or edge endpoints toward I4 or I5; a node at the root and in one cluster, a node only in plain subgraphs, a node in a `rank` subgraph and in the cluster that encloses it, and an edge to a node never added produce no warning
- **why:** declaring every node at the root and grouping them afterwards is normal; subgraphs without `rank` do not affect placement; edges live at the root and create nodes there
- **kind:** functional
- **status:** active

### graphvix.warnings.I7 — Subgraphs that Graphviz treats as clusters
- **scope:** I4, I5
- **must:** treat a `Subgraph` as a cluster when its id starts with `cluster` in any case or its graph attributes set `cluster` to `true` or `"true"`
- **why:** Graphviz places nodes in such subgraphs exactly as in clusters, so the model must agree with it
- **kind:** functional
- **record:** cluster-like-subgraphs
- **status:** active

### graphvix.warnings.I8 — Duplicate subgraph and cluster names
- **scope:** every subgraph and cluster in the graph
- **must:** report `{:duplicate_name, name, [path]}` once per emitted name used by more than one subgraph or cluster anywhere in the graph, listing each one's own path in render order; names are compared as emitted, so a `Subgraph` `cluster_x` clashes with a `Cluster` `x`, and a `Subgraph` `x` does not clash with a `Cluster` `x`
- **why:** DOT subgraph names are global, so two blocks with one name silently merge into one
- **kind:** functional
- **record:** emitted-name-duplicates
- **status:** active

### graphvix.warnings.I9 — Edge ports a node does not define
- **scope:** every edge endpoint with a port
- **must:** report `{:unknown_port, {from, to}, node_id, port}` when no occurrence of that node has its own `label` set to a `Record` or `HTMLRecord` whose `ports/1` includes the port (including nodes with no record label at all, and nodes never added); compass-only endpoints (`{id, nil, compass}`) are never checked
- **why:** Graphviz ignores an unknown port with only a stderr warning and attaches the edge to the node itself
- **kind:** functional
- **status:** active

### graphvix.warnings.I10 — Record labels on non-record shapes
- **scope:** every node occurrence whose own `label` is a `Record`
- **must:** report `{:record_shape, node_id, shape}` when that occurrence's own `shape` is set to anything other than `record` or `Mrecord`; never report it for `HTMLRecord` labels
- **why:** with any other shape Graphviz prints the record syntax as literal text; HTML-like labels work on every shape
- **kind:** functional
- **status:** active

### graphvix.warnings.I11 — Unknown HTML attributes
- **scope:** every `HTMLRecord` used as a node's own label
- **must:** report `{:unknown_html_attribute, node_id, element, key}` for each attribute on a table, `td` or `font` whose hyphenated name is not in `Graphvix.HTMLRecord.allowed_attributes(element)`, including in nested tables
- **why:** Graphviz rejects or ignores unknown HTML attributes; the allowed lists are the ones 1.x documented
- **kind:** functional
- **status:** active

### graphvix.warnings.I12 — Conflicting attribute values across blocks
- **scope:** every node id with occurrences in more than one block
- **must:** report `{:conflicting_attribute, node_id, key, winner: {path, value}, others: [{path, value}]}` for each key set to different values in different occurrences, where `winner` is the occurrence read last in render order and `others` the rest in render order; equal values do not warn
- **why:** Graphviz keeps the last value read and drops the rest silently, and with containers emitted before a block's own nodes the root's value is read last
- **kind:** functional
- **record:** conflict-winner-render-order
- **status:** active

### graphvix.warnings.I13 — Record labels where records cannot work
- **scope:** `label` attributes of the graph, subgraphs, clusters, edges and `node`/`edge` defaults
- **must:** report `{:record_label_misplaced, target}` when one of them is a `Graphvix.Record`; an `HTMLRecord` there never warns
- **why:** record syntax only works as a node's own label with a record shape; anywhere else Graphviz prints it literally
- **kind:** functional
- **status:** active

### graphvix.warnings.I14 — Invalid compass points
- **scope:** every edge endpoint with a compass element
- **must:** report `{:invalid_compass_point, {from, to}, node_id, value}` when the compass is not one of `:n :ne :e :se :s :sw :w :nw :c :_`
- **why:** `graphvix.render` drops an invalid compass so the edge still renders; the caller must be told it was dropped
- **kind:** functional
- **status:** active

### graphvix.warnings.I15 — Warning tuples are pinned
- **scope:** every warning
- **must:** have exactly the shapes listed under Public surface, with paths of emitted names
- **why:** callers pattern-match on warnings; the shapes are a persisted format
- **kind:** persisted-format
- **record:** warning-tuple-shapes
- **status:** active

### graphvix.warnings.I16 — Placement agrees with Graphviz
- **scope:** I4, I5, I6, I7
- **must:** for every graph the builders can make, including `rank` subgraphs with and without `newrank`, the placement implied by the warnings (the innermost cluster on a warned node's `kept` or `placed` path; otherwise the deepest cluster among its occurrences; otherwise the root) equals where `dot -Tjson` places the node; graphs on which `dot` itself crashes are outside this obligation
- **why:** the model is only useful if it matches Graphviz; the environment facts above are Graphviz behaviour, not documentation
- **kind:** functional
- **record:** placement-model
- **status:** active

## Decisions

| Decision | Value | Reason | Record |
| --- | --- | --- | --- |
| Placement model | `rank` subgraph pins (unless `newrank`); else first cluster wins, descendant moves deeper, ancestor keeps | matches `dot` 13.0.0 | placement-model |
| Nested membership | warn | Graphviz is silent; usually a mistake | warn-nested-membership |
| Cluster-like subgraphs | `cluster*` any case, or `cluster=true` | matches `dot` | cluster-like-subgraphs |
| Duplicate names | compare emitted names | DOT names are global | emitted-name-duplicates |
| Conflict winner | last occurrence in render order | matches `dot` | conflict-winner-render-order |
| Warning shapes | tagged tuples, emitted-name paths | pattern-matchable | warning-tuple-shapes |

Worked example. With cluster ids `"1"`, `"2"`, `"3"`:

```elixir
alias Graphvix.Cluster

Graphvix.new()
|> then(fn g -> Enum.reduce(~w(a b c d e f g), g, &Graphvix.add_node(&2, &1)) end)
|> Graphvix.add_cluster(Cluster.new("1") |> Cluster.add_node("a") |> Cluster.add_node("b"))
|> Graphvix.add_cluster(
  Cluster.new("2")
  |> Cluster.add_node("c")
  |> Cluster.add_node("d")
  |> Cluster.add_cluster(Cluster.new("3") |> Cluster.add_node("a") |> Cluster.add_node("e") |> Cluster.add_node("c"))
)
|> Graphvix.warnings()
```

renders `cluster_3` before `cluster_2`'s own nodes, and must return exactly:

```elixir
[
  {:multiple_clusters, "a", kept: ["cluster_1"], ignored: [["cluster_2", "cluster_3"]]},
  {:nested_clusters, "c", placed: ["cluster_2", "cluster_3"], also: [["cluster_2"]]}
]
```

`dot -Tjson` on its output places `a` and `b` in `cluster_1`, `c` and `e` in
`cluster_3`, `d` in `cluster_2`, and `f` and `g` at the root.

## Orderings

- Placement is decided by render order (`graphvix.render.I2`, `I3`): nested
  blocks before a block's own nodes, definition order within each kind. The
  model walks occurrences in exactly that order; any other walk disagrees
  with Graphviz.
- The returned list is ordered per I1.

## Known limits

- Attribute values are not validated (`rankdir="sideways"` does not warn).
- Edges inside subgraphs are not modelled because they cannot be built.
- The model is verified against Graphviz 13.0.0 only.
- Graphs on which `dot` 13.0.0 crashes (see Environment facts) cannot be
  checked; Graphvix still renders them and still reports its warnings.
- `HTMLRecord` labels on non-node elements are not checked against
  `allowed_attributes/1` (only node labels are, per I11).

## Regeneration brief

A regenerator receives this intent, `warnings.decisions.yml`, the system
intent and records, `test/contract/graphvix/warnings_contract_test.exs`, and
public-surface stubs for `Graphvix.Warnings`. It also needs the builder,
records, render and attribute_table Contracts: the walk must follow render
order exactly, and the checks call `Graphvix.Attributes.lookup/1`,
`Graphvix.Record.ports/1`, `Graphvix.HTMLRecord.ports/1` and
`Graphvix.HTMLRecord.allowed_attributes/1`.

Questions previous rounds asked, answered:

- *Does a node at the root and in one cluster warn?* No (I6).
- *Does a `rank="same"` subgraph affect placement?* Yes, unless the root
  sets `newrank`: it pins its nodes at its own cluster level (I4), and a
  cluster elsewhere that lists them loses them with a `multiple_clusters`
  warning.
- *Does a plain subgraph inside a cluster change a node's cluster path?* No;
  only clusters and cluster-like subgraphs (I7) count, but the plain
  subgraph's name still appears in the reported paths.
- *Which value wins a conflict when the root and a cluster disagree?* The
  root's, because a block's own nodes are emitted after its nested blocks
  (I12).
- *Are `nil`-valued attributes checked?* No. Rendering omits them
  (`graphvix.render.I11`), so every check treats them as absent.
