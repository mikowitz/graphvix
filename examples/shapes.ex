alias Graphvix.Graph

graph = Graph.new()

graph = Graph.set_graph_property(graph, :size, "4,4")

{graph, a} = Graph.add_vertex(graph, "a", shape: "polygon", sides: 5, peripheries: 3, color: "lightblue", style: "filled")
{graph, b} = Graph.add_vertex(graph, "b")
{graph, c} = Graph.add_vertex(graph, "hello world", shape: "polygon", sides: 4, skew: ".4")
{graph, d} = Graph.add_vertex(graph, "d", shape: "invtriangle")
{graph, e} = Graph.add_vertex(graph, "e", shape: "polygon", sides: 4, distortion: ".7")

{graph, _} = Graph.add_edge(graph, a, b)
{graph, _} = Graph.add_edge(graph, b, c)
{graph, _} = Graph.add_edge(graph, b, d)

Graph.write(graph, "examples/shapes.dot")
