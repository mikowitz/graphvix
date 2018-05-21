defmodule Graphvix.RecordSubset do
  defstruct [
    cells: [],
    is_column: false
  ]

  def new(cells, is_column \\ false) do
    %__MODULE__{cells: cells, is_column: is_column}
  end

  def to_label(subset, top_level \\ false)
  def to_label(%{cells: cells, is_column: false}, _top_level = true) do
    Enum.map(cells, &_to_label/1) |> Enum.join(" | ")
  end
  def to_label(%{cells: cells}, _top_level) do
    "{ " <> (Enum.map(cells, &_to_label/1) |> Enum.join(" | ")) <> " }"
  end

  defp _to_label(string) when is_bitstring(string), do: string
  defp _to_label({port, string}) do
    "<#{port}> #{string}"
  end
  defp _to_label(subset = %__MODULE__{}), do: __MODULE__.to_label(subset)
end
