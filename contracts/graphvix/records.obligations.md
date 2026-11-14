---
modules:
  - Graphvix.Record
  - Graphvix.HTMLRecord
---

# graphvix.records

## Purpose

Builds the two structured node labels Graphvix supports, carried over from
1.x with the same builders. `Graphvix.Record` builds Graphviz `record`
labels: `new/1`, `row/1`, `column/1`, `to_label/1` (the record syntax,
escaped, without surrounding quotes) and `ports/1`. `Graphvix.HTMLRecord`
builds HTML-like table labels: `new(rows, attrs \\ [])`, `tr/1`,
`td(content, attrs \\ [])`, `br/0`, `font(content, attrs \\ [])`,
`to_label/1` (one line of HTML, without the outer `<` `>`), `ports/1` and
`allowed_attributes/1`. A record is used as the value of a node's `label`
attribute; `graphvix.render` quotes or brackets the result of `to_label/1`
and sets the node's shape.

### graphvix.records.I1 — Record bodies render as 1.x record syntax
- **scope:** `Graphvix.Record.new/1`, `row/1`, `column/1`, `to_label/1`
- **must:** a string body is a single cell and renders as its text (escaped per I3, so a string is never parsed as record syntax); a plain list is a row rendered `"a | b | c"`; `column/1` renders `"{ a | b | c }"`; rows and columns nest to any depth, e.g. `row(["a", column(["b", "c", "d"]), column(["e", "f", row(["g", "h", "i"])])])` renders `"a | { b | c | d } | { e | f | { g | h | i } }"`
- **why:** this is the record label syntax Graphviz reads and the 1.x output; existing users' records must keep their layout
- **kind:** persisted-format
- **status:** active

### graphvix.records.I2 — Port cells render with their port and are listed
- **scope:** `Graphvix.Record.to_label/1`, `Graphvix.Record.ports/1`
- **must:** a cell `{port, text}` renders `"<port> text"`, with both the port and the text escaped per I3; `ports/1` returns every port name in the record, at any depth, in definition order
- **why:** ports let edges attach to a cell; `graphvix.warnings` checks edge ports against `ports/1`
- **kind:** functional
- **status:** active

### graphvix.records.I3 — Record cell text is escaped
- **scope:** `Graphvix.Record.to_label/1`
- **must:** in cell text and port names, double every run of backslashes that comes directly before `{`, `}`, `|`, `<`, `>` or the end of the text, then put a backslash before each `{`, `}`, `|`, `<` and `>`; leave every other backslash as written (`x\{y` → `x\\\{y`, `a>b` → `a\>b`, `line\nbreak` unchanged)
- **why:** 1.x did not escape, so a `|` in cell text silently split the cell; Graphviz's record parser also reads a backslash as escaping the next character, so a caller's backslash before a special character must itself be escaped or the label is rejected ("bad label format"), while `\n` and `\l` must keep working (checked by fuzzing against `dot -Tcanon` 13.0.0)
- **kind:** functional
- **record:** escape-record-text
- **status:** active

### graphvix.records.I4 — Record.new takes only a body
- **scope:** `Graphvix.Record`
- **must:** export `new/1` and no `new/2`; node attributes go on `Graphvix.add_node/3`
- **why:** in 2.0 a record is only a label value; the 1.x second argument (node attributes) has no node to apply to
- **kind:** functional
- **record:** drop-record-attrs
- **status:** active

### graphvix.records.I5 — HTML records render as one line of table markup
- **scope:** `Graphvix.HTMLRecord.to_label/1`, `new/2`, `tr/1`, `td/2`, `br/0`, `font/2`
- **must:** render on a single line with no whitespace between elements: `new([tr([td("a"), td("b")])])` → `<table><tr><td>a</td><td>b</td></tr></table>`; `br()` → `<br/>`; `font(c, attrs)` → `<font ...>c</font>`; cell content may be a string, an element, a list of them, or a nested `HTMLRecord`, which renders in place
- **why:** multi-line HTML (1.x) makes indentation inside nested DOT containers ambiguous; one line has a single pinned form
- **kind:** persisted-format
- **record:** html-single-line
- **status:** active

### graphvix.records.I6 — HTML attributes are hyphenated and quoted
- **scope:** attributes of `new/2`, `td/2`, `font/2`
- **must:** render each attribute as ` name="value"` in the order given, with `_` in names replaced by `-` (`point_size: 100` → `point-size="100"`)
- **why:** Graphviz's HTML attribute names are hyphenated, while Elixir keyword keys use underscores; this is the 1.x behaviour
- **kind:** persisted-format
- **status:** active

### graphvix.records.I7 — HTML text is escaped as entities
- **scope:** `Graphvix.HTMLRecord.to_label/1`
- **must:** escape `&`, `<` and `>` in text content as `&amp;`, `&lt;` and `&gt;`, and `"` in attribute values as `&quot;`
- **why:** 1.x did not escape, so text containing markup characters produced an invalid label that Graphviz rejects
- **kind:** functional
- **status:** active

### graphvix.records.I8 — td ports are listed, including nested tables
- **scope:** `Graphvix.HTMLRecord.td/2`, `Graphvix.HTMLRecord.ports/1`
- **must:** `td(content, port: "p")` renders `port="p"` on that cell; `ports/1` returns every port in the table, including ports in nested tables and a port on the table itself, in definition order
- **why:** edges attach to HTML cells by port; `graphvix.warnings` checks edge ports against `ports/1`
- **kind:** functional
- **status:** active

### graphvix.records.I9 — Allowed HTML attributes are the 1.x lists
- **scope:** `Graphvix.HTMLRecord.allowed_attributes/1`
- **must:** return, as hyphenated strings, for `:table`: align, bgcolor, border, cellborder, cellpadding, cellspacing, color, columns, fixedsize, gradientangle, height, href, id, port, rows, sides, style, target, title, tooltip, valign, width; for `:td`: align, balign, bgcolor, border, cellpadding, cellspacing, color, colspan, fixedsize, gradientangle, height, href, id, port, rowspan, sides, style, target, title, tooltip, valign, width; for `:font`: color, face, point-size
- **why:** `graphvix.warnings` reports attributes outside these lists; they are the lists 1.x documented
- **kind:** functional
- **status:** active
