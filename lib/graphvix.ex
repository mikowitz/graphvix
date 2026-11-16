defmodule Graphvix do
  @moduledoc """
  An Elixir interface to [Graphviz](https://graphviz.org/).

  Graphvix 2.0 models a graph as plain, immutable data. Every construction
  function returns a new graph, so graphs are built with pipes.
  """

  alias Graphvix.Graph

  def new, do: %Graph{}
  def new(_), do: %Graph{}

  def add_node(%Graph{} = graph, _), do: graph
  def add_node(%Graph{} = graph, _, _), do: graph

  def add_edge(%Graph{} = graph, _, _), do: graph
  def add_edge(%Graph{} = graph, _, _, _), do: graph

  def add_cluster(%Graph{} = graph, _), do: graph

  def add_subgraph(%Graph{} = graph, _), do: graph

  def set_attributes(%Graph{} = graph, _, _), do: graph
end
