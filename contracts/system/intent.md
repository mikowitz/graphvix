# Graphvix — system intent

Graphvix is an Elixir interface for Graphviz. Version 2.0 models a graph as
plain, immutable Elixir data: every construction function returns a new value,
so graphs are built with pipes and never held in processes or ETS tables. It
renders that data to DOT text, writes it to disk, and invokes the `dot` binary
to compile it.

Design: `docs/superpowers/specs/2026-11-13-graphvix-2-contracts-design.md`.

## Scope

Owns: building graphs, nodes, edges, nested subgraphs and clusters, attributes,
`Record` and `HTMLRecord` labels; rendering DOT; writing `.dot` files; invoking
`dot`; warning about attributes and structures Graphviz silently mishandles.

Does not own: layout (Graphviz does it), attribute *value* validation, edges
inside subgraphs or clusters, updating or removing existing nodes or edges,
HTML-like labels other than `HTMLRecord`, opening rendered files (1.x `show/2`).

Anti-goals: raising or failing output because of a questionable attribute or
placement (warnings only); silently dropping something the caller wrote;
mutable or process-held state; runtime dependencies.

## Environment facts

- Elixir `~> 1.20` (`mix.exs`).
- Graphviz `dot` 13.0.0 (20250608.1624) is the version every Graphviz
  behaviour in this Contract was verified against. Checked by the
  `:graphviz`-tagged contract tests, which run `dot` and are skipped when it
  is not on `PATH`.
- No runtime dependencies: every dependency in `mix.exs` is `only: :dev` or
  `only: :test`. Checked by `graphvix.attribute_table.I4`.

## Cross-cutting invariants

- Immutability: no construction function changes its input
  (`graphvix.builder.I2`).
- Warnings never raise and never stop output (`graphvix.render.I13`,
  `graphvix.warnings.I1`).
- Vocabulary: graph, node, edge, subgraph, cluster, attribute. "Vertex" is
  gone.

## Components

| Component | Form | Owns |
| --- | --- | --- |
| `graphvix.builder` | light | `Graphvix` construction API and the `Graph`, `Node`, `Edge`, `Subgraph`, `Cluster` structs |
| `graphvix.records` | light | `Record`, `HTMLRecord`, their label syntax and escaping |
| `graphvix.render` | heavy | `to_dot/1`, `write/2`, `compile/3` |
| `graphvix.warnings` | heavy | `warnings/1` and the cluster placement model |
| `graphvix.attribute_table` | light | the generated Graphviz attribute table and its mix task |
