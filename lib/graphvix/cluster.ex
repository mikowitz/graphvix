defmodule Graphvix.Cluster do
  defstruct [:id, attributes: %{graph: %{}, node: %{}}, nodes: []]

  def new(id), do: %__MODULE__{id: id}

  def set_attributes(_, _, _), do: nil

  def add_node(%__MODULE__{} = cluster, _), do: cluster
  def add_node(%__MODULE__{} = cluster, _, _), do: cluster

  def add_subgraph(%__MODULE__{} = cluster, _), do: cluster
end
