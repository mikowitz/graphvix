alias Graphvix.{Graph, Node, Edge, Cluster}

Graph.restart
Graph.update(size: "4,4")
main = Node.new(label: "main")
parse = Node.new(label: "parse")
execute = Node.new(label: "execute")
init = Node.new(label: "init")
cleanup = Node.new(label: "cleanup")
make_string = Node.new(label: "make_string")
printf = Node.new(label: "printf")
compare = Node.new(label: "compare")

main_parse = Edge.new(main, parse)
Edge.new(parse, execute)
main_init = Edge.new(main, init)
Edge.new(main, cleanup)
Edge.new(execute, make_string)
Edge.new(execute, printf)
Edge.new(init, make_string)
main_print = Edge.new(main, printf)
exec_compare = Edge.new(execute, compare)

Node.update(main.id, shape: "box")
Node.update(make_string.id, label: "make a\nstring")
Node.update(compare.id, shape: "box", style: "filled", color: ".7 .3 1.0")
Edge.update(main_parse.id, weight: 8)
Edge.update(main_init.id, style: "dotted")
Edge.update(main_print.id, style: "bold", label: "100 times")
Edge.update(exec_compare.id, color: "red")


Graph.graph


