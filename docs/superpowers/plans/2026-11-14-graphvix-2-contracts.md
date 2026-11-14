# Graphvix 2.0 Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Write the complete Covenant Contract for Graphvix 2.0 — intents/obligations, decision records, scope ceilings and executable contract tests — ahead of any 2.0 implementation.

**Architecture:** Five components under `contracts/graphvix/` (`builder`, `records`, `render`, `warnings`, `attribute_table`), plus `contracts/system/`. Each component task follows a red/green cycle against `mix covenant.check --static`: write the obligations (check fails: active obligations with no tagged test), then write the tagged contract tests (check passes). Contract tests compile but fail at runtime until 2.0 is implemented — that is expected and is the point.

**Tech Stack:** Elixir ~> 1.20, Covenant 0.2 (`Covenant.Case`, `mix covenant.check --static`), ExUnit, StreamData, Graphviz `dot` 13.0.0 for `:graphviz`-tagged tests.

**Spec:** `docs/superpowers/specs/2026-11-13-graphvix-2-contracts-design.md` — read it in full before any task. Every obligation below traces to a section of it; where this plan and the spec seem to disagree, the spec wins and you stop and ask.

## Global Constraints

- Layout per `contracts/README.md` (Covenant convention): `contracts/graphvix/<component>.{obligations,intent}.md`, `contracts/graphvix/<component>.decisions.yml`, `test/contract/graphvix/<component>_contract_test.exs`. Covenant's defaults (`contracts_dir: "contracts"`, `test_paths: ["test/contract"]`) are used; no config.
- Component ids: `graphvix.builder`, `graphvix.records`, `graphvix.render`, `graphvix.warnings`, `graphvix.attribute_table`. Obligation ids `<component id>.I<n>`, numbered from 1, never reused.
- Every obligation block has `scope`, `must`, `why`, `kind`, `status: active` (light form too — include `why` everywhere). `kind` ∈ `functional | non-functional | persisted-format | ordering | security | exception`.
- Decision records require `id, date, decision, driver, approved_by`; use `date: "2026-11-14"`, `approved_by: mikowitz (2026-11-14)`; add `alternatives` and `invariant` where the spec gives them.
- Every intent/obligations file opens with YAML front matter listing the modules it owns (`modules: [...]`). Module ownership:
  - builder: `Graphvix`, `Graphvix.Graph`, `Graphvix.Node`, `Graphvix.Edge`, `Graphvix.Subgraph`, `Graphvix.Cluster`
  - records: `Graphvix.Record`, `Graphvix.HTMLRecord`
  - render: `Graphvix.Render` (`Graphvix.to_dot/1`, `write/2`, `compile/3` delegate to it)
  - warnings: `Graphvix.Warnings` (`Graphvix.warnings/1` delegates to it)
  - attribute_table: `Graphvix.Attributes`, `Mix.Tasks.Graphvix.Gen.Attributes`
- Contract tests:
  - `use Covenant.Case, component: "<id>", async: true` (`async: false` only where a test changes `PATH` or captures logs globally).
  - Every `test`/`property` carries a literal `@tag obligation: "<id>"` (or a literal list). Never generate tests in `for`/`Enum.each` — Covenant cannot credit them statically.
  - Use only the public API. **No struct literals or struct patterns** (`%Graphvix.Graph{}`) — 1.x modules with the same names exist and would fail compilation; read fields with `graph.nodes` etc.
  - Persisted formats (DOT text, warning tuple shapes) are pinned as literals. Properties (StreamData) wherever a property fits.
  - Tests that run `dot` carry `@tag :graphviz`.
- Test names use spaces, not underscores.
- Do not modify `lib/` or the 1.x tests. Do not touch the root file `ok`.
- Commit after each task; end commit messages with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Shared vocabulary (used by every task)

