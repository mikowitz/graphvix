defmodule Graphvix.Node do
  @moduledoc """
  A node: a caller-chosen `id` and its `attributes`.

  Nodes are created with `Graphvix.add_node/3`, `Graphvix.Subgraph.add_node/3`
  or `Graphvix.Cluster.add_node/3`.
  """

  defstruct id: nil, attributes: %{}

  @type t :: %__MODULE__{id: String.t(), attributes: %{String.t() => term()}}
end
