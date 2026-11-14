# The contract convention

The Contract is a project's versioned description of what each component must
do, including the non-functional obligations nobody writes down. Code is
regenerable from it: if a component could not be deleted and rebuilt from its
Contract alone, the Contract is missing something. Covenant parses this layout
and enforces it.

Copy this file to your project as `contracts/README.md` and change what you
need. `mix covenant.regen` puts that file in every regeneration pack as
`CONTRACT_CONVENTION.md`, so the agent that rebuilds a component reads the
same rules you wrote it under.

## Layout

```
contracts/
  README.md                      # this convention
  system/
    intent.md                    # whole-product intent: scope, environment facts, cross-cutting invariants
    decisions.yml                # architecture decision records
    scope.yml                    # scope-budget ceilings checked by `mix covenant.check`
  <app>/
    <component>.intent.md        # heavy form
    <component>.obligations.md   # light form, instead of an intent
    <component>.decisions.yml    # records for that component
    <component>.survivors.yml    # sorted survivors of `mix covenant.mutate`
test/contract/<app>/<component>_contract_test.exs   # executable obligations
```

In an umbrella the Contract stays at the root and each app keeps its contract
tests in `apps/<app>/test/contract/`. Point Covenant at them from
`config/config.exs`:

```elixir
config :covenant,
  contracts_dir: Path.expand("../contracts", __DIR__),
  test_paths: ["apps/*/test/contract"]
```

Component ids are `<app>.<component>` in snake_case (`billing.invoices`).
Obligation ids are `<component id>.I<n>` (`billing.invoices.I3`). Ids are
never reused; a retired obligation keeps its number with status `retired`.

Covenant also reads the smaller layout that flinch, qualm and exhale use:
`contract/<primitive>/README.md` with `- **A1**` obligations and a `covers`
block, the Contract tests beside it, and an optional `mutants.md`. A project
can keep either layout or both; the README's "The sibling layout" section
describes it. The rest of this document is about the `contracts/` layout.

## Which form

Heavy form is for components where a regenerated implementation could repeat
a past incident: each obligation cites the learning it protects. Light form is
for everything else. A component moves from light to heavy when its first
production defect lands.

## Heavy form: `<component>.intent.md`

Sections, in this order, with these exact headings. `mix covenant.check`
fails on a missing heading or one out of order.

1. `## Purpose` — one paragraph, then the revision log as a table:
   `| Rev | Date | Change | Driver |`. Every revision answers the previous
   round's regenerator questions.