- `path`: list of **emitted** container names from the root, e.g. `["cluster_outer", "s1", "cluster_inner"]`; `[]` is the root.
- Endpoint: `id | {id, port} | {id, port, compass}`; `{id, nil, compass}` is compass-only. Compass atoms: `:n :ne :e :se :s :sw :w :nw :c :_`.
- Warning tuples (pinned, from the spec's "Calls I made"):
  `{:unknown_attribute, target, key}`, `{:unsupported_attribute, target, key}`,
  `{:multiple_clusters, node_id, kept: path, ignored: [path]}`,
  `{:nested_clusters, node_id, placed: path, also: [path]}`,
  `{:duplicate_name, name, [path]}`, `{:unknown_port, {from, to}, node_id, port}`,
  `{:record_shape, node_id, shape}`, `{:unknown_html_attribute, node_id, element, key}`,
  `{:conflicting_attribute, node_id, key, winner: {path, value}, others: [{path, value}]}`,
  `{:record_label_misplaced, target}`, `{:invalid_compass_point, {from, to}, node_id, value}`.
  `target` ∈ `:graph | {:subgraph, path} | {:cluster, path} | {:node, id} | {:edge, from, to} | {:node_default, path} | {:edge_default, path}`; `key` is a string.

## Review Focus

1. Node ids, ports and labels containing `"`, `\`, newlines, or DOT keywords (`node`, `edge`, `graph`, `strict`, `subgraph`) — expect valid DOT that `dot` parses, with the text preserved. → Task 4, test "hostile ids and labels still parse in dot".
2. Empty graph and empty containers — expect `digraph G {\n}\n` and an empty cluster rendering as an opening line and bare `}` at the right indent. → Task 4, test "empty graph and empty cluster".
3. Deep nesting (50 levels) — expect correct 2-space indentation at every level and no crash. → Task 4, test "deep nesting indents two spaces per level".
4. Mixed attribute key types and container types (`[color: "red"]` then `%{"color" => "blue"}`) — expect one `"color"` key, value `"blue"`. → Task 2, test "atom and string keys name the same attribute across keyword lists and maps".
5. Edges whose endpoints were never added, in a graph with clusters — expect no warning and the implicit node at the root. → Task 5, test "edges to undeclared nodes neither warn nor anchor".

---

### Task 1: Contracts scaffold and system contract

**Files:**
- Move: `contract/README.md` → `contracts/README.md`; delete `contract/` (incl. `contract/coverage.json`)
- Create: `contracts/system/intent.md`, `contracts/system/decisions.yml`, `contracts/system/scope.yml`
- Modify: `test/test_helper.exs`
- Commit also: the existing uncommitted changes to `mix.exs`, `mix.lock`, `test/test_helper.exs` (Covenant dependency + formatter)

**Interfaces:**
- Produces: `:graphviz` tag excluded automatically when `dot` is not on `PATH`; system records `immutable-graph`, `warnings-not-errors`, `edges-root-only`, `contract-first` that later tasks may cite in `depends_on`.

- [ ] **Step 1: Move the convention README** — `git mv contract/README.md contracts/README.md`, `git rm contract/coverage.json`.
- [ ] **Step 2: Write `contracts/system/intent.md`** — prose only, no obligation blocks: whole-product intent (spec "Intent", "Goals", "Non-goals", "Anti-goals"), environment facts (Elixir `~> 1.20`; Graphviz `dot` 13.0.0 (20250608.1624), checked by `dot -V` in the `:graphviz` suite; no runtime dependencies, checked by reading `mix.exs`), cross-cutting invariants (immutability, warnings never raise or fail output), and the component map table from the spec.
- [ ] **Step 3: Write `contracts/system/decisions.yml`** with records `immutable-graph` (no `:digraph`/ETS; driver: 1.x shared mutable ETS state), `warnings-not-errors`, `edges-root-only` (driver: edge statements in a cluster pull endpoints into it), `contract-first`. Alternatives and drivers from the spec.
- [ ] **Step 4: Write `contracts/system/scope.yml`** — one ceiling: `graphvix-lib-files`, `ceiling: 20`, `counter: { kind: glob, pattern: "lib/**/*.ex" }`, `why: Small enough to regenerate one component in a sitting.`
- [ ] **Step 5: Update `test/test_helper.exs`**:
  ```elixir
  exclude = if System.find_executable("dot"), do: [], else: [:graphviz]
  ExUnit.start(formatters: [ExUnit.CLIFormatter, Covenant.Formatter], exclude: exclude)
  ```
- [ ] **Step 6: Verify** — `mix covenant.check --static`. Expected: exits 0, zero components with obligations, no parse errors.
- [ ] **Step 7: Commit** — `git add mix.exs mix.lock test/test_helper.exs contracts/` then `git commit -m "Scaffold Graphvix 2.0 contracts"`.

---

### Task 2: `graphvix.builder` (light form)

**Files:**
- Create: `contracts/graphvix/builder.obligations.md`, `contracts/graphvix/builder.decisions.yml`, `test/contract/graphvix/builder_contract_test.exs`

**Interfaces:**
- Produces (public surface every later task's tests use):
  - `Graphvix.new(opts \\ []) :: graph` — opts `digraph: boolean`, `strict: boolean`
  - `Graphvix.add_node(graph, id, attrs \\ [])`, `add_edge(graph, from, to, attrs \\ [])`, `add_subgraph(graph, subgraph)`, `add_cluster(graph, cluster)`, `set_attributes(graph, :graph | :node | :edge, attrs)` — all return a graph
  - `Graphvix.Subgraph.new(id)`, `Graphvix.Cluster.new(id)`; each module has `add_node/3`, `add_subgraph/2`, `add_cluster/2`, `set_attributes(struct, :graph | :node, attrs)` returning its own struct type; neither exports `add_edge`
  - Fields: graph `digraph, strict, nodes, edges, subgraphs, clusters, attributes` (`%{graph: %{}, node: %{}, edge: %{}}`); node `id, attributes`; edge `from, to, attributes`; subgraph/cluster `id, nodes, subgraphs, clusters, attributes` (`%{graph: %{}, node: %{}}`)
  - `attrs` is a keyword list or a map; stored keys are strings

- [ ] **Step 1: Write `builder.obligations.md`** — `## Purpose`, then these blocks (`must` text from the spec sections "Public API", "Structs", "Node identity and merging", "Edges", "Attributes"):
  - I1 `new/1` defaults (`digraph: true`, `strict: false`, empty lists, three empty attribute maps) and option overrides — functional
  - I2 Every construction function returns a new value and leaves its input unchanged — non-functional (record `immutable-graph`)
  - I3 Ids given as string/atom/number are stored as strings; `:a`, `"a"` name one node; subgraph/cluster ids likewise — functional
  - I4 Re-adding a node id in the same container merges: one entry at its first position, later attribute values win — functional (record `same-container-merge`)
  - I5 `nodes`, `edges`, `subgraphs`, `clusters` keep definition order — ordering
  - I6 Edges: endpoints stored normalized (ids to strings, port strings, compass atoms as given); repeated edges kept separately; endpoints need not be added nodes; no `label` field — functional
  - I7 Attribute keys may be atoms or strings, from keyword lists or maps, stored as strings; `set_attributes` merges with later values winning — functional
  - I8 Subgraph/Cluster builders return their own struct type, nest arbitrarily, apply I3–I5 and I7 within themselves; `set_attributes` accepts `:graph | :node` only (`:edge` raises `FunctionClauseError` — an API misuse, not a questionable attribute) — functional
  - I9 Re-adding a subgraph/cluster with an existing id appends a second entry (no merge) — functional
  - I10 Occurrences of one node id across containers are all kept exactly as built — functional (record `keep-cross-container-occurrences`)
  - I11 Exclusion: Subgraph and Cluster export no `add_edge`; edges only live on the graph — functional (system record `edges-root-only`)
