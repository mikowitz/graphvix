alias Graphvix.{Graph, Node, Edge, Cluster}

Graph.restart
Graph.update(size: "4,4")

a = Node.new(label: "a", shape: "polygon", sides: 5, peripheries: 3, color: "lightblue", style: "filled")
b = Node.new(label: "b")
c = Node.new(label: "hello world", shape: "polygon", sides: 4, skew: ".4")
d = Node.new(label: "d", shape: "invtriangle")
e = Node.new(label: "e", shape: "polygon", sides: 4, distortion: ".7")

Edge.new(a, b)
Edge.new(b, c)
Edge.new(b, d)

Graph.graph
