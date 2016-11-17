alias Graphvix.{Graph, Node, Edge, Cluster}

Graph.new(:structs)

{top, _} = Node.new(label: "<f0> left|<f1> mid\ dle|<f2> right", shape: "record")
{onetwo, _} = Node.new(label: "<f0> one|<f1> two", shape: "record")
{right, _} = Node.new(label: "hello\\nworld |{b |{c|<here> d|e}| f}| g | h", shape: "record")

Edge.new(top, onetwo)
Edge.new(top, right)

Graph.graph


