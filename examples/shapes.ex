alias Graphvix.{Graph, Node, Edge, Cluster}

Graph.restart
Graph.update(size: "4,4")

{a, _} = Node.new(label: "a", shape: "polygon", sides: 5, peripheries: 3, color: "lightblue", style: "filled")
{b, _} = Node.new("b")
{c, _} = Node.new(label: "hello world", shape: "polygon", sides: 4, skew: ".4")
{d, _} = Node.new(label: "d", shape: "invtriangle")
{e, _} = Node.new(label: "e", shape: "polygon", sides: 4, distortion: ".7")

Edge.chain([a, b, c])
Edge.new(b, d)

Graph.graph