- [ ] **Step 2: Write `builder.decisions.yml`** — records `same-container-merge` (alternatives replace / keep-both, rejected per spec), `keep-cross-container-occurrences`, `string-attribute-keys` (driver: atom and string keys must merge; no atoms from user input).
- [ ] **Step 3: Run `mix covenant.check --static`** — Expected: FAIL listing `graphvix.builder.I1`…`I11` as active with no tagged test.
- [ ] **Step 4: Write `builder_contract_test.exs`** — one or more tests per obligation, e.g.:
  - I1 "new graph has documented defaults"; "options override digraph and strict"
  - I2 property "construction never changes its input" — generate a sequence of ops, apply each, assert the prior value is `==` to a copy taken before
  - I3 "atom string and integer ids name the same node" — `add_node(:a) |> add_node("a")` → one node with `id == "a"`
  - I4 "re-adding a node merges and keeps first position" — add `a`(color red), `b`, `a`(shape box) → ids `["a","b"]`, `a` attributes `%{"color" => "red", "shape" => "box"}`; later value wins on clash
  - I5 property "lists keep definition order" — random distinct ids → `Enum.map(g.nodes, & &1.id)` equals input order
  - I6 "edges normalize endpoints and allow repeats and undeclared nodes" — `add_edge(:a, {"b", "p1"})`, `add_edge("a", {"b", "p1", :ne})`, same edge twice → 3 edges, `from == "a"`, `to == {"b","p1"}`, `{"b","p1",:ne}`; `g.nodes == []`; edge map has no `:label` key
  - I7 "atom and string keys name the same attribute across keyword lists and maps" (Review Focus 4)
  - I8 "clusters nest and return their own type"; "set_attributes on a cluster rejects :edge"
  - I9 "re-adding a cluster id appends"
  - I10 "a node in two containers is kept in both"
  - I11 "subgraphs and clusters cannot hold edges" — `refute function_exported?(Graphvix.Cluster, :add_edge, 3)` and `4`; same for Subgraph (call `Code.ensure_loaded/1` first)
