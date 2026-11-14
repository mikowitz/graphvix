defmodule Graphvix.Builder do
  @moduledoc false
  # Normalization and merging shared by Graphvix, Subgraph and Cluster.

  alias Graphvix.Node

  @type id :: String.t() | atom() | number()
  @type attrs :: keyword() | map()

  @doc "Normalizes a node, subgraph or cluster id to a string."
  @spec id(id()) :: String.t()
  def id(id) when is_binary(id), do: id
  def id(id) when is_atom(id) and not is_nil(id), do: Atom.to_string(id)
  def id(id) when is_number(id), do: to_string(id)

  @doc "Normalizes attribute keys to strings; later duplicate keys win."
  @spec attrs(attrs()) :: %{String.t() => term()}
  def attrs(attrs) when is_list(attrs) or is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end

  @doc "Merges `attrs` into the attribute map `existing`, later values winning."
  @spec merge(map(), attrs()) :: map()
  def merge(existing, attrs), do: Map.merge(existing, attrs(attrs))

  @doc """
  Adds a node to a container's node list. Re-adding an id merges attributes
  into the first entry and keeps its position.
  """
  @spec put_node([Node.t()], id(), attrs()) :: [Node.t()]
  def put_node(nodes, id, attrs) do
    id = id(id)

    case Enum.find_index(nodes, &(&1.id == id)) do
      nil ->
        nodes ++ [%Node{id: id, attributes: attrs(attrs)}]

      index ->
        List.update_at(nodes, index, fn node ->
          %{node | attributes: merge(node.attributes, attrs)}
        end)
    end
  end
end
