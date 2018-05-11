defmodule Graphvix.Record do
  defstruct [
    body: nil,
    properties: []
  ]

  alias Graphvix.RecordSubset

  def new(body, properties \\ [])
  def new(string, properties) when is_bitstring(string) do
    %__MODULE__{body: string, properties: properties}
  end
  def new(list, properties) when is_list(list) do
    %__MODULE__{body: Graphvix.RecordSubset.new(list), properties: properties}
  end
  def new(row_or_column = %Graphvix.RecordSubset{}, properties) do
    %__MODULE__{body: row_or_column, properties: properties}
  end

  def row(cells) do
    %RecordSubset{cells: cells, is_column: false}
  end
  def column(cells) do
    %RecordSubset{cells: cells, is_column: true}
  end

  def to_label(record)
  def to_label(%{body: string}) when is_bitstring(string) do
    string
  end
  def to_label(%{body: subset = %RecordSubset{}}) do
    RecordSubset.to_label(subset, true)
  end
end
