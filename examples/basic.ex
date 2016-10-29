alias Graphvix.{Graph, Node, Edge, Cluster}

Graph.restart
Graph.update(size: "4,4")
{main, _} = Node.new("main")
{parse, _} = Node.new("parse")
{execute, _} = Node.new("execute")
{init, _} = Node.new("init")
{cleanup, _} = Node.new("cleanup")
{make_string, _} = Node.new("make_string")
{printf, _} = Node.new("printf")
{compare, _} = Node.new("compare")

[{main_parse, _},_,{exec_compare, _}]= Edge.chain([main, parse, execute, compare])
[{main_init, _}, {main_print, _}, _] = Edge.new(main, [init, printf, cleanup])
Edge.new(execute, [make_string, printf])
Edge.new(init, make_string)

Node.update(main, shape: "box")
Node.update(make_string, label: "make a\nstring")
Node.update(compare, shape: "box", style: "filled", color: ".7 .3 1.0")

Edge.update(main_parse, weight: 8)
Edge.update(main_init, style: "dotted")
Edge.update(main_print, style: "bold", label: "100 times")
Edge.update(exec_compare, color: "red")

Graph.graph


