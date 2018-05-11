alias Graphvix.{Graph, HTMLRecord}
import Graph.HTMLRecord, only: [tr: 1, td: 1, td: 2]

graph = Graph.new()

top_record = HTMLRecord.new([
  tr([
    td("left", port: "f0"),
    td("mid dle", port: "f1"),
    td("right", port: "f2"),
  ])
], border: 0, cellborder: 1, cellspacing: 0)

one_two_record = HTMLRecord.new([
  tr([
    td("one", port: "f0"),
    td("two", port: "f1")
  ])
], border: 0, cellborder: 1, cellspacing: 0)

hello_record = HTMLRecord.new([
  tr([
    td("hello<br/>world", rowspan: 3),
    td("b", colspan: 3),
    td("g", rowspan: 3),
    td("h", rowspan: 3)
  ]),
  tr([
    td("c"),
    td("d", port: "here"),
    td("e")
  ]),
  tr([
    td("f", colspan: 3)
  ])
], border: 0, cellborder: 1, cellspacing: 0)

{graph, top} = Graph.add_html_record(graph, top_record)
{graph, one_two} = Graph.add_html_record(graph, one_two_record)
{graph, hello} = Graph.add_html_record(graph, hello_record)

{graph, _} = Graph.add_edge(graph, {top, "f1"}, {one_two, "f0"})
{graph, _} = Graph.add_edge(graph, {top, "f2"}, {hello, "here"})

Graph.write(graph, "examples/html_records.dot")
