defmodule Graphvix.Record do
  defstruct [:body]
  def new(body) when is_list(body), do: %__MODULE__{body: row(body)}
  def new(body), do: %__MODULE__{body: body}

  def column(body), do: {:col, body}

  def row(body), do: {:row, body}

  def ports(%__MODULE__{body: body}), do: collect_ports(body) |> List.flatten()

  def to_label(%__MODULE__{body: body}), do: to_label(body)

  def to_label(body) when is_binary(body), do: escape(body)
  def to_label({:row, body}), do: join(body)
  def to_label({:col, _} = col), do: wrap(col)

  defp join(cells), do: Enum.map_join(cells, " | ", &wrap/1)

  defp wrap({type, body}) when type in [:row, :col], do: "{ #{join(body)} }"
  defp wrap({port, body}) when is_binary(body), do: "<#{escape(port)}> #{escape(body)}"
  defp wrap(body), do: escape(body)

  defp collect_ports({type, cells}) when type in [:row, :col] do
    Enum.map(cells, &collect_ports/1)
  end

  defp collect_ports({port, _}), do: port
  defp collect_ports(_), do: []

  defp escape(text) do
    ~r/(\\+)(?=[{}|<>]|\z)/
    |> Regex.replace(text, fn _, run -> run <> run end)
    |> String.replace(~r/([{}|<>])/, "\\\\\\1")
  end
end
