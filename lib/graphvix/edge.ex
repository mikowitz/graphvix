defmodule Graphvix.Edge do
  @moduledoc """
  An edge between two endpoints, with its `attributes`.

  An endpoint is a node id, `{id, port}`, `{id, port, compass}` or
  `{id, nil, compass}`. Ports address cells of `Graphvix.Record` and
  `Graphvix.HTMLRecord` labels; compass points are `:n`, `:ne`, `:e`, `:se`,
  `:s`, `:sw`, `:w`, `:nw`, `:c` and `:_`.

  An edge's label is an ordinary attribute. Edges are created with
  `Graphvix.add_edge/4` and live only at the root of a graph.
  """

  alias Graphvix.Builder

  defstruct from: nil, to: nil, attributes: %{}

  @type endpoint ::
          String.t()
          | {String.t(), String.t()}
          | {String.t(), String.t() | nil, atom()}

  @type t :: %__MODULE__{from: endpoint(), to: endpoint(), attributes: %{String.t() => term()}}

  @doc false
  @spec new(term(), term(), Builder.attrs()) :: t()
  def new(from, to, attrs) do
    %__MODULE__{from: endpoint(from), to: endpoint(to), attributes: Builder.attrs(attrs)}
  end

  @doc false
  @spec node_id(endpoint()) :: String.t()
  def node_id({id, _port}), do: id
  def node_id({id, _port, _compass}), do: id
  def node_id(id), do: id

  defp endpoint({id, port}), do: {Builder.id(id), Builder.id(port)}
  defp endpoint({id, nil, compass}), do: {Builder.id(id), nil, compass}
  defp endpoint({id, port, compass}), do: {Builder.id(id), Builder.id(port), compass}
  defp endpoint(id), do: Builder.id(id)
end