2. `## Scope` — what the component owns and, as explicitly, what it does not.
3. `## Environment facts` — the compilation target: pinned versions and
   external behaviours the component relies on (the Postgres version, a
   provider's wire format). Each fact names how it is checked.
4. `## Public surface` — every function, message, table, event type, config
   key and persisted format a caller can observe, with types. Persisted
   formats are listed literally; contract tests pin them. A `#### Modules`
   paragraph lists the modules the component owns.
5. `## Invariants` — one block per obligation, in the form below.
6. `## Decisions` — a table `| Decision | Value | Reason | Record |` plus one
   worked example the decisions must reproduce exactly.
7. `## Orderings` — every ordering of side effects that matters, and why.
   Silence on an ordering is a coin flip for a regenerator.
8. `## Known limits` — gaps the Contract deliberately does not hold.
9. `## Regeneration brief` — what a regenerator receives (this intent, the
   records, the contract tests, the public-surface stubs) and the questions
   previous regenerations asked, answered.

### Obligation block

```markdown
### billing.invoices.I3 — Every invoice is a row before the provider is called
- **scope:** `MyApp.Billing.issue/2`, every payment provider
- **must:** insert the `invoices` row with status `draft` before calling the provider; every later failure sets `status` and `reason` on that row
- **why:** v1 called the provider first, and a timeout left a charge with no invoice (incident #2)
- **kind:** functional
- **record:** invoice-row-first
- **status:** active
```

`kind` is one of `functional`, `non-functional`, `persisted-format`,
`ordering`, `security` or `exception`. `status` is `active` or `retired`.
`mix covenant.check` fails when a block lacks any of `scope`, `must`, `why`,
`kind` and `status`, or when `record` names a decision that does not exist.

## Light form: `<component>.obligations.md`

A `## Purpose` paragraph, then obligation blocks with `scope`, `must`, `kind`
and `status` (`why` optional).

Deliberate exceptions, such as intentional duplication or a known gap, are
blocks with `kind: exception` and a `target:` naming the code
(`Module.function/arity`, `Module` or a file path). An exception needs no
test, and the build fails when its target no longer exists.

## Decision records: `<component>.decisions.yml`

```yaml
- id: invoice-row-first           # kebab-case, cited from code comments as `record invoice-row-first`
  date: "2026-10-09"
  decision: One sentence stating the rule or value.
  driver: What forced it — the incident, the number.
  alternatives:
    - option: Call the provider first, record on success
      rejected: Failures become invisible; incident #2.
  evidence: What was measured or read.
  invariant: billing.invoices.I3
  approved_by: lead (2026-10-09)
  conditions:                     # premises; `mix covenant.conditions` re-checks the machine-checkable ones
    - text: Postgres is the invoice store
      check: { kind: dep, name: postgrex }
  expires: When invoices move off Postgres
  source: ["docs/incidents.md#2"]
  # optional: kind (fact | cross-system | known-gap), superseded_by, depends_on, notes
```

What earns a record: a choice that is expensive or dangerous to reverse, a
value that looks arbitrary to a competent stranger (a magic number, a narrow
limit), or a constraint another component quietly depends on. Records are
never deleted; they are superseded.

## Scope ceilings: `system/scope.yml`

A ceiling caps something countable, so the product stays small enough to
regenerate. A `glob` counter counts files; a `module` counter calls a
function of the project.

`contracts/` executes project functions (a `module` counter here, a `value`
check on a decision record) and is trusted input, like `mix.exs`. Covenant
refuses to call a function of Elixir or OTP itself, so `System.halt/0` cannot
end the gate with a success status, but that is a mitigation and not a
sandbox: a project function can still do anything a test can. A `file`
condition or exception target must stay under the project root.

```yaml
- name: billing-modules
  ceiling: 40
  counter: { kind: glob, pattern: "lib/my_app/billing/**/*.ex" }
  why: Billing stays small enough to regenerate in a day.
```

## Contract tests

```elixir
defmodule MyApp.Billing.InvoicesContractTest do
  use Covenant.Case, component: "billing.invoices", async: false

  @tag obligation: "billing.invoices.I3"
  test "a provider timeout still leaves an invoice row with a reason" do
    ...
  end
end
```

Membership test for a contract example: would reimplementing the component in
another language invalidate this assertion? If yes, it is an implementation
test and belongs in `test/<app>/`, not `test/contract/`.

Contract tests resolve file paths from the project root (`Covenant.root/0`,
the directory that holds `contracts/`), never from the directory `mix test`
runs in.

Rules for contract tests:

- Properties over grids (StreamData), not pinned outputs. A pinned example
  fixes one point; a property sweeps a line.
- Persisted formats (table columns, event types, audit keys, prompt block
  order, token prefixes, tool names and descriptions) are environment facts
  and are pinned as literals.
- Decision values (margins, ceilings) are not pinned in tests; the record that
  decides a value verifies it with a `value` condition, and a numeric diff
  against the previous implementation catches drift.
- Every fixture holds a second of everything: two accounts, two users each,
  two sessions.
- Degenerate inputs are mandatory: empty, nil, maximum size, duplicate,
  out of order.
- Non-functional promises are promises: read counts, log levels and latency
  budgets stated in the intent are asserted.
- A stated exclusion needs a positive example: "does X, never Y" tests both.
- Races land the competing write at a precise point (a hook or a clock step),
  never with sleeps.
- Side-effecting components get an interaction recorder: scripted
  collaborators (Mox), a frozen clock, recorded ordered calls, rows before and
  after, emitted events. A recorder is an evaluation and gets the same review
  as the Contract.
- A contract example is never deleted to satisfy a tool.

## Covenant tasks

| Task | Does |
| --- | --- |
| `mix covenant.check` | Parses every intent, obligations file and decision record; fails on malformed blocks, dangling references, an active obligation with no tagged test, a tag naming an unknown obligation, a failing test, a stale exception or a scope ceiling exceeded; prints contract coverage and writes `contracts/coverage.json` |
| `mix covenant.check --static` | The same checks, with nothing compiled and no test run, for a Contract written ahead of its implementation; writes `contracts/coverage.static.json` |
| `mix covenant.conditions` | Re-checks the machine-checkable premises of every record and lists the suspect ones |
| `mix covenant.regen <component>` | Writes a regeneration pack: the intent, records, contract tests, public-surface stubs and the regeneration brief, with the implementation excluded |
| `mix covenant.mutate <component>` | Mutates the component's modules, runs its contract tests against each mutant and writes a kill matrix crediting each kill to the obligations whose tests caught it |

## Process

1. **Inhale.** As a component is discussed and built, register each
   obligation in its intent and each non-obvious value as a record. Write the
   contract test against the intent.
2. **Exhale, in the same pull request.** Coverage never decreases, every
   regenerator question is folded in as an intent sentence, known limits are
   updated and `mix covenant.check` is green.
3. **Gate.** Contract tests, `mix covenant.mutate` on what changed, and a
   review that reads intent, records, contract and code side by side.
4. **Bugs.** A production defect means the Contract was missing something:
   add the obligation, make it executable, prove the new test kills the mutant
   matching the bug, then fix the code.
5. **Fire drill.** Once per milestone, delete one heavy component and
   regenerate it from `mix covenant.regen`; every diff becomes an intent
   sentence.
