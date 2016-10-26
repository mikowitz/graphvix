alias Graphvix.{Graph, Node, Edge, Cluster}

Graph.restart
Graph.update(size: "4,4")
{main, _} = Node.new(label: "main")
{parse, _} = Node.new(label: "parse")
{execute, _} = Node.new(label: "execute")
{init, _} = Node.new(label: "init")
{cleanup, _} = Node.new(label: "cleanup")
{make_string, _} = Node.new(label: "make_string")
{printf, _} = Node.new(label: "printf")
{compare, _} = Node.new(label: "compare")

{main_parse, _} = Edge.new(main, parse)
Edge.new(parse, execute)
{main_init, _} = Edge.new(main, init)
Edge.new(main, cleanup)
Edge.new(execute, make_string)
Edge.new(execute, printf)
Edge.new(init, make_string)
{main_print, _} = Edge.new(main, printf)
{exec_compare, _} = Edge.new(execute, compare)

Node.update(main.id, shape: "box")
Node.update(make_string.id, label: "make a\nstring")
Node.update(compare.id, shape: "box", style: "filled", color: ".7 .3 1.0")
Edge.update(main_parse.id, weight: 8)
Edge.update(main_init.id, style: "dotted")
Edge.update(main_print.id, style: "bold", label: "100 times")
Edge.update(exec_compare.id, color: "red")


Graph.graph