- [ ] **Step 5: Run `mix covenant.check --static`** — Expected: PASS, builder 11/11 covered.
- [ ] **Step 6: Run `mix test test/contract/graphvix/builder_contract_test.exs`** — Expected: compiles; tests fail (2.0 not implemented). Any compile error is a bug in the test.
- [ ] **Step 7: Commit** — "Add graphvix.builder contract".

---

### Task 3: `graphvix.records` (light form)

**Files:**
- Create: `contracts/graphvix/records.obligations.md`, `contracts/graphvix/records.decisions.yml`, `test/contract/graphvix/records_contract_test.exs`

**Interfaces:**
- Produces:
  - `Graphvix.Record.new(body)`, `row(cells)`, `column(cells)`, `to_label(record) :: String.t()` (record syntax, unquoted, escaped), `ports(record) :: [String.t()]`
  - `Graphvix.HTMLRecord.new(rows, attrs \\ [])`, `tr/1`, `td/2`, `br/0`, `font/2`, `to_label(record) :: String.t()` (single line, without the outer `<` `>`), `ports(record) :: [String.t()]` (including nested tables), `allowed_attributes(:table | :td | :font) :: [String.t()]` (the 1.x lists in `lib/graphvix/html_record.ex`)

- [ ] **Step 1: Write `records.obligations.md`**:
  - I1 Record bodies: string; plain list = row `"a | b"`; `column` = `"{ a | b }"`; nested alternation as 1.x (`"a | { b | c | d } | { e | f | { g | h | i } }"`) — persisted-format
  - I2 Port cells `{port, text}` render `"<port> text"`; `ports/1` lists every port in definition order — functional
  - I3 Record cell text escapes `{ } | < >` with a backslash (1.x did not) — functional (record `escape-record-text`)
  - I4 `Record.new/1` only — the 1.x attributes argument is dropped — functional (record `drop-record-attrs`)
  - I5 HTML structure: `<table ...><tr><td ...>…</td></tr></table>` on one line; `br` → `<br/>`; `font` → `<font ...>…</font>`; tables nest in cells — persisted-format (record `html-single-line`)
  - I6 HTML attribute names hyphenated (`point_size` → `point-size`), values double-quoted, in given order — persisted-format
  - I7 HTML text escapes `&`, `<`, `>` as `&amp;` `&lt;` `&gt;` — functional
  - I8 `td(…, port: "p")` defines a port; `HTMLRecord.ports/1` finds ports in nested tables — functional
  - I9 `allowed_attributes/1` returns the 1.x lists for table, td, font — functional
