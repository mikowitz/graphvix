alias Graphvix.{Graph, Record, RecordSubset}

graph = Graph.new()

top_record = Record.new([{"f0", "left"}, {"f1", "mid\\ dle"}, {"f2", "right"}])
one_two_record = Record.new([{"f0", "one"}, {"f1", "two"}])
hello_record = Record.new([
  "hello\\nworld",
  Record.column([
    "b",
    Record.row(["c", {"here", "d"}, "e"]),
    "f"
  ]),
  "g",
  "h"
])

{graph, top} = Graph.add_record(graph, top_record)
{graph, one_two} = Graph.add_record(graph, one_two_record)
{graph, hello} = Graph.add_record(graph, hello_record)

{graph, _} = Graph.add_edge(graph, top, one_two)
{graph, _} = Graph.add_edge(graph, top, hello)

Graph.write(graph, "examples/structs.dot")
