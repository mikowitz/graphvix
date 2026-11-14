defmodule Graphvix.Record do
  @moduledoc """
  A Graphviz `record` label: cells laid out in nested rows and columns.

  Use a record as the value of a node's `label`; the node is then drawn with
  `shape: "record"` unless it sets a shape of its own.

      iex> import Graphvix.Record, only: [row: 1, column: 1]
      iex> record = Graphvix.Record.new(row(["a", column(["b", {"p", "c"}])]))
      iex> Graphvix.Record.to_label(record)
      "a | { b | <p> c }"

  A body is a string (one cell), a list (a row), or a `row/1` or `column/1`.
  A cell is a string, `{port, text}`, or a nested row or column. Edges can
  attach to a cell's port with `{node_id, port}` endpoints.
  """

  defstruct body: ""

  @type cell :: String.t() | {String.t(), String.t()} | subset()
  @type subset :: {:row, [cell()]} | {:column, [cell()]}
  @type t :: %__MODULE__{body: String.t() | subset()}

  @doc "Returns a record with the given body."
  @spec new(String.t() | [cell()] | subset()) :: t()
  def new(body) when is_binary(body), do: %__MODULE__{body: body}
  def new(cells) when is_list(cells), do: %__MODULE__{body: row(cells)}

  def new({kind, cells} = subset) when kind in [:row, :column] and is_list(cells),
    do: %__MODULE__{body: subset}

  @doc "A row of cells."
  @spec row([cell()]) :: subset()
  def row(cells) when is_list(cells), do: {:row, cells}

  @doc "A column of cells."
  @spec column([cell()]) :: subset()
  def column(cells) when is_list(cells), do: {:column, cells}

  @doc """
  The record label text, escaped, without surrounding quotes.

  `{`, `}`, `|`, `<` and `>` in cell text and port names are escaped, and a
  backslash directly before one of them (or at the end of the text) is
  doubled; other backslashes, such as `\\n`, are left alone.
  """
  @spec to_label(t()) :: String.t()
  def to_label(%__MODULE__{body: body}) when is_binary(body), do: escape(body)
  def to_label(%__MODULE__{body: {:row, cells}}), do: join(cells)
  def to_label(%__MODULE__{body: {:column, _} = column}), do: cell(column)

  @doc "Every port in the record, in definition order."
  @spec ports(t()) :: [String.t()]
  def ports(%__MODULE__{body: body}), do: collect_ports(body)

  defp join(cells), do: Enum.map_join(cells, " | ", &cell/1)

  defp cell({kind, cells}) when kind in [:row, :column], do: "{ " <> join(cells) <> " }"
  defp cell({port, text}), do: "<#{escape(port)}> #{escape(text)}"
  defp cell(text) when is_binary(text), do: escape(text)

  defp collect_ports(text) when is_binary(text), do: []

  defp collect_ports({kind, cells}) when kind in [:row, :column],
    do: Enum.flat_map(cells, &collect_ports/1)

  defp collect_ports({port, _text}), do: [port]

  # record.I3: double backslash runs before a special character or the end,
  # then escape the special characters themselves.
  defp escape(text) do
    ~r/(\\+)(?=[{}|<>]|\z)/
    |> Regex.replace(text, fn _, run -> run <> run end)
    |> String.replace(~r/([{}|<>])/, "\\\\\\1")
  end
end
