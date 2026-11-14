---
modules:
  - Graphvix.Attributes
  - Mix.Tasks.Graphvix.Gen.Attributes
---

# graphvix.attribute_table

## Purpose

Holds the Graphviz attribute table that `graphvix.warnings` checks attributes
against: for every attribute on the Graphviz attribute reference
(https://graphviz.org/doc/info/attrs.html), which kinds of element use it.
The reference's "Used By" column names them in words (Graphs, Subgraphs,
Clusters, Nodes, Edges); Graphvix maps them to the letters `:G`, `:S`, `:C`,
`:N`, `:E`. `Graphvix.Attributes` is a generated, checked-in module, so
building and testing never touch the network. `mix graphvix.gen.attributes`
(`Mix.Tasks.Graphvix.Gen.Attributes`), a dev-only task, regenerates it from
the live page; its `parse/1` turns the page's HTML into rows.

Public surface: `Graphvix.Attributes.lookup(name :: String.t()) ::
{:ok, [:G | :S | :C | :N | :E]} | :error`; `Graphvix.Attributes.names() ::
[String.t()]` (every known name, in page order); `Graphvix.Attributes.source() ::
%{url: String.t(), page_modified: String.t(), generated_on: String.t()}`;
`Mix.Tasks.Graphvix.Gen.Attributes.parse(html :: String.t()) ::
[{String.t(), [:G | :S | :C | :N | :E]}]`. Letter lists are always in the
order `:G, :S, :C, :N, :E`.

### graphvix.attribute_table.I1 — lookup/1 covers the reference exactly
- **scope:** `Graphvix.Attributes.lookup/1`
- **must:** return `{:ok, letters}` for every attribute name on the reference page, with letters in the order `:G, :S, :C, :N, :E`, and `:error` for any other name; `names/0` lists exactly the names `lookup/1` knows; `:error` covers names including a known name in another case (`"Color"`) or spelling (`"colour"`)
- **why:** `graphvix.warnings` reports unknown attributes from `:error` and unsupported ones from the letters; Graphviz attribute names are case-sensitive
- **kind:** functional
- **status:** active

### graphvix.attribute_table.I2 — Pinned facts from the reference
- **scope:** `Graphvix.Attributes.lookup/1`
- **must:** return, as fetched on 2026-11-14 (page modified 2024-07-28): `cluster` → `[:S, :C]`; `color` → `[:C, :N, :E]`; `label` → `[:G, :C, :N, :E]`; `lhead` → `[:E]`; `rank` → `[:S]`; `rankdir` → `[:G]`; `shape` → `[:N]`; and know exactly 176 attributes
- **why:** these are environment facts the warnings Contract's tests rely on; a regeneration that changes them must be reviewed, not absorbed
- **kind:** persisted-format
- **status:** active

### graphvix.attribute_table.I3 — The table names its source
- **scope:** `Graphvix.Attributes.source/0`
- **must:** return the reference page URL, the page's own modification date, and the date the table was generated, as non-empty strings
- **why:** the table lags Graphviz; a reader must be able to see how old it is and where it came from
- **kind:** functional
- **status:** active

### graphvix.attribute_table.I4 — Builds never touch the network
- **scope:** `Graphvix.Attributes`, `Mix.Tasks.Graphvix.Gen.Attributes`, `mix.exs`
- **must:** `Graphvix.Attributes` is compiled from a checked-in file under `lib/`; regeneration happens only when `mix graphvix.gen.attributes` is run by hand; no dependency is added outside `only: :dev` or `only: :test`
- **why:** fetching at compile time would put the network in every build; a hand-run task makes each table change a reviewed diff; the library has no runtime dependencies
- **kind:** non-functional
- **record:** checked-in-attribute-table
- **status:** active

### graphvix.attribute_table.I5 — parse/1 reads the reference table
- **scope:** `Mix.Tasks.Graphvix.Gen.Attributes.parse/1`
- **must:** return one `{name, letters}` row per attribute row of the reference table, in page order, mapping Graphs, Subgraphs, Clusters, Nodes and Edges to `:G`, `:S`, `:C`, `:N` and `:E`
- **why:** the generator's correctness is what keeps I1 true after a regeneration; a saved excerpt of the page pins its parsing
- **kind:** functional
- **status:** active