- [ ] **Step 2: Write `records.decisions.yml`** — `escape-record-text`, `drop-record-attrs` (alternative: merge into node, rejected by user), `html-single-line` (driver: multi-line HTML makes indentation inside nested containers ambiguous).
- [ ] **Step 3: Run `mix covenant.check --static`** — Expected: FAIL, records I1–I9 untested.
- [ ] **Step 4: Write `records_contract_test.exs`** — port the 1.x record properties from `test/graphvix/record_test.exs` to the new API (I1); pinned literals for I2, I5, I6 (e.g. `font("B", color: "red", point_size: 100)` → `~s(<font color="red" point-size="100">B</font>)`); property for I3 "record cell text never leaves a special character unescaped" (generate strings over `[?a, ?{, ?}, ?|, ?<, ?>, ?\s]`; assert every special char in output is preceded by `\`); I4 `refute function_exported?(Graphvix.Record, :new, 2)`; I7 `td("a & <b>")` → contains `a &amp; &lt;b&gt;`; I8 nested table port found; I9 lists equal the 1.x doc lists, as strings.
- [ ] **Step 5: Run `mix covenant.check --static`** — Expected: PASS.
- [ ] **Step 6: Run `mix test test/contract/graphvix/records_contract_test.exs`** — Expected: compiles, fails.
- [ ] **Step 7: Commit** — "Add graphvix.records contract".

---

### Task 4: `graphvix.render` (heavy form)

**Files:**
- Create: `contracts/graphvix/render.intent.md`, `contracts/graphvix/render.decisions.yml`, `test/contract/graphvix/render_contract_test.exs` (the `dot` helpers are private functions in this test module)

**Interfaces:**
- Consumes: Task 2 builders, Task 3 `to_label/1`.
- Produces: `Graphvix.to_dot(graph) :: String.t()`, `Graphvix.write(graph, basename) :: :ok | {:error, term}`, `Graphvix.compile(graph, basename, format \\ :png) :: {:ok, Path.t()} | {:error, term}`; logging contract used by Task 5 (each warning logged once via `Logger.warning`).

- [ ] **Step 1: Write `render.intent.md`** with the nine headings in order: `## Purpose` (+ revision table, Rev 1 2026-11-14, driver "2.0 contract-first"), `## Scope` (owns DOT text, files, invoking `dot`; does not own deciding warnings), `## Environment facts` (Graphviz 13.0.0; `dot` accepts `"a":"p1":ne`; `node [...]` defaults apply only to nodes created after them — verified with `dot -Tcanon`; each checked by a `:graphviz` test), `## Public surface` (signatures above, `#### Modules` `Graphvix.Render`), `## Invariants`, `## Decisions` (table + the spec's pinned worked example **verbatim**), `## Orderings` (statement order; definition order; warnings logged before output is returned), `## Known limits` (no attribute-value validation; `lhead`/`ltail` need full `cluster_<id>`; HTML elements beyond 1.x set), `## Regeneration brief`.
  Invariants:
  - I1 Header `digraph G {` / `graph G {`, `strict ` prefix when strict — persisted-format
  - I2 Statement kind order per container: graph attrs, `node` defaults, `edge` defaults (root), subgraphs, clusters, own nodes, edges (root) — ordering (record `containers-before-nodes`)
  - I3 Definition order within each kind, merged node at first position, at every depth — ordering
  - I4 Whitespace: 2 spaces per level, no tabs, one statement per line, `;` ends every statement, blocks close with bare `}`, no blank lines, one trailing newline — persisted-format (record `semicolons-everywhere`)
  - I5 Attribute lists `[k="v", k2="v2"]`, keys sorted, omitted when empty; graph attributes as `k="v";` lines sorted; empty maps emit nothing — persisted-format (record `sorted-attribute-keys`)
  - I6 Quoting: ids, names, ports and string values double-quoted; `"` escaped; `\` preserved except an odd trailing run gains one — security (record `backslash-preserved`)
  - I7 Names: subgraph id verbatim; cluster always `cluster_<id>` — persisted-format (record `cluster-prefix-always`)
  - I8 Edge operator `->`/`--`; endpoints `"a"`, `"a":"p"`, `"a":"p":ne`, `"a":ne`; invalid compass omitted — persisted-format
  - I9 Labels: `Record` → `label="<to_label, quote-escaped>"`; `HTMLRecord` → `label=<…>` on any element — persisted-format
  - I10 Auto-shape `record` / `plaintext` from the node's **own** label unless the node's own attributes set `shape`; defaults never trigger it — functional (record `html-plaintext-shape`)
  - I11 Numbers, atoms, booleans rendered via `to_string` and quoted — functional
  - I12 Attribute values are never rewritten (`lhead: "cluster_x"` emitted as given) — functional (record `values-never-rewritten`)
  - I13 `to_dot`/`write`/`compile` log every `Graphvix.warnings/1` entry exactly once per call at `:warning` and still return output; no warnings → no log — non-functional
  - I14 `write/2` writes `basename.dot` equal to `to_dot/1`; returns `:ok | {:error, reason}` — functional
  - I15 `compile/3` writes `basename.dot` and `basename.<format>`, returns `{:ok, "basename.<format>"}`; `{:error, reason}` (never raises) when `dot` is missing or exits non-zero — functional
  - I16 Rendered output is valid DOT that `dot` parses, for any graph the builders can make — functional
- [ ] **Step 2: Write `render.decisions.yml`** — `containers-before-nodes` (driver: cluster defaults silently missed root-declared nodes; alternatives: warn only, known limit — rejected by user), `semicolons-everywhere`, `sorted-attribute-keys`, `backslash-preserved` (driver: `\n`, `\l`, `\N`; trailing-backslash hole), `cluster-prefix-always`, `html-plaintext-shape` (1.x parity), `values-never-rewritten`, `graph-named-g`.
- [ ] **Step 3: Run `mix covenant.check --static`** — Expected: FAIL, render I1–I16 untested.
- [ ] **Step 4: Write `render_contract_test.exs`**. Required tests (plus at least one per obligation):
  - I1–I9, I4 "pinned worked example renders exactly" — build the spec's example with the builders and assert `to_dot` equals the literal (heredoc) byte for byte.
  - I2 "cluster node defaults reach root-declared nodes" — `@tag :graphviz`: cluster with `node [color=red]` containing `a`, root also adds `a`; `dot -Tcanon` output shows `a` red (or `-Tjson` node `color`).
  - I3 property "definition order survives merges and nesting".
  - I4 "empty graph and empty cluster" (Review Focus 2): `Graphvix.new() |> to_dot == "digraph G {\n}\n"`; graph with empty cluster `x` == `"digraph G {\n  subgraph \"cluster_x\" {\n  }\n}\n"`.
  - I4 "deep nesting indents two spaces per level" (Review Focus 3): 50 nested clusters; the line for depth *n* starts with exactly `2*n` spaces; `refute output =~ "\t"`.
  - I6 "trailing backslash cannot escape the closing quote" — label `"foo\\"` → `label="foo\\\\"`; `"a\\nb"` preserved as `"a\\nb"`.
  - I6/I16 "hostile ids and labels still parse in dot" (Review Focus 1), `@tag :graphviz` — ids `~s(say "hi")`, `"node"`, `"strict"`, `"line\nbreak"`; `dot -Tjson` succeeds and node names round-trip.
  - I8 one test per endpoint form incl. `{"a", nil, :ne}` → `"a":ne` and `{"a","p",:bogus}` → `"a":"p"`.
  - I13 `ExUnit.CaptureLog` — a graph with exactly two warnings logs exactly two warning lines per `to_dot` call; a clean graph logs nothing.
  - I14/I15 use `System.tmp_dir!/0` + unique basename; I15 "compile without dot returns an error" sets `PATH` to an empty dir for the call (`async: false` module) and restores it in `on_exit`.
  - I16 property `@tag :graphviz` "any built graph is valid DOT" — StreamData generator of nested graphs with random ids/attrs/records; write `to_dot` output to a temp file and run `System.cmd("dot", ["-Tcanon", file], stderr_to_stdout: true)`; assert exit 0. Cap `max_runs: 50`.
- [ ] **Step 5: Run `mix covenant.check --static`** — Expected: PASS; also passes the heavy-form heading check.
- [ ] **Step 6: Run `mix test test/contract/graphvix/render_contract_test.exs`** — Expected: compiles, fails.
- [ ] **Step 7: Commit** — "Add graphvix.render contract".

---

### Task 5: `graphvix.warnings` (heavy form)

**Files:**
- Create: `contracts/graphvix/warnings.intent.md`, `contracts/graphvix/warnings.decisions.yml`, `test/contract/graphvix/warnings_contract_test.exs`

**Interfaces:**
- Consumes: Tasks 2–3; `Graphvix.Attributes.lookup/1` (Task 6); `Graphvix.Record.ports/1`, `Graphvix.HTMLRecord.ports/1`, `allowed_attributes/1`.
- Produces: `Graphvix.warnings(graph) :: [warning]` with the tuple shapes in "Shared vocabulary".

- [ ] **Step 1: Write `warnings.intent.md`** (nine headings). Environment facts: Graphviz placement rules, each with how it's checked (`:graphviz` tests): first cluster wins among unrelated clusters; a later descendant occurrence moves a node deeper; a later ancestor occurrence keeps it; subgraphs named `cluster*` (any case) or with `cluster=true` are clusters; in `-Tjson`, a cluster's `nodes` lists nodes placed in it or any descendant, so placement = deepest cluster listing the node. Decisions section: worked example = the spec's `a…g` example with its two expected warnings as literal tuples. Invariants:
  - I1 Pure and deterministic: no logging, no I/O, same graph → same list; order = render-order walk — non-functional
  - I2 `:unknown_attribute` for keys absent from the attribute table — functional
  - I3 `:unsupported_attribute` using G (root graph attrs), S (subgraph), C (cluster), N (node attrs and `node` defaults), E (edge attrs and `edge` defaults) — functional
  - I4 `:multiple_clusters` with `kept`/`ignored` per the placement rules — functional (record `placement-model`)
  - I5 `:nested_clusters` with `placed`/`also` — functional (record `warn-nested-membership`)
  - I6 Exclusions: root occurrences never warn or anchor; plain subgraphs are transparent; edges to undeclared nodes never warn — functional
  - I7 Cluster-like subgraphs (`cluster*` any case, `cluster=true`) count as clusters for I4/I5 — functional
  - I8 `:duplicate_name` compares emitted names (`Subgraph` `cluster_x` clashes with `Cluster` `x`; `Subgraph` `x` does not clash with `Cluster` `x`) — functional
  - I9 `:unknown_port` — port absent from every occurrence's own `Record`/`HTMLRecord` label (incl. nodes without one); compass-only endpoints never checked — functional
  - I10 `:record_shape` — `Record` label with own `shape` not `record`/`Mrecord`; never for `HTMLRecord` — functional
  - I11 `:unknown_html_attribute` against `allowed_attributes/1` — functional
  - I12 `:conflicting_attribute` — same node, same key, different explicit values in different containers; `winner` = last in render order — functional
  - I13 `:record_label_misplaced` — `Record` as edge/graph/subgraph/cluster label or in a `node` default — functional
  - I14 `:invalid_compass_point` — functional
  - I15 Warning tuple shapes are pinned literally — persisted-format
  - I16 Placement agrees with Graphviz — functional
- [ ] **Step 2: Write `warnings.decisions.yml`** — `placement-model` (evidence: `dot -Tjson` runs on 13.0.0 recorded in the spec), `warn-nested-membership` (Graphviz silent; usually unintentional), `cluster-like-subgraphs`, `emitted-name-duplicates`, `conflict-winner-render-order`, `warning-tuple-shapes`. `placement-model` gets one condition, `text: Graphviz 13.x placement semantics`, with no `check:` (the `:graphviz` property is its check).
- [ ] **Step 3: Run `mix covenant.check --static`** — Expected: FAIL, warnings I1–I16 untested.
- [ ] **Step 4: Write `warnings_contract_test.exs`**. Required tests:
  - I4/I5/I15 "worked example yields exactly the two documented warnings" — build the spec's `a…g` example with cluster ids `"1"`, `"2"`, `"3"` (emitted `cluster_1`…); `warnings == [{:multiple_clusters, "a", kept: ["cluster_1"], ignored: [["cluster_2", "cluster_3"]]}, {:nested_clusters, "c", placed: ["cluster_2", "cluster_3"], also: [["cluster_2"]]}]`. Use the same ids and literals in the intent's worked example.
  - I1 property "warnings are deterministic and silent" — same graph twice → equal lists; `capture_log` empty.
  - I3 one test per target letter, e.g. `set_attributes(g, :graph, rank: "same")` → `{:unsupported_attribute, :graph, "rank"}`; `rank` on a subgraph → none.
  - I6 "root plus one cluster never warns"; "a node only in plain subgraphs never warns"; "edges to undeclared nodes neither warn nor anchor" (Review Focus 5).
  - I7 subgraph ids `"clusterfoo"`, `"Cluster_z"`, and `cluster: true` each produce `:multiple_clusters` when sharing a node with another cluster.
  - I8 both clash and non-clash cases.
  - I9/I10/I11/I12/I13/I14 one positive and one negative example each.
  - I16 `@tag :graphviz` property "placement agrees with dot -Tjson" — generate nested cluster trees (≤4 levels, ≤6 nodes, nodes reused across containers); render with `to_dot`, run `dot -Tjson`, compute dot placement (deepest cluster whose `nodes` contains the node's `_gvid`); expected placement: `kept`/`placed` from that node's warning, else the deepest cluster path among its occurrences, else root. Assert equal for every node. `max_runs: 50`.
- [ ] **Step 5: Run `mix covenant.check --static`** — Expected: PASS.
- [ ] **Step 6: Run `mix test test/contract/graphvix/warnings_contract_test.exs`** — Expected: compiles, fails.
- [ ] **Step 7: Commit** — "Add graphvix.warnings contract".

---

### Task 6: `graphvix.attribute_table` (light form)

**Files:**
- Create: `contracts/graphvix/attribute_table.obligations.md`, `contracts/graphvix/attribute_table.decisions.yml`, `test/contract/graphvix/attribute_table_contract_test.exs`, `test/fixtures/graphviz_attrs_excerpt.html`

**Interfaces:**
- Produces: `Graphvix.Attributes.lookup(name :: String.t()) :: {:ok, [:G | :S | :C | :N | :E]} | :error`; `Graphvix.Attributes.source() :: %{url: String.t(), graphviz_version: String.t(), generated_on: String.t()}`; `Mix.Tasks.Graphvix.Gen.Attributes.parse(html :: String.t()) :: [{String.t(), [atom]}]`.

- [ ] **Step 1: Fetch https://graphviz.org/doc/info/attrs.html** and save a short excerpt (the table header plus the rows for `cluster`, `color`, `label`, `lhead`, `rank`, `rankdir`, `shape`) as the fixture. Record the exact "Used By" letters for those seven attributes — they become the pinned facts in Step 4.
- [ ] **Step 2: Write `attribute_table.obligations.md`**:
  - I1 `lookup/1` returns the Graphviz "used by" letters for every attribute on the reference page; unknown names (incl. wrong case) return `:error` — functional
  - I2 Pinned facts for the seven attributes above — persisted-format (environment facts)
  - I3 `source/0` names the page URL, Graphviz doc version and generation date — functional
  - I4 The table is a checked-in module; building and testing never touch the network; regeneration is the dev-only mix task — non-functional (record `checked-in-attribute-table`)
  - I5 `parse/1` on the fixture yields exactly the fixture's rows — functional
- [ ] **Step 3: Write `attribute_table.decisions.yml`** — `checked-in-attribute-table` (alternatives: fetch at compile time — rejected, network in builds; hand-maintained list — rejected, drifts).
- [ ] **Step 4: Write the tests** — I1 property over a few known names plus `"colour"` / `"Color"` → `:error`; I2 literal assertions from Step 1; I3 keys present and non-empty; I4 "attribute lookup works with the network unavailable" is not testable directly — instead assert `Graphvix.Attributes` is compiled from a file under `lib/` (`Graphvix.Attributes.module_info(:compile)[:source]` ends with `.ex` under `lib/`) and that `mix.exs` declares no runtime deps; I5 fixture parse equals the Step 1 literal list.
- [ ] **Step 5: Run `mix covenant.check --static`** — Expected: PASS for all five components.
- [ ] **Step 6: Run `mix test test/contract`** — Expected: compiles; contract tests fail (no 2.0 yet); 1.x tests in `test/graphvix/` still pass.
- [ ] **Step 7: Commit** — "Add graphvix.attribute_table contract".

---

### Task 7: Final gate

- [ ] **Step 1:** `mix covenant.check --static` — Expected: exit 0, coverage 100% of active obligations, `contracts/coverage.static.json` written. Commit that file.
- [ ] **Step 2:** `mix covenant.regen graphvix.render` and `graphvix.warnings` into the scratchpad — read each pack as a regenerator would; every question it raises becomes a sentence in that intent's `## Regeneration brief` (answered) or a spec question for the user (stop and ask).
- [ ] **Step 3:** `mix format --check-formatted` and `mix credo` on `test/contract` — Expected: clean.
- [ ] **Step 4: Commit** — "Complete Graphvix 2.0 contract".
