alias Graphvix.Graph

graph = Graph.new

graph = Graph.set_graph_property(graph, :size, "4,4")

{graph, main} = Graph.add_vertex(graph, "main", shape: "box")
{graph, parse} = Graph.add_vertex(graph, "parse")
{graph, execute} = Graph.add_vertex(graph, "execute")
{graph, init} = Graph.add_vertex(graph, "init")
{graph, cleanup} = Graph.add_vertex(graph, "cleanup")
{graph, make_string} = Graph.add_vertex(graph, "make a\nstring")
{graph, printf} = Graph.add_vertex(graph, "printf")
{graph, compare} = Graph.add_vertex(graph, "compare", shape: "box", style: "filled", color: ".7 .3 1.0")

{graph, _} = Graph.add_edge(graph, main, parse, weight: 8)
{graph, _} = Graph.add_edge(graph, parse, execute)
{graph, _} = Graph.add_edge(graph, execute, compare, color: "red")
{graph, _} = Graph.add_edge(graph, main, init, style: "dotted")
{graph, _} = Graph.add_edge(graph, main, printf, style: "bold", label: "100 times")
{graph, _} = Graph.add_edge(graph, main, cleanup)
{graph, _} = Graph.add_edge(graph, execute, make_string)
{graph, _} = Graph.add_edge(graph, execute, printf)
{graph, _} = Graph.add_edge(graph, init, make_string)

Graph.write(graph, "examples/basic.dot")
